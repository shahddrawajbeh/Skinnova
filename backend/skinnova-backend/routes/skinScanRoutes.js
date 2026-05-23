// const express = require("express");
// const multer = require("multer");
// const path = require("path");
// const fs = require("fs");

// const router = express.Router();

// const uploadDir = "uploads/skin-scans";

// if (!fs.existsSync(uploadDir)) {
//   fs.mkdirSync(uploadDir, { recursive: true });
// }

// const storage = multer.diskStorage({
//   destination: function (req, file, cb) {
//     cb(null, uploadDir);
//   },
//   filename: function (req, file, cb) {
//     const uniqueName =
//       Date.now() +
//       "-" +
//       Math.round(Math.random() * 1e9) +
//       path.extname(file.originalname);

//     cb(null, uniqueName);
//   },
// });

// const fileFilter = (req, file, cb) => {
//   if (file.mimetype.startsWith("image/")) {
//     cb(null, true);
//   } else {
//     cb(new Error("Only image files are allowed"), false);
//   }
// };

// const upload = multer({
//   storage,
//   fileFilter,
//   limits: {
//     fileSize: 8 * 1024 * 1024,
//   },
// });

// router.post(
//   "/analyze",
//   upload.fields([
//     { name: "frontImage", maxCount: 1 },
//     { name: "leftImage", maxCount: 1 },
//     { name: "rightImage", maxCount: 1 },
//   ]),
//   async (req, res) => {
//     try {
//       const frontImage = req.files?.frontImage?.[0];
//       const leftImage = req.files?.leftImage?.[0];
//       const rightImage = req.files?.rightImage?.[0];

//       if (!frontImage || !leftImage || !rightImage) {
//         return res.status(400).json({
//           message: "Please upload front, left, and right face images.",
//         });
//       }

//       const baseUrl = `${req.protocol}://${req.get("host")}`;

//       const scanImages = {
//         front: `${baseUrl}/${frontImage.path.replace(/\\/g, "/")}`,
//         left: `${baseUrl}/${leftImage.path.replace(/\\/g, "/")}`,
//         right: `${baseUrl}/${rightImage.path.replace(/\\/g, "/")}`,
//       };

//       return res.status(200).json({
//         skinScore: 72,
//         skinType: "Combination",
//         severity: "Moderate",

//         conditions: [
//           "Acne",
//           "Redness",
//           "Dark spots",
//           "Uneven texture",
//         ],

//         expertAnalysis:
//           "Your skin scan used front, left, and right face photos. Your skin shows signs of combination skin with an oily T-zone and normal-to-dry cheeks. Mild acne and redness are visible, especially around the cheeks and forehead. Some dark spots may be post-acne marks. A gentle routine with hydration, acne control, and daily sunscreen is recommended.",

//         scanImages,

//         morningRoutine: [
//           {
//             step: 1,
//             name: "Gentle Cleanser",
//             duration: "60 sec",
//             instruction:
//               "Use a gentle cleanser with lukewarm water. Avoid harsh scrubbing because it can irritate the skin.",
//             category: "Cleanse",
//           },
//           {
//             step: 2,
//             name: "Niacinamide Serum",
//             duration: "30 sec",
//             instruction:
//               "Apply a few drops to help control oil, reduce redness, and support the skin barrier.",
//             category: "Treat",
//           },
//           {
//             step: 3,
//             name: "Light Moisturizer",
//             duration: "30 sec",
//             instruction:
//               "Use a lightweight moisturizer to keep the skin hydrated without making it too oily.",
//             category: "Moisturize",
//           },
//           {
//             step: 4,
//             name: "Sunscreen SPF 50",
//             duration: "30 sec",
//             instruction:
//               "Apply sunscreen every morning. This helps protect the skin and prevents dark spots from becoming worse.",
//             category: "Protect",
//           },
//         ],

//         nightRoutine: [
//           {
//             step: 1,
//             name: "Gentle Cleanser",
//             duration: "60 sec",
//             instruction:
//               "Clean your face at night to remove sunscreen, oil, sweat, and dirt.",
//             category: "Cleanse",
//           },
//           {
//             step: 2,
//             name: "Salicylic Acid",
//             duration: "1 min",
//             instruction:
//               "Use 2-3 times per week to help with acne, clogged pores, and oily areas. Do not overuse it.",
//             category: "Treat",
//           },
//           {
//             step: 3,
//             name: "Hydrating Serum",
//             duration: "30 sec",
//             instruction:
//               "Apply hyaluronic acid or another hydrating serum to keep the skin comfortable and hydrated.",
//             category: "Hydrate",
//           },
//           {
//             step: 4,
//             name: "Barrier Repair Cream",
//             duration: "30 sec",
//             instruction:
//               "Use a moisturizer with calming ingredients to support and repair the skin barrier overnight.",
//             category: "Moisturize",
//           },
//         ],
//       });
//     } catch (error) {
//       return res.status(500).json({
//         message: "Skin analysis failed",
//         error: error.message,
//       });
//     }
//   }
// );

// module.exports = router;
const express = require("express");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

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

module.exports = router;