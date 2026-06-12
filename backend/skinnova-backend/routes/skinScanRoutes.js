
const express = require("express");
const multer = require("multer");
const path = require("path");
const User = require('../models/user');
const fs = require("fs");
const { getAppSettings } = require("../helpers/getAppSettings");

const router = express.Router();

const uploadDir = "uploads/skin-scans";

if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueName =
      Date.now() +
      "-" +
      Math.round(Math.random() * 1e9) +
      path.extname(file.originalname);

    cb(null, uniqueName);
  },
});

const upload = multer({ storage });

async function analyzeWithHuggingFace(imagePath) {
  const imageBuffer = fs.readFileSync(imagePath);

  const response = await fetch(
  "https://router.huggingface.co/hf-inference/models/google/vit-base-patch16-224",
   {
      method: "POST",
      headers: {
        Authorization: `Bearer ${process.env.HF_TOKEN}`,
        "Content-Type": "application/octet-stream",
      },
      body: imageBuffer,
    }
  );

  const data = await response.json();

  if (!response.ok) {
    throw new Error(JSON.stringify(data));
  }

  return data;
}

function buildSkinovaResult(aiResult) {
  let topLabel = "Acne";
  let confidence = 0.7;

  if (Array.isArray(aiResult) && aiResult.length > 0) {
    topLabel = aiResult[0].label || "Acne";
    confidence = aiResult[0].score || 0.7;
  }

  const label = topLabel.toLowerCase();

  let acneScore = 35;
  let rednessScore = 45;
  let hydrationScore = 55;
  let poresScore = 48;
  let wrinklesScore = 70;
  let darkSpotsScore = 42;

  if (label.includes("acne")) {
    acneScore = Math.round(confidence * 100);
    rednessScore = 55;
    poresScore = 58;
  }

  if (label.includes("rosacea")) {
    rednessScore = Math.round(confidence * 100);
    acneScore = 35;
  }

  if (label.includes("eczema")) {
    hydrationScore = 35;
    rednessScore = 65;
  }

  const averageProblem =
    (acneScore + rednessScore + poresScore + darkSpotsScore) / 4;

  const skinScore = Math.max(35, Math.round(100 - averageProblem / 1.5));
  const potentialScore = Math.min(98, skinScore + 35);

  return {
    aiDetectedCondition: topLabel,
    aiConfidence: confidence,

    skinScore,
    potentialScore,
    skinType: "Combination",
    severity:
      skinScore >= 75 ? "Mild" : skinScore >= 55 ? "Moderate" : "Needs Care",

    improvementTime: "3 Months",

    metrics: [
      {
        name: "Hydration",
        score: hydrationScore,
        status: hydrationScore >= 70 ? "Good" : hydrationScore >= 50 ? "Medium" : "Needs care",
      },
      {
        name: "Acne",
        score: acneScore,
        status: acneScore <= 35 ? "Good" : acneScore <= 60 ? "Medium" : "Needs care",
      },
      {
        name: "Redness",
        score: rednessScore,
        status: rednessScore <= 35 ? "Good" : rednessScore <= 60 ? "Medium" : "Needs care",
      },
      {
        name: "Pores",
        score: poresScore,
        status: poresScore <= 35 ? "Good" : poresScore <= 60 ? "Medium" : "Needs care",
      },
      {
        name: "Wrinkles",
        score: wrinklesScore,
        status: wrinklesScore >= 70 ? "Good" : "Medium",
      },
      {
        name: "Dark spots",
        score: darkSpotsScore,
        status: darkSpotsScore <= 35 ? "Good" : darkSpotsScore <= 60 ? "Medium" : "Needs care",
      },
    ],

    expertAnalysis:
      `The AI detected ${topLabel}. This result is only a skincare suggestion, not a medical diagnosis. A gentle routine with hydration, sunscreen, and targeted treatment is recommended.`,

    morningRoutine: [
      {
        step: 1,
        name: "Gentle Cleanser",
        duration: "60 sec",
        instruction: "Use a gentle cleanser with lukewarm water.",
        category: "Cleanse",
      },
      {
        step: 2,
        name: "Niacinamide Serum",
        duration: "30 sec",
        instruction: "Helps with redness, oil control, and barrier support.",
        category: "Treat",
      },
      {
        step: 3,
        name: "Light Moisturizer",
        duration: "30 sec",
        instruction: "Keep the skin hydrated without clogging pores.",
        category: "Moisturize",
      },
      {
        step: 4,
        name: "Sunscreen SPF 50",
        duration: "30 sec",
        instruction: "Use every morning to protect the skin.",
        category: "Protect",
      },
    ],

    nightRoutine: [
      {
        step: 1,
        name: "Gentle Cleanser",
        duration: "60 sec",
        instruction: "Clean your face from sunscreen, oil, and dirt.",
        category: "Cleanse",
      },
      {
        step: 2,
        name: "Salicylic Acid",
        duration: "1 min",
        instruction: "Use 2-3 times per week for acne and clogged pores.",
        category: "Treat",
      },
      {
        step: 3,
        name: "Hydrating Serum",
        duration: "30 sec",
        instruction: "Use hyaluronic acid or calming hydration.",
        category: "Hydrate",
      },
      {
        step: 4,
        name: "Barrier Repair Cream",
        duration: "30 sec",
        instruction: "Support your skin barrier overnight.",
        category: "Moisturize",
      },
    ],
  };
}

router.post("/analyze", upload.single("image"), async (req, res) => {
  try {
    const settings = await getAppSettings();
    if (!settings.allowSkinScans) {
      return res.status(403).json({ message: "Skin scans are currently disabled." });
    }

    console.log("🔥 analyze route hit");
    const image = req.file;

    if (!image) {
      return res.status(400).json({
        message: "No image uploaded.",
      });
    }

    let aiResult = null;
    let aiMode = "huggingface";

    try {
      aiResult = await analyzeWithHuggingFace(image.path);
    } catch (error) {
      console.log("HuggingFace failed, using fallback:", error.message);
      aiMode = "fallback";
      aiResult = [{ label: "Acne", score: 0.72 }];
    }

    const result = buildSkinovaResult(aiResult);
console.log("AI MODE:", aiMode);
console.log("RAW AI RESULT:", aiResult);
    return res.status(200).json({
      aiMode,
      rawAiResult: aiResult,
      ...result,
    });
  } catch (error) {
    return res.status(500).json({
      message: "Skin analysis failed",
      error: error.message,
    });
  }
});

// ─── Skin scan history routes ─────────────────────────────────────────────────

const SkinScan = require('../models/SkinScan');

const DAILY_SCAN_LIMIT = 2;

// POST / — save a new skin scan (multipart image OR JSON with imageUrl)
router.post('/', upload.single('image'), async (req, res) => {
  try {
    const { userId, overallStatus, skinScore } = req.body;

    if (!userId) {
      return res.status(400).json({ message: 'userId is required.' });
    }

    // Daily limit check
    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);
    const todayCount = await SkinScan.countDocuments({
      userId,
      createdAt: { $gte: startOfDay },
    });

    if (todayCount >= DAILY_SCAN_LIMIT) {
      console.log(`[skin-scan] Daily limit reached for user ${userId}`);
      return res.status(429).json({
        message: 'You can only do 2 skin scans per day.',
      });
    }

    // Parse JSON fields sent as strings (multipart) or directly (JSON body)
    let detectedConcerns = [];
    let morningRoutine = [];
    let eveningRoutine = [];

    try {
      if (req.body.detectedConcerns) {
        detectedConcerns =
          typeof req.body.detectedConcerns === 'string'
            ? JSON.parse(req.body.detectedConcerns)
            : req.body.detectedConcerns;
      }
      if (req.body.morningRoutine) {
        morningRoutine =
          typeof req.body.morningRoutine === 'string'
            ? JSON.parse(req.body.morningRoutine)
            : req.body.morningRoutine;
      }
      if (req.body.eveningRoutine) {
        eveningRoutine =
          typeof req.body.eveningRoutine === 'string'
            ? JSON.parse(req.body.eveningRoutine)
            : req.body.eveningRoutine;
      }
    } catch (parseErr) {
      return res.status(400).json({ message: 'Invalid JSON in fields.', error: parseErr.message });
    }

    // Resolve image URL
    let imageUrl = req.body.imageUrl || '';
    if (req.file) {
      imageUrl = `/${req.file.path.replace(/\\/g, '/')}`;
    }

    if (!imageUrl) {
      console.log('[skin-scan] Warning: scan saved without an image');
    }
const user = await User.findById(userId).select("scanPrivacy");
const scanPrivacy = user?.scanPrivacy || {};
    const scan = new SkinScan({
      userId,
      imageUrl: scanPrivacy.allowImageStorage === false ? '' : imageUrl,
      detectedConcerns,
      overallStatus: overallStatus || '',
      skinScore: skinScore != null ? Number(skinScore) : null,
      morningRoutine,
      eveningRoutine,
    });

    await scan.save();
    if (scanPrivacy.allowImageStorage === false && req.file?.path) {
  fs.unlink(req.file.path, (err) => {
    if (err) {
      console.log('Failed to delete skin scan image:', err.message);
    }
  });
}
    console.log(`[skin-scan] Saved scan ${scan._id} for user ${userId}`);
    res.status(201).json(scan);
  } catch (err) {
    console.error('[skin-scan] Save error:', err.message);
    res.status(500).json({ message: 'Failed to save scan.', error: err.message });
  }
});

// Helper: true if the given date falls on today's calendar day
function isToday(date) {
  if (!date) return false;
  const d = new Date(date);
  const now = new Date();
  return (
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate()
  );
}

// GET /web-quota/:userId — check whether the web AI scan (1/day) is still available
router.get('/web-quota/:userId', async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select('lastWebAiScanDate');
    if (!user) return res.status(404).json({ message: 'User not found.' });
    const allowed = !isToday(user.lastWebAiScanDate);
    res.json({ allowed });
  } catch (err) {
    res.status(500).json({ message: 'Failed to check web AI scan quota.', error: err.message });
  }
});

// POST /web-quota/claim — claim today's web AI scan (1/day), call before running AI analysis
router.post('/web-quota/claim', async (req, res) => {
  try {
    const { userId } = req.body;
    if (!userId) return res.status(400).json({ message: 'userId is required.' });

    const user = await User.findById(userId).select('lastWebAiScanDate');
    if (!user) return res.status(404).json({ message: 'User not found.' });

    if (isToday(user.lastWebAiScanDate)) {
      return res.status(403).json({
        allowed: false,
        message:
          'You have used your free AI scan for today on web. Download the mobile app for full AI access and camera scanning.',
      });
    }

    user.lastWebAiScanDate = new Date();
    await user.save();
    res.json({ allowed: true });
  } catch (err) {
    res.status(500).json({ message: 'Failed to claim web AI scan quota.', error: err.message });
  }
});

// GET /history/:userId — all scans for a user, newest first
router.get('/history/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const scans = await SkinScan.find({ userId })
      .sort({ createdAt: -1 })
      .lean();
    res.json(scans);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch history.', error: err.message });
  }
});

// GET /:scanId — single scan (must come after /history/:userId)
router.get('/:scanId', async (req, res) => {
  try {
    const scan = await SkinScan.findById(req.params.scanId).lean();
    if (!scan) return res.status(404).json({ message: 'Scan not found.' });
    res.json(scan);
  } catch (err) {
    res.status(500).json({ message: 'Failed to fetch scan.', error: err.message });
  }
});

// DELETE /:scanId — delete a scan
router.delete('/:scanId', async (req, res) => {
  try {
    const scan = await SkinScan.findByIdAndDelete(req.params.scanId);
    if (!scan) return res.status(404).json({ message: 'Scan not found.' });
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: 'Failed to delete scan.', error: err.message });
  }
});

module.exports = router;