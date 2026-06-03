const express = require("express");
const Anthropic = require("@anthropic-ai/sdk");
const mongoose = require("mongoose");
const User = require("../models/user");
const Product = require("../models/product");
const SkinScan = require("../models/SkinScan");
const UserRoutine = require("../models/UserRoutine");

const router = express.Router();
const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });

const SAFETY_NOTE =
  "Note: This is general skincare guidance, not medical advice. For severe irritation, pregnancy, chronic skin conditions, or prescription questions, consult a dermatologist.";

function parseClaudeJson(rawText) {
  let clean = rawText.trim();
  if (clean.startsWith("```")) {
    clean = clean.replace(/^```[a-z]*\n?/, "").replace(/\n?```$/, "").trim();
  }
  try {
    return JSON.parse(clean);
  } catch (_) {
    const start = clean.indexOf("{");
    const end = clean.lastIndexOf("}");
    if (start !== -1 && end !== -1 && end > start) {
      return JSON.parse(clean.slice(start, end + 1));
    }
    throw new Error("No valid JSON found in AI response");
  }
}

// ── POST /api/ai/product-suitability ─────────────────────────────────────────
router.post("/product-suitability", async (req, res) => {
  try {
    const { userId, productId, includeRoutine = true } = req.body;

    if (!userId || !productId) {
      return res
        .status(400)
        .json({ success: false, message: "userId and productId are required" });
    }
    if (
      !mongoose.Types.ObjectId.isValid(userId) ||
      !mongoose.Types.ObjectId.isValid(productId)
    ) {
      return res
        .status(400)
        .json({ success: false, message: "Invalid userId or productId" });
    }

    // Fetch all data in parallel
    const [user, product, latestScan, activeRoutine] = await Promise.all([
      User.findById(userId).select("fullName onboarding").lean(),
      Product.findById(productId)
        .select(
          "name brand category shortDescription directionsOfUse ingredients whatsInside recommendedFor"
        )
        .lean(),
      SkinScan.findOne({ userId }).sort({ createdAt: -1 }).lean(),
      includeRoutine
        ? UserRoutine.findOne({ userId, isActive: true }).lean()
        : null,
    ]);

    if (!product) {
      return res
        .status(404)
        .json({ success: false, message: "Product not found" });
    }

    // ── User context ──────────────────────────────────────────────────────
    const o = user?.onboarding || {};
    const userBlock = `User Profile:
- Skin type: ${o.skinType || "not specified"}
- Skin concerns: ${(o.skinConcerns || []).join(", ") || "not specified"}
- Skin sensitivity: ${o.skinSensitivity || "not specified"}
- Goals: ${(o.goals || []).join(", ") || "not specified"}
- Age range: ${o.ageRange || "not specified"}
- Experience: ${o.skincareExperience || "not specified"}
- Phototype: ${o.skinPhototype || "not specified"}
- Chronic conditions: ${o.chronicCondition || "none"}
- Special conditions: ${(o.specialConditions || []).join(", ") || "none"}`;

    // ── Skin scan context ─────────────────────────────────────────────────
    let scanBlock = "";
    if (latestScan) {
      const concerns = (latestScan.detectedConcerns || [])
        .map((c) => `${c.name} (score: ${c.severityScore || 0}/100, ${c.status || ""})`)
        .join(", ");
      scanBlock = `Latest AI Skin Scan (${
        latestScan.createdAt
          ? new Date(latestScan.createdAt).toLocaleDateString()
          : "recent"
      }):
- Skin score: ${latestScan.skinScore ?? "N/A"}/100
- Overall: ${latestScan.overallStatus || "N/A"}
- Detected concerns: ${concerns || "none"}`;
    }

    // ── Product context ───────────────────────────────────────────────────
    const ingredientNames = (product.ingredients || [])
      .map((i) => i.name)
      .join(", ");
    const flags = product.whatsInside || {};
    const activeFlags = Object.entries(flags)
      .filter(([, v]) => v === true)
      .map(([k]) => k.replace(/([A-Z])/g, " $1").toLowerCase().trim())
      .join(", ");

    const productBlock = `Product to Analyze:
- Name: ${product.name}
- Brand: ${product.brand}
- Category: ${product.category || "not specified"}
- Description: ${product.shortDescription || "not provided"}
- Directions: ${product.directionsOfUse || "not provided"}
- Ingredients: ${ingredientNames || "not listed"}
- Formula flags: ${activeFlags || "none listed"}
- Recommended for skin types: ${(product.recommendedFor?.skinTypes || []).join(", ") || "not specified"}
- Recommended for concerns: ${(product.recommendedFor?.concerns || []).join(", ") || "not specified"}`;

    // ── Routine context ───────────────────────────────────────────────────
    let routineBlock = "";
    if (activeRoutine) {
      const fmt = (steps) =>
        (steps || [])
          .filter((s) => s.isActive)
          .map(
            (s) =>
              `  • ${s.stepName} (ingredient: ${s.keyIngredient || "none"}, category: ${s.productCategory || "general"})`
          )
          .join("\n");
      routineBlock = `Current Active Routine:
Morning steps:
${fmt(activeRoutine.morning) || "  • none"}
Evening steps:
${fmt(activeRoutine.evening) || "  • none"}`;
    }

    const systemPrompt = `You are Skinova AI Skin Advisor. Analyze whether a skincare product suits a specific user.
${SAFETY_NOTE}

Return ONLY valid JSON, no markdown, no code fences.
Use exactly this structure:
{
  "matchScore": number 0-100,
  "verdict": "recommended" | "use_with_caution" | "not_recommended" | "neutral",
  "summary": "2-3 sentence assessment",
  "benefits": ["benefit 1", "benefit 2"],
  "warnings": ["warning if any"],
  "conflicts": [
    {
      "ingredientA": "ingredient from product",
      "ingredientB": "ingredient or step from routine",
      "severity": "low" | "medium" | "high",
      "reason": "why they may conflict",
      "recommendation": "what to do"
    }
  ],
  "usageAdvice": {
    "bestTime": "morning" | "evening" | "either",
    "frequency": "daily" | "twice daily" | "2-3 times per week" | "once a week" | "as directed",
    "instructions": "one brief usage tip"
  }
}`;

    const userMessage = `${userBlock}

${scanBlock ? scanBlock + "\n\n" : ""}${productBlock}

${routineBlock ? routineBlock + "\n\n" : ""}Analyze this product's suitability for this user. Consider: skin type compatibility, concern benefits, potential irritants, conflicts with routine ingredients. Assign a match score 0-100.`;

    const aiResponse = await client.messages.create({
      model: "claude-sonnet-4-6",
      max_tokens: 2000,
      system: systemPrompt,
      messages: [{ role: "user", content: userMessage }],
    });

    const result = parseClaudeJson(aiResponse.content?.[0]?.text || "{}");

    // Sanitize
    result.matchScore = Math.min(100, Math.max(0, Number(result.matchScore) || 50));
    result.verdict = ["recommended", "use_with_caution", "not_recommended", "neutral"].includes(
      result.verdict
    )
      ? result.verdict
      : "neutral";
    result.summary = result.summary || "";
    result.benefits = Array.isArray(result.benefits) ? result.benefits : [];
    result.warnings = Array.isArray(result.warnings) ? result.warnings : [];
    result.conflicts = Array.isArray(result.conflicts) ? result.conflicts : [];
    result.usageAdvice = result.usageAdvice || {
      bestTime: "either",
      frequency: "as directed",
      instructions: "",
    };

    res.json({ success: true, ...result });
  } catch (err) {
    console.error("[ai/product-suitability] error:", err.message);
    res
      .status(500)
      .json({ success: false, message: "AI analysis failed. Please try again." });
  }
});

// ── POST /api/ai/routine-safety ───────────────────────────────────────────────
router.post("/routine-safety", async (req, res) => {
  try {
    const { userId } = req.body;

    if (!userId || !mongoose.Types.ObjectId.isValid(userId)) {
      return res
        .status(400)
        .json({ success: false, message: "Valid userId is required" });
    }

    const [user, routine] = await Promise.all([
      User.findById(userId).select("onboarding").lean(),
      UserRoutine.findOne({ userId, isActive: true }).lean(),
    ]);

    if (!routine) {
      return res
        .status(404)
        .json({ success: false, message: "No active routine found" });
    }

    const o = user?.onboarding || {};
    const allSteps = [
      ...(routine.morning || [])
        .filter((s) => s.isActive)
        .map((s) => ({ ...s, period: "morning" })),
      ...(routine.evening || [])
        .filter((s) => s.isActive)
        .map((s) => ({ ...s, period: "evening" })),
    ];

    if (allSteps.length === 0) {
      return res.json({
        success: true,
        hasConflicts: false,
        overallSafety: "safe",
        summary: "Your routine has no active steps to analyze.",
        conflicts: [],
        safeSuggestions: [
          "Add steps to your routine to get a safety analysis.",
        ],
      });
    }

    const stepsList = allSteps
      .map(
        (s) =>
          `[${s.period.toUpperCase()}] ${s.stepName} — key ingredient: ${
            s.keyIngredient || "none"
          }, category: ${s.productCategory || "general"}, frequency: ${
            s.frequency || "daily"
          }`
      )
      .join("\n");

    const systemPrompt = `You are Skinova AI Routine Safety Advisor. Analyze skincare routines for ingredient conflicts.
Known conflicts to check for:
• Retinol + AHA/BHA: increased irritation risk — alternate nights
• Retinol + Benzoyl Peroxide: deactivates retinol — separate times
• Vitamin C + Niacinamide: potential reduced effectiveness — morning vs evening
• AHA + BHA together: over-exfoliation risk — limit frequency
• Multiple strong actives together: irritation — stagger use
• High frequency actives on sensitive skin: barrier damage risk
${SAFETY_NOTE}

Return ONLY valid JSON, no markdown, no code fences.
Structure:
{
  "hasConflicts": true | false,
  "overallSafety": "safe" | "use_with_caution" | "needs_adjustment",
  "summary": "2-3 sentence routine assessment",
  "conflicts": [
    {
      "items": ["item A", "item B"],
      "severity": "low" | "medium" | "high",
      "reason": "why this combination may be problematic",
      "recommendation": "what to do instead"
    }
  ],
  "safeSuggestions": ["tip 1", "tip 2"]
}`;

    const userMessage = `User skin profile:
- Skin type: ${o.skinType || "not specified"}
- Sensitivity: ${o.skinSensitivity || "normal"}
- Concerns: ${(o.skinConcerns || []).join(", ") || "none"}

Current routine steps:
${stepsList}

Check for ingredient conflicts, over-exfoliation risks, and general safety issues. Consider the user's sensitivity.`;

    const aiResponse = await client.messages.create({
      model: "claude-sonnet-4-6",
      max_tokens: 2000,
      system: systemPrompt,
      messages: [{ role: "user", content: userMessage }],
    });

    const result = parseClaudeJson(aiResponse.content?.[0]?.text || "{}");

    // Sanitize
    result.hasConflicts = Boolean(result.hasConflicts);
    result.overallSafety = ["safe", "use_with_caution", "needs_adjustment"].includes(
      result.overallSafety
    )
      ? result.overallSafety
      : "use_with_caution";
    result.summary = result.summary || "";
    result.conflicts = Array.isArray(result.conflicts) ? result.conflicts : [];
    result.safeSuggestions = Array.isArray(result.safeSuggestions)
      ? result.safeSuggestions
      : [];

    res.json({ success: true, ...result });
  } catch (err) {
    console.error("[ai/routine-safety] error:", err.message);
    res
      .status(500)
      .json({ success: false, message: "AI analysis failed. Please try again." });
  }
});

module.exports = router;
