
const express = require("express");
const Product = require("../models/product");
const { getAppSettings } = require("../helpers/getAppSettings");

const router = express.Router();

router.post("/", async (req, res) => {
  try {
    const {
      brand,
      name,
      shortDescription,
      category,
      directionsOfUse,

      imageUrl,
      whatsInside,
      ingredients,
      brandOrigin,
      price,
      currency,
      inStock,
      stockCount,
      size,
      discountPercent,
      recommendedFor,
      isPublished,
    } = req.body;

    if (!name || !brand) {
      return res.status(400).json({
        message: "name and brand are required",
      });
    }

    const newProduct = new Product({
      brand,
      name,
      category: category ? category.trim().toLowerCase() : "",
      shortDescription,
      directionsOfUse: directionsOfUse || "",
      imageUrl,
      rating: 0,
      reviews: [],
      whatsInside: whatsInside || {},
      ingredients: ingredients || [],
      brandOrigin: brandOrigin || "",
      price: price ?? 0,
      currency: currency || "USD",
      inStock: inStock ?? true,
      stockCount: stockCount ?? 0,
      size: size || "",
      discountPercent: discountPercent ?? 0,
      recommendedFor: recommendedFor || {
        skinTypes: [],
        concerns: [],
        goals: [],

      },
      isPublished: isPublished ?? true,
    });

    await newProduct.save();

    res.status(201).json({
      message: "Product added successfully",
      product: newProduct,
    });
  } catch (error) {
    console.log("❌ ADD PRODUCT ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

router.get("/", async (req, res) => {
  try {
    const { category } = req.query;

    const filter = {};

    if (category) {
      filter.category = category.trim().toLowerCase();
    }

    const products = await Product.find(filter).sort({ createdAt: -1 });

    res.status(200).json(products);
  } catch (error) {
    console.log("❌ GET PRODUCTS ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

router.get("/count", async (req, res) => {
  try {
    const count = await Product.countDocuments();
    res.status(200).json({ count });
  } catch (error) {
    console.log("❌ GET PRODUCTS COUNT ERROR:", error);
    res.status(500).json({
      message: "Failed to get products count",
      error: error.message,
    });
  }
});
router.get("/brand/:brand", async (req, res) => {
  try {
    const brand = req.params.brand.trim();

    const products = await Product.find({
      brand: { $regex: `^${brand}$`, $options: "i" },
      isPublished: true,
    })
      .sort({ createdAt: -1 })
      .limit(10);

    res.status(200).json(products);
  } catch (error) {
    res.status(500).json({
      message: "Failed to get products by brand",
      error: error.message,
    });
  }
});
router.get("/recommend/routine", async (req, res) => {
  try {
    const { ingredient, category } = req.query;

    const products = await Product.find({
      isPublished: true,
      category: category?.toLowerCase(),
      "ingredients.name": {
        $regex: ingredient,
        $options: "i",
      },
    }).limit(5);

    res.status(200).json(products);
  } catch (error) {
    console.log("❌ RECOMMEND ROUTINE PRODUCTS ERROR:", error);

    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.get("/:id", async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({ message: "Product not found" });
    }

    res.status(200).json(product);
  } catch (error) {
    console.log("❌ GET PRODUCT ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/:id/reviews", async (req, res) => {
  try {
    const settings = await getAppSettings();
    if (!settings.allowReviews) {
      return res.status(403).json({ message: "Reviews are currently disabled." });
    }
    const {
      userId,
      userName,
      rating,
      title,
      comment,
      repurchase,
      improvedSkin,
      wasGift,
      adverseReaction,
      texture,
      usageWeeks,
    } = req.body;

    if (!userId || !userName || !rating) {
      return res.status(400).json({
        message: "userId, userName, and rating are required",
      });
    }

    const product = await Product.findById(req.params.id);

    if (!product) {
      return res.status(404).json({
        message: "Product not found",
      });
    }

    const newReview = {
      userId,
      userName,
      rating: Number(rating),
      title: title || "",
      comment: comment || "",
      repurchase: repurchase ?? null,
      improvedSkin: improvedSkin ?? null,
      wasGift: wasGift ?? null,
      adverseReaction: adverseReaction ?? null,
      texture: texture || "",
      usageWeeks: usageWeeks || "",
      createdAt: new Date(),
    };

    product.reviews.unshift(newReview);

    const totalRating = product.reviews.reduce((sum, review) => {
      return sum + Number(review.rating || 0);
    }, 0);

    product.rating = totalRating / product.reviews.length;

    await product.save();

    res.status(201).json({
      message: "Review added successfully",
      review: newReview,
      rating: product.rating,
      reviews: product.reviews,
    });
  } catch (error) {
    console.log("❌ ADD REVIEW ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// ── Product analytics (real data from reviews + user profiles) ───────────────
router.get("/:id/analytics", async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });

    const reviews = product.reviews;
    const reviewCount = reviews.length;

    if (reviewCount === 0) {
      return res.status(200).json({
        reviewCount: 0,
        avgRating: 0,
        repurchaseRate: null,
        improvedSkinRate: null,
        adverseReactionRate: null,
        skinTypeBreakdown: [],
        reviewerInitials: [],
      });
    }

    // Review-based rates
    const repurchaseYes = reviews.filter(r => r.repurchase === true).length;
    const repurchaseAnswered = reviews.filter(r => r.repurchase !== null).length;
    const improvedYes = reviews.filter(r => r.improvedSkin === true).length;
    const improvedAnswered = reviews.filter(r => r.improvedSkin !== null).length;
    const adverseYes = reviews.filter(r => r.adverseReaction === true).length;
    const adverseAnswered = reviews.filter(r => r.adverseReaction !== null).length;

    // Skin type breakdown via reviewer profiles
    let skinTypeBreakdown = [];
    try {
      const User = require("../models/user");
      const userIds = [...new Set(reviews.map(r => r.userId).filter(Boolean))];
      const users = await User.find({ _id: { $in: userIds } })
        .select("onboarding.skinType");

      const skinTypeCounts = {};
      let knownCount = 0;
      for (const review of reviews) {
        const user = users.find(u => u._id.toString() === review.userId);
        const skinType = user?.onboarding?.skinType;
        if (skinType) {
          skinTypeCounts[skinType] = (skinTypeCounts[skinType] || 0) + 1;
          knownCount++;
        }
      }

      skinTypeBreakdown = Object.entries(skinTypeCounts)
        .map(([type, count]) => ({
          type,
          count,
          percentage: Math.round((count / (knownCount || 1)) * 100),
        }))
        .sort((a, b) => b.count - a.count);
    } catch (_) { /* leave empty if user lookup fails */ }

    const reviewerInitials = reviews.slice(0, 5).map(r => ({
      initial: r.userName ? r.userName[0].toUpperCase() : "U",
      userName: r.userName || "User",
    }));

    const avgRating = reviews.reduce((s, r) => s + r.rating, 0) / reviewCount;

    res.status(200).json({
      reviewCount,
      avgRating: parseFloat(avgRating.toFixed(1)),
      repurchaseRate: repurchaseAnswered > 0
        ? Math.round((repurchaseYes / repurchaseAnswered) * 100) : null,
      improvedSkinRate: improvedAnswered > 0
        ? Math.round((improvedYes / improvedAnswered) * 100) : null,
      adverseReactionRate: adverseAnswered > 0
        ? Math.round((adverseYes / adverseAnswered) * 100) : null,
      skinTypeBreakdown,
      reviewerInitials,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.get("/concern/:concern", async (req, res) => {
  try {
    const concern = req.params.concern;

    const products = await Product.find({
      isPublished: true,
     "recommendedFor.concerns": {
  $regex: new RegExp(`^${concern}$`, "i"),
}
    });

    res.json(products);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;