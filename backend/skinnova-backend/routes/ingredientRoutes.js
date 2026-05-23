const express = require("express");
const router = express.Router();
const Ingredient = require("../models/Ingredient");
const Product = require("../models/Product");

router.get("/", async (req, res) => {
  try {
    const ingredients = await Ingredient.find({ isActive: true }).sort({
      name: 1,
    });

    res.json(ingredients);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post("/seed", async (req, res) => {
  try {
    await Ingredient.deleteMany({});

    const ingredients = await Ingredient.insertMany([
      { name: "Aloe vera", slug: "aloe-vera", imageUrl: "assets/images/aloe_vera.png", description: "A soothing ingredient that helps calm and hydrate the skin.", suitableFor: ["Dry", "Sensitive", "Redness", "Irritation"] },
      { name: "Rosehip oil", slug: "rosehip-oil", imageUrl: "assets/images/rosehip_oil.png", description: "A nourishing oil that helps support glow and uneven tone.", suitableFor: ["Dry", "Dullness", "Hyperpigmentation", "Anti-aging"] },
      { name: "Vitamin B5", slug: "vitamin-b5", imageUrl: "assets/images/vitamin_b5.png", description: "A hydrating and calming ingredient that supports the skin barrier.", suitableFor: ["Dry", "Sensitive", "Dehydrated", "Redness"] },
      { name: "Jojoba oil", slug: "jojoba-oil", imageUrl: "assets/images/jojoba_oil.png", description: "A lightweight oil that helps soften and moisturize the skin.", suitableFor: ["Dry", "Normal", "Combination", "Sensitive"] },
      { name: "Calendula extract", slug: "calendula-extract", imageUrl: "assets/images/calendula_extract.png", description: "A calming plant extract often used for sensitive skin.", suitableFor: ["Sensitive", "Redness", "Eczema", "Irritation"] },
      { name: "Rosemary extract", slug: "rosemary-extract", imageUrl: "assets/images/rosemary_extract.png", description: "An antioxidant plant extract used in skincare formulas.", suitableFor: ["Oily", "Acne", "Dullness"] },

      { name: "Caffeine", slug: "caffeine", imageUrl: "assets/images/caffeine.png", description: "Often used for puffiness and tired-looking under-eyes.", suitableFor: ["Puffiness", "Dark circles", "Puffy under-eyes"] },
      { name: "Glycolic acid", slug: "glycolic-acid", imageUrl: "assets/images/glycolic_acid.png", description: "An exfoliating acid that helps with dullness and uneven texture.", suitableFor: ["Dullness", "Uneven Texture", "Hyperpigmentation"] },
      { name: "Hyaluronic acid", slug: "hyaluronic-acid", imageUrl: "assets/images/hyaluronic_acid.png", description: "A hydrating ingredient that retains moisture in the skin.", suitableFor: ["Normal", "Dry", "Dehydrated", "Oily", "Combination", "Sensitive"] },
      { name: "Retinol", slug: "retinol", imageUrl: "assets/images/retinol.png", description: "Helps improve texture, acne marks, and signs of aging.", suitableFor: ["Anti-aging", "Acne", "Uneven Texture", "Dark Spots"] },
      { name: "Zinc oxide", slug: "zinc-oxide", imageUrl: "assets/images/zinc_oxide.png", description: "A mineral sunscreen ingredient that helps protect the skin.", suitableFor: ["Sensitive", "Redness", "Sunscreen", "Oily"] },
      { name: "Ferulic acid", slug: "ferulic-acid", imageUrl: "assets/images/ferulic_acid.png", description: "An antioxidant often paired with vitamin C.", suitableFor: ["Dullness", "Anti-aging", "Dark Spots"] },
      { name: "Shea butter", slug: "shea-butter", imageUrl: "assets/images/shea_butter.png", description: "A rich moisturizing ingredient for softening dry skin.", suitableFor: ["Dry", "Eczema", "Sensitive"] },
      { name: "Resveratrol", slug: "resveratrol", imageUrl: "assets/images/resveratrol.png", description: "An antioxidant ingredient used for skin protection and aging signs.", suitableFor: ["Anti-aging", "Dullness", "Sensitive"] },
      { name: "Arbutin", slug: "arbutin", imageUrl: "assets/images/arbutin.png", description: "Helps improve the look of dark spots and uneven tone.", suitableFor: ["Dark Spots", "Hyperpigmentation", "Melasma"] },
      { name: "Green tea extract", slug: "green-tea-extract", imageUrl: "assets/images/green_tea_extract.png", description: "A soothing antioxidant ingredient.", suitableFor: ["Sensitive", "Redness", "Oily", "Acne"] },
      { name: "Vitamin E", slug: "vitamin-e", imageUrl: "assets/images/vitamin_e.png", description: "An antioxidant ingredient that helps support and soften skin.", suitableFor: ["Dry", "Sensitive", "Dullness"] },
      { name: "Collagen", slug: "collagen", imageUrl: "assets/images/collagen.png", description: "Used in skincare for a smoother and hydrated appearance.", suitableFor: ["Dry", "Anti-aging", "Dullness"] },
      { name: "Azelaic acid", slug: "azelaic-acid", imageUrl: "assets/images/azelaic_acid.png", description: "Helps with redness, acne, and dark spots.", suitableFor: ["Acne", "Redness", "Rosacea", "Dark Spots"] },
      { name: "Kojic acid", slug: "kojic-acid", imageUrl: "assets/images/kojic_acid.png", description: "Used to help brighten uneven skin tone.", suitableFor: ["Dark Spots", "Hyperpigmentation", "Melasma"] },
      { name: "Licorice extract", slug: "licorice-extract", imageUrl: "assets/images/licorice_extract.png", description: "A soothing brightening ingredient for uneven tone.", suitableFor: ["Redness", "Dark Spots", "Sensitive"] },
      { name: "Coenzyme Q10", slug: "coenzyme-q10", imageUrl: "assets/images/coenzyme_q10.png", description: "An antioxidant ingredient used for signs of aging.", suitableFor: ["Anti-aging", "Dullness"] },
      { name: "Rose oil", slug: "rose-oil", imageUrl: "assets/images/rose_oil.png", description: "A fragrant oil used for softness and glow.", suitableFor: ["Dry", "Dullness"] },
      { name: "Licorice root extract", slug: "licorice-root-extract", imageUrl: "assets/images/licorice_root_extract.png", description: "Helps calm skin and improve uneven tone.", suitableFor: ["Sensitive", "Redness", "Hyperpigmentation"] },
      { name: "Benzoyl peroxide", slug: "benzoyl-peroxide", imageUrl: "assets/images/benzoyl_peroxide.png", description: "An acne-fighting ingredient commonly used for breakouts.", suitableFor: ["Acne", "Oily", "Blemishes"] },
      { name: "Tea tree oil", slug: "tea-tree-oil", imageUrl: "assets/images/tea_tree_oil.png", description: "A plant oil often used in acne-prone skincare.", suitableFor: ["Acne", "Oily", "Blemishes"] },
      { name: "Peppermint extract", slug: "peppermint-extract", imageUrl: "assets/images/peppermint_extract.png", description: "A cooling plant extract used in some skincare products.", suitableFor: ["Oily", "Dullness"] },
      { name: "Ceramides", slug: "ceramides", imageUrl: "assets/images/ceramides.png", description: "Supports and repairs the skin barrier.", suitableFor: ["Dry", "Sensitive", "Eczema", "Barrier repair"] },
      { name: "Witch hazel", slug: "witch-hazel", imageUrl: "assets/images/witch_hazel.png", description: "Often used for oily skin and visible pores.", suitableFor: ["Oily", "Enlarged pores", "Acne"] },
      { name: "Centella asiatica", slug: "centella-asiatica", imageUrl: "assets/images/centella_asiatica.png", description: "A soothing ingredient that helps calm sensitive skin.", suitableFor: ["Sensitive", "Redness", "Acne"] },
      { name: "Vitamin C", slug: "vitamin-c", imageUrl: "assets/images/vitamin_c.png", description: "Helps brighten skin and improve uneven tone.", suitableFor: ["Dullness", "Dark Spots", "Hyperpigmentation"] },
      { name: "Peptides", slug: "peptides", imageUrl: "assets/images/peptides.png", description: "Used to support smoother and firmer-looking skin.", suitableFor: ["Anti-aging", "Dry", "Dullness"] },
      { name: "Allantoin", slug: "allantoin", imageUrl: "assets/images/allantoin.png", description: "A gentle soothing ingredient that helps calm skin.", suitableFor: ["Sensitive", "Redness", "Dry"] },
      { name: "Niacinamide", slug: "niacinamide", imageUrl: "assets/images/niacinamide.png", description: "Helps brighten the skin and support the skin barrier.", suitableFor: ["Oily", "Acne", "Enlarged pores", "Redness"] },
      { name: "Squalane", slug: "squalane", imageUrl: "assets/images/squalane.png", description: "A lightweight moisturizing ingredient that softens skin.", suitableFor: ["Dry", "Sensitive", "Normal", "Combination"] },
      { name: "Lactic acid", slug: "lactic-acid", imageUrl: "assets/images/lactic_acid.png", description: "A gentle exfoliating acid that helps smooth skin texture.", suitableFor: ["Dry", "Dullness", "Uneven Texture"] },
      { name: "Adenosine", slug: "adenosine", imageUrl: "assets/images/adenosine.png", description: "Used in skincare for smoothing and anti-aging support.", suitableFor: ["Anti-aging", "Dullness"] },
      { name: "Salicylic acid", slug: "salicylic-acid", imageUrl: "assets/images/salicylic_acid.png", description: "Helps unclog pores and reduce acne breakouts.", suitableFor: ["Oily", "Acne", "Enlarged pores", "Sebaceous filaments"] },
    ]);

    res.json({
      message: "Ingredients seeded successfully",
      count: ingredients.length,
      ingredients,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
router.get("/:slug", async (req, res) => {
  try {
    const ingredient = await Ingredient.findOne({
      slug: req.params.slug,
      isActive: true,
    });

    if (!ingredient) {
      return res.status(404).json({ message: "Ingredient not found" });
    }

    const products = await Product.find({
      "ingredients.name": { $regex: new RegExp(`^${ingredient.name}$`, "i") },
      isPublished: true,
    });

    res.json({
      ingredient,
      products,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;