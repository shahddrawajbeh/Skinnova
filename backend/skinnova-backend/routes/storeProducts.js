const express = require("express");
const StoreProduct = require("../models/storeProduct");
const GroupPost = require("../models/group_posts");
const router = express.Router();

// GET all store products
router.get("/", async (req, res) => {
  try {
    const storeProducts = await StoreProduct.find()
      .populate("storeId")
      .populate("productId")
      .populate("sellerId", "fullName email role")
      .sort({ price: 1 });

    res.status(200).json(storeProducts);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// GET stores that sell a specific product
router.get("/product/:productId", async (req, res) => {
  try {
    const sellers = await StoreProduct.find({
      productId: req.params.productId,
      isAvailable: true,
    })
      .populate("storeId")
      .populate("sellerId", "fullName email role")
      .sort({ price: 1 });

    res.status(200).json(sellers);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// CREATE store product
router.post("/", async (req, res) => {
  try {
    const { storeId, productId, sellerId, price, currency, stockCount } = req.body;

    if (!storeId || !productId || !sellerId || !price) {
      return res.status(400).json({
        message: "storeId, productId, sellerId, and price are required",
      });
    }

    const storeProduct = await StoreProduct.create({
      storeId,
      productId,
      sellerId,
      price,
      currency,
      stockCount,
    });

    res.status(201).json(storeProduct);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// GET all products sold by a specific store
router.get("/store/:storeId", async (req, res) => {
  try {
    const products = await StoreProduct.find({
      storeId: req.params.storeId,
      isAvailable: true,
    })
      .populate("storeId")
      .populate("productId")
      .populate("sellerId", "fullName email role")
      .sort({ createdAt: -1 });

    res.status(200).json(products);
  } catch (error) {
    console.log("❌ GET STORE PRODUCTS ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});router.get("/trending", async (req, res) => {
  try {
    const reviewPosts = await GroupPost.find({ postType: "review" });

    const stats = {};

    reviewPosts.forEach((post) => {
      if (!post.productId) return;

      const id = post.productId.toString();

      if (!stats[id]) {
        stats[id] = {
          count: 0,
          totalRating: 0,
        };
      }

      stats[id].count += 1;
      stats[id].totalRating += Number(post.rating || 0);
    });

    const productIds = Object.keys(stats);

    const storeProducts = await StoreProduct.find({
      productId: { $in: productIds },
    })
      .populate("productId")
      .populate("storeId")
      .populate("sellerId", "fullName email role");

    const uniqueMap = {};

    storeProducts.forEach((item) => {
      const id = item.productId?._id?.toString();
      if (!id) return;

      if (!uniqueMap[id]) {
        uniqueMap[id] = item;
      }
    });

    const result = Object.values(uniqueMap)
      .map((item) => {
        const id = item.productId?._id?.toString();
        const reviewCount = stats[id]?.count || 0;
        const avgRating =
          reviewCount > 0 ? stats[id].totalRating / reviewCount : 0;

        return {
          ...item.toObject(),
          reviewPostsCount: reviewCount,
          reviewPostsRating: avgRating,
          trendingScore: avgRating * 2 + reviewCount,
        };
      })
      .sort((a, b) => b.trendingScore - a.trendingScore);

    res.status(200).json(result.slice(0, 8));
  } catch (err) {
    console.log("TRENDING ERROR:", err);
    res.status(500).json({
      message: "Failed to get trending products",
      error: err.message,
    });
  }
});
module.exports = router;