const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const http = require("http");
const https = require("https");
const Anthropic = require("@anthropic-ai/sdk");
const OpenAI = require("openai");
const Product = require("../models/product");
const User = require("../models/user");
const SkinScan = require("../models/SkinScan");
const TryBeforeBuy = require("../models/TryBeforeBuy");
const { toFile } = require("openai/uploads");

const router = express.Router();

// ── Clients ──────────────────────────────────────────────────────────────────
// Claude: generate suitability analysis + realistic image editing prompt
const anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
// OpenAI: apply the image editing prompt to the user's photo
const openaiClient = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

// ── Upload storage ────────────────────────────────────────────────────────────
const uploadDir = "uploads/try-before-buy";
if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: (_, __, cb) => cb(null, uploadDir),
  filename: (_, file, cb) => {
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${path.extname(file.originalname)}`);
  },
});
const upload = multer({
  storage,
  limits: { fileSize: 15 * 1024 * 1024 },
});

// ── Helpers ───────────────────────────────────────────────────────────────────

// Resolve an image to a local file path (multer upload OR existing scan URL)
function resolveImagePath(req) {
  if (req.file) {
    return req.file.path;
  }
  const imageUrl = req.body.imageUrl;
  if (!imageUrl) return null;

  // Scan photos are stored locally at uploads/... relative to project root
  const localPath = path.join(__dirname, "..", imageUrl.replace(/^\//, ""));
  if (fs.existsSync(localPath)) return localPath;

  return null;
}

// Download an external image URL to a temp file (used when imageUrl is a full URL)
function downloadToTemp(url) {
  return new Promise((resolve, reject) => {
    const filename = path.join(uploadDir, `tmp-${Date.now()}.jpg`);
    const file = fs.createWriteStream(filename);
    const client = url.startsWith("https") ? https : http;
    client
      .get(url, (res) => {
        res.pipe(file);
        file.on("finish", () => file.close(() => resolve(filename)));
      })
      .on("error", (err) => {
        fs.unlink(filename, () => {});
        reject(err);
      });
  });
}

// POST /api/try-before-buy
// Accepts multipart (new photo) or JSON with imageUrl (scan photo).
router.post("/", upload.single("image"), async (req, res) => {
  let tempDownloadPath = null;

  try {
    const { userId, productId } = req.body;

    // ── Validate ─────────────────────────────────────────────────────────────
    if (!userId || !productId) {
      return res.status(400).json({
        success: false,
        message: "userId and productId are required.",
      });
    }

    // ── Resolve image ─────────────────────────────────────────────────────────
    let imagePath = resolveImagePath(req);

    // If imageUrl is a full http/https URL, download it
    if (!imagePath && req.body.imageUrl?.startsWith("http")) {
      tempDownloadPath = await downloadToTemp(req.body.imageUrl);
      imagePath = tempDownloadPath;
    }

    if (!imagePath) {
      return res.status(400).json({
        success: false,
        message: "Please provide a photo (upload a file or send imageUrl).",
      });
    }

    // ── Load product ──────────────────────────────────────────────────────────
    const product = await Product.findById(productId).lean();
    if (!product) {
      return res.status(404).json({ success: false, message: "Product not found." });
    }

    // ── Load user profile ─────────────────────────────────────────────────────
    let skinType = "combination";
    let concerns = [];
    let goals = [];
    let sensitivity = "";

    try {
      const user = await User.findById(userId).select("onboarding").lean();
      if (user?.onboarding) {
        skinType = user.onboarding.skinType || skinType;
        concerns = user.onboarding.skinConcerns || [];
        goals = user.onboarding.goals || [];
        sensitivity = user.onboarding.skinSensitivity || "";
      }
    } catch (_) {}

    // ── Load latest skin scan ─────────────────────────────────────────────────
    let skinScore = null;
    let overallStatus = "";
    let detectedConcerns = [];

    try {
      const scan = await SkinScan.findOne({ userId }).sort({ createdAt: -1 }).lean();
      if (scan) {
        skinScore = scan.skinScore;
        overallStatus = scan.overallStatus;
        detectedConcerns = (scan.detectedConcerns || []).map(
          (c) => `${c.name} (${c.status})`
        );
      }
    } catch (_) {}

    const ingredientNames = (product.ingredients || []).map((i) => i.name).join(", ");
    const flags = product.whatsInside || {};

    // ── Ask Claude for analysis + image prompt ────────────────────────────────
    const claudePrompt = `You are a skincare AI assistant for the Skinova app.
A user wants to preview how a skincare product may affect their skin.

USER SKIN PROFILE:
- Skin type: ${skinType}
- Skin concerns: ${concerns.join(", ") || "none specified"}
- Goals: ${goals.join(", ") || "none specified"}
- Sensitivity: ${sensitivity || "not specified"}
- Latest scan score: ${skinScore ?? "N/A"}
- Overall scan status: ${overallStatus || "N/A"}
- Detected concerns from scan: ${detectedConcerns.join(", ") || "none"}

PRODUCT:
- Name: ${product.name}
- Brand: ${product.brand}
- Category: ${product.category || "skincare"}
- Description: ${product.shortDescription || "N/A"}
- Key Ingredients: ${ingredientNames || "not listed"}
- Fragrance-free: ${flags.fragranceFree ? "yes" : "no"}
- Oil-free: ${flags.oilFree ? "yes" : "no"}
- Paraben-free: ${flags.parabenFree ? "yes" : "no"}
- Suitable for skin types: ${(product.recommendedFor?.skinTypes || []).join(", ") || "not specified"}
- Targets concerns: ${(product.recommendedFor?.concerns || []).join(", ") || "not specified"}

Based on the above:
1. Compute a suitability score (0–100) — how well this product fits the user's skin.
2. List 2–4 expected visible improvements (short, natural, realistic).
3. List any relevant warnings (fragrance, irritants, over-use risk). Empty array if none.
4. Write a realistic image editing prompt for an AI image editor.

For the imagePrompt:
- Phrase it as direct editing instructions for a photo of a real person's face.
- Start with: "Photo of a real person. Keep the same face, identity, lighting, background, and realistic skin texture."
- Then describe ONLY what the product category would realistically improve over 3–4 weeks.
- Do not add beauty filters, reshape the face, change age, gender, or add makeup.
- Keep it under 120 words.
- Examples by category:
  moisturizer → reduce dryness, improve hydration, subtle healthy glow, no filter.
  anti-acne → gently reduce redness around affected areas, calm skin tone, no visible filter.
  brightening → slightly even skin tone, subtle radiance, realistic improvement, no filter.
  sunscreen → healthy skin appearance, no changes to skin concerns.

Return ONLY valid JSON with no markdown:
{
  "productName": "${product.name}",
  "suitabilityScore": <number 0-100>,
  "expectedEffects": ["effect1", "effect2"],
  "warnings": ["warning if any"],
  "imagePrompt": "<editing prompt>"
}`;

    let claudeResult;
    const claudeResponse = await anthropic.messages.create({
      model: "claude-haiku-4-5-20251001",
      max_tokens: 512,
      messages: [{ role: "user", content: claudePrompt }],
    });

    const rawText = (claudeResponse.content[0]?.text || "").trim();
    let cleanJson = rawText;
    if (cleanJson.startsWith("```")) {
      cleanJson = cleanJson.replace(/^```[a-z]*\n?/, "").replace(/\n?```$/, "").trim();
    }

    try {
      claudeResult = JSON.parse(cleanJson);
    } catch (_) {
      claudeResult = {
        productName: product.name,
        suitabilityScore: 70,
        expectedEffects: ["Improved hydration", "Calmer skin over time"],
        warnings: [],
        imagePrompt:
          "Photo of a real person. Keep the same face, identity, lighting, and background. Slightly improve overall skin health appearance. No beauty filter.",
      };
    }

    // Clamp score to valid range
    claudeResult.suitabilityScore = Math.max(
      0,
      Math.min(100, Math.round(claudeResult.suitabilityScore || 0))
    );

    // ── Edit image with OpenAI gpt-image-1 ────────────────────────────────────
    let generatedImageUrl = "";

    if (process.env.OPENAI_API_KEY) {
      try {
        const imageFile = await toFile(
  fs.createReadStream(imagePath),
  "skin-preview.png",
  { type: "image/png" }
);
        const editResponse = await openaiClient.images.edit({
          model: "gpt-image-1",
image: imageFile,          prompt: claudeResult.imagePrompt,
          n: 1,
          size: "1024x1024",
        });

        const b64 = editResponse.data?.[0]?.b64_json;
        if (b64) {
          const outFilename = `gen-${Date.now()}-${Math.round(Math.random() * 1e9)}.png`;
          const outPath = path.join(uploadDir, outFilename);
          fs.writeFileSync(outPath, Buffer.from(b64, "base64"));
          generatedImageUrl = `/${uploadDir}/${outFilename}`;
        }
      } catch (imgErr) {
        // Image editing failed — still return the analysis, just no preview image
        console.error("[try-before-buy] Image edit failed:", imgErr.message);
      }
    }

    // ── Determine original image URL to store ─────────────────────────────────
    let originalImageUrl = req.body.imageUrl || "";
    if (req.file) {
      originalImageUrl = `/${req.file.path.replace(/\\/g, "/")}`;
    }

    // ── Save record ───────────────────────────────────────────────────────────
    const record = new TryBeforeBuy({
      userId,
      productId,
      originalImageUrl,
      generatedImageUrl,
      suitabilityScore: claudeResult.suitabilityScore,
      expectedEffects: claudeResult.expectedEffects || [],
      warnings: claudeResult.warnings || [],
      imagePrompt: claudeResult.imagePrompt || "",
    });
    await record.save();

    res.status(200).json({
      success: true,
      suitabilityScore: claudeResult.suitabilityScore,
      expectedEffects: claudeResult.expectedEffects || [],
      warnings: claudeResult.warnings || [],
      generatedImageUrl,
      originalImageUrl,
      productName: claudeResult.productName || product.name,
      recordId: record._id,
    });
  } catch (error) {
    console.error("[try-before-buy] Error:", error.message);
    res.status(500).json({
      success: false,
      message: "Preview generation failed. Please try again.",
    });
  } finally {
    // Clean up temp downloaded file
    if (tempDownloadPath && fs.existsSync(tempDownloadPath)) {
      fs.unlink(tempDownloadPath, () => {});
    }
  }
});

// GET /api/try-before-buy/history/:userId — fetch past previews for a user
router.get("/history/:userId", async (req, res) => {
  try {
    const records = await TryBeforeBuy.find({ userId: req.params.userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .populate("productId", "name brand imageUrl category")
      .lean();
    res.json(records);
  } catch (error) {
    res.status(500).json({ success: false, message: "Failed to load history." });
  }
});

// DELETE /api/try-before-buy/:id — delete a single preview record and its generated image file
router.delete("/:id", async (req, res) => {
  try {
    const record = await TryBeforeBuy.findByIdAndDelete(req.params.id).lean();

    if (!record) {
      return res.status(404).json({ success: false, message: "Record not found." });
    }

    // Remove the generated image file from disk if it exists
    if (record.generatedImageUrl) {
      const filePath = path.join(
        __dirname,
        "..",
        record.generatedImageUrl.replace(/^\//, "")
      );
      if (fs.existsSync(filePath)) {
        fs.unlink(filePath, (err) => {
          if (err) console.error("[try-before-buy] File delete failed:", err.message);
        });
      }
    }

    res.json({ success: true });
  } catch (error) {
    console.error("[try-before-buy] Delete error:", error.message);
    res.status(500).json({ success: false, message: "Failed to delete preview." });
  }
});

module.exports = router;
