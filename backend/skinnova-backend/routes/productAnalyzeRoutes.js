const express = require("express");
const OpenAI = require("openai");
const Product = require("../models/Product");

const router = express.Router();

const client = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

router.post("/", async (req, res) => {
  try {
    const { productId, userSkinType, userConcerns } = req.body;

    const product = await Product.findById(productId);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: "Product not found",
      });
    }

    const prompt = `
You are Skinova AI, a skincare product analysis assistant.

Analyze this skincare product for a user.

User skin type: ${userSkinType || "not provided"}
User concerns: ${(userConcerns || []).join(", ") || "not provided"}

Product:
Brand: ${product.brand}
Name: ${product.name}
Category: ${product.category}
Description: ${product.shortDescription}
Ingredients: ${product.ingredients.map((i) => i.name).join(", ")}

Flags:
Fragrance free: ${product.whatsInside?.fragranceFree}
Alcohol free: ${product.whatsInside?.alcoholFree}
Paraben free: ${product.whatsInside?.parabenFree}
Oil free: ${product.whatsInside?.oilFree}
Sulfate free: ${product.whatsInside?.sulfateFree}

Return JSON only:
{
  "matchLevel": "Good match | Use with caution | Not recommended",
  "score": 0-100,
  "summary": "short simple explanation",
  "goodPoints": ["point1", "point2"],
  "cautionPoints": ["point1", "point2"],
  "ingredientNotes": ["note1", "note2"],
  "recommendation": "simple final advice"
}
`;

    const response = await client.responses.create({
      model: "gpt-5.1-mini",
      input: prompt,
    });

    const text = response.output_text;

    let analysis;
    try {
      analysis = JSON.parse(text);
    } catch (e) {
      analysis = {
        matchLevel: "Use with caution",
        score: 50,
        summary: text,
        goodPoints: [],
        cautionPoints: [],
        ingredientNotes: [],
        recommendation: "Please review this product carefully.",
      };
    }

    res.status(200).json({
      success: true,
      product,
      analysis,
    });
  } catch (error) {
    console.error("AI analyze error:", error);
    res.status(500).json({
      success: false,
      message: "AI analysis failed",
    });
  }
});

module.exports = router;