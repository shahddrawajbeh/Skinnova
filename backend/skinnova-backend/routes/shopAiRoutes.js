const express = require("express");
const Anthropic = require("@anthropic-ai/sdk");
const StoreProduct = require("../models/storeProduct");
const User = require("../models/user");
const SkinScan = require("../models/SkinScan");

const router = express.Router();

// API key stays server-side only — never exposed to Flutter
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

// Limit products sent to AI to keep token usage manageable
const MAX_PRODUCTS = 30;

// Shared identity and safety guardrails injected on every call
const SYSTEM_PROMPT = `You are Skinova Beauty AI, a skincare shopping and coaching assistant inside the Skinova app.
You have three modes: Product Detective, Skin Coach, and Smart Shopper.
Be friendly, simple, and practical. Use clear language.
Do not diagnose medical conditions or give dangerous medical advice.
If the user describes severe irritation, swelling, infection, burns, or persistent symptoms, strongly advise them to see a dermatologist.
For Smart Shopper mode, ONLY recommend products from the provided product list. Never invent products or store names.

Return ONLY valid JSON.
Do not explain outside the JSON.
Do not wrap the JSON in markdown.
Do not include backticks.
The response must start with { and end with }. — no markdown, no code fences, no extra text.
Use exactly this structure:
{
  "title": "short heading (max 8 words)",
  "summary": "main answer in 2-4 sentences",
  "verdict": "one-line verdict if applicable, otherwise empty string",
  "warnings": ["warning if any"],
  "tips": ["practical tip 1", "practical tip 2"],
  "products": [
  {
    "storeProductId": "id from product list",
    "productId": "id from product list",
    "storeId": "id from product list",
    "name": "exact product name",
    "brand": "exact brand",
    "price": 0,
    "currency": "ILS",
    "stockCount": 0,
    "storeName": "exact store name",
    "imageUrl": "exact image url or empty string",
    "reason": "one sentence why this fits"
  }
],
  "routine": {
    "morning": ["step 1 description", "step 2 description"],
    "evening": ["step 1 description", "step 2 description"]
  }
}`;

// POST /api/shop-ai/chat
router.post("/chat", async (req, res) => {
  try {
    const { userId, mode, message } = req.body;

    // ── Validate inputs ──────────────────────────────────────────────────
    if (!userId || !mode || !message) {
      return res.status(400).json({
        success: false,
        message: "userId, mode, and message are all required.",
      });
    }

    if (!["detective", "coach", "shopper"].includes(mode)) {
      return res.status(400).json({
        success: false,
        message: "mode must be one of: detective, coach, shopper.",
      });
    }

    const trimmedMessage = message.trim();
    if (trimmedMessage.length < 3) {
      return res.status(400).json({
        success: false,
        message: "Message is too short. Please ask a question.",
      });
    }

    // ── Build user context block (used for personalization) ──────────────
    let userContext = "";

    try {
      const user = await User.findById(userId).select("fullName onboarding").lean();
      if (user?.onboarding) {
        const o = user.onboarding;
        userContext += `
User profile:
- Skin type: ${o.skinType || "not specified"}
- Skin concerns: ${(o.skinConcerns || []).join(", ") || "not specified"}
- Goals: ${(o.goals || []).join(", ") || "not specified"}
- Age range: ${o.ageRange || "not specified"}
- Sensitivity: ${o.skinSensitivity || "not specified"}
- Experience: ${o.skincareExperience || "not specified"}`;
      }
    } catch (_) {
      // Non-critical — continue without user profile
    }

    // ── Append latest skin scan if available ─────────────────────────────
    try {
      const scan = await SkinScan.findOne({ userId }).sort({ createdAt: -1 }).lean();
      if (scan) {
        const concerns = (scan.detectedConcerns || [])
          .map((c) => `${c.name} (${c.status})`)
          .join(", ");

        userContext += `
Latest skin scan (${scan.createdAt ? new Date(scan.createdAt).toLocaleDateString() : "recent"}):
- Skin score: ${scan.skinScore ?? "N/A"}
- Overall: ${scan.overallStatus || "N/A"}
- Concerns: ${concerns || "none detected"}`;
      }
    } catch (_) {
      // Non-critical
    }

    // ── Build mode-specific prompt ───────────────────────────────────────
    let modePrompt = "";

    if (mode === "detective") {
      modePrompt = `${SYSTEM_PROMPT}

Mode: Product Detective
${userContext}

User message: "${trimmedMessage}"

Analyze the product name or ingredient list the user provided.
Assess: suitability for oily/acne-prone skin, fragrance or irritants, comedogenic potential, best ingredients present, and any warnings.
Give a clear final verdict.
Leave products array empty unless user explicitly asks for alternatives.`;

    } else if (mode === "coach") {
      modePrompt = `${SYSTEM_PROMPT}

Mode: Skin Coach
${userContext}

User message: "${trimmedMessage}"

Answer the skincare question clearly and practically.
Cover routine advice, ingredient interactions, skin concern questions.
Do not diagnose diseases.
For severe symptoms (burning, swelling, infection) tell them to see a dermatologist.
Leave products array empty unless user explicitly asks for product recommendations.`;

    } else if (mode === "shopper") {
      // Fetch available products and populate product + store details
      const storeProducts = await StoreProduct.find({ isAvailable: true })
        .populate(
          "productId",
          "name brand category imageUrl shortDescription ingredients whatsInside recommendedFor brandOrigin"
        )
        .populate("storeId", "storeName city")
        .limit(MAX_PRODUCTS)
        .lean();

      const productList = storeProducts
        .filter((sp) => sp.productId && sp.storeId)
        .map((sp) => ({
          storeProductId: sp._id.toString(),
          productId: sp.productId._id.toString(),
          storeId: sp.storeId._id.toString(),
          name: sp.productId.name,
          brand: sp.productId.brand,
          category: sp.productId.category || "",
          price: sp.price,
currency: sp.currency || "ILS",
stockCount: sp.stockCount ?? 0,
          storeName: sp.storeId.storeName,
          imageUrl: sp.productId.imageUrl || "",
          description: sp.productId.shortDescription || "",
          topIngredients: (sp.productId.ingredients || [])
            .slice(0, 8)
            .map((i) => i.name)
            .join(", "),
          suitableFor: {
            skinTypes: ((sp.productId.recommendedFor || {}).skinTypes || []).join(", "),
            concerns: ((sp.productId.recommendedFor || {}).concerns || []).join(", "),
          },
          flags: {
            fragranceFree: sp.productId.whatsInside?.fragranceFree || false,
            oilFree: sp.productId.whatsInside?.oilFree || false,
            parabenFree: sp.productId.whatsInside?.parabenFree || false,
            vegan: sp.productId.whatsInside?.vegan || false,
          },
          brandOrigin: sp.productId.brandOrigin || "",
        }));

      if (productList.length === 0) {
        return res.status(200).json({
          success: true,
          mode,
          result: {
            title: "No Products Available",
            summary:
              "There are currently no products listed in the shop. Please check back later when sellers have added their products.",
            verdict: "",
            warnings: [],
            tips: ["Browse back soon — new products are added regularly."],
            products: [],
            routine: { morning: [], evening: [] },
          },
        });
      }

      modePrompt = `${SYSTEM_PROMPT}

Mode: Smart Shopper
${userContext}

Available products (ONLY recommend from this list — never invent products or stores):
${JSON.stringify(productList, null, 1)}

User message: "${trimmedMessage}"

Recommend the best matching products from the list above.
Return maximum 6 products only.
Choose the most relevant and cheapest matches first.
Do not list every matching product.
Use ONLY the price and currency from each StoreProduct entry.
Do NOT use or invent any price from the Product model.
The same product may appear in different stores with different prices.
Treat each storeProductId as a separate store offer.
If the user asks for a budget, cheapest product, or products under a price, filter using StoreProduct price.
For each recommended product include: storeProductId, productId, storeId, name, brand, price, currency, stockCount, storeName, imageUrl, and a clear reason.
If building a routine, populate the routine field.
If nothing matches, set products to [] and explain in summary what category of products to look for.`;
    }

    // ── Call Anthropic Messages API ────────────────────────────────────────
  const response = await client.messages.create({
  model: "claude-sonnet-4-6",
  max_tokens: 4000,
  system: SYSTEM_PROMPT,
  messages: [
    {
      role: "user",
      content: modePrompt,
    },
  ],
});

const rawText = (response.content?.[0]?.text || "").trim();


    // Strip markdown code fences that models sometimes add despite instructions
    let cleanJson = rawText;
    if (cleanJson.startsWith("```")) {
      cleanJson = cleanJson
        .replace(/^```[a-z]*\n?/, "")
        .replace(/\n?```$/, "")
        .trim();
    }

    // ── Parse AI response ────────────────────────────────────────────────
    let result;

try {
  result = JSON.parse(cleanJson);
} catch (_) {
  try {
    const start = cleanJson.indexOf("{");
    const end = cleanJson.lastIndexOf("}");

    if (start !== -1 && end !== -1 && end > start) {
      const jsonOnly = cleanJson.slice(start, end + 1);
      result = JSON.parse(jsonOnly);
    } else {
      throw new Error("No JSON object found");
    }
  } catch (parseError) {
    console.error("[shop-ai] JSON parse failed. Raw AI text:", rawText);
      console.log("RAW CLAUDE TEXT:", rawText);


    result = {
      title: "AI Response",
      summary: "I found an answer, but it could not be formatted correctly. Please try asking again.",
      verdict: "",
      warnings: [],
      tips: [],
      products: [],
      routine: { morning: [], evening: [] },
    };
  }
}

    // Defensive field defaults — ensure the Flutter app never crashes on missing keys
    result.title = result.title || "";
    result.summary = result.summary || "";
    result.verdict = result.verdict || "";
    result.warnings = Array.isArray(result.warnings) ? result.warnings : [];
    result.tips = Array.isArray(result.tips) ? result.tips : [];
    result.products = Array.isArray(result.products) ? result.products : [];
    result.routine = result.routine || {};
    result.routine.morning = Array.isArray(result.routine.morning) ? result.routine.morning : [];
    result.routine.evening = Array.isArray(result.routine.evening) ? result.routine.evening : [];

    res.status(200).json({ success: true, mode, result });
  } catch (error) {
    console.error("[shop-ai] Chat error:", error.message);
    res.status(500).json({
      success: false,
      message: "AI is temporarily unavailable. Please try again in a moment.",
    });
  }
});

module.exports = router;
