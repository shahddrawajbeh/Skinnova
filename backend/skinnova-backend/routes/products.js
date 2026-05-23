
const express = require("express");
const Product = require("../models/product");

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