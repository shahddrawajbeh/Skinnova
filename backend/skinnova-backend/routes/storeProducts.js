const express = require("express");
const StoreProduct = require("../models/storeProduct");
const GroupPost = require("../models/group_posts");
const User = require("../models/user");
const Store = require("../models/store");
const Product = require("../models/product");
const { sendPushNotification } = require("../helpers/sendPushNotification");
const router = express.Router();

// Helper: send in-app + FCM push to all followers of a store
async function notifyStoreFollowers({ storeId, storeName, title, body, type, productId }) {
  try {
    const followers = await User.find({ followedStores: storeId }).select("_id");
    if (!followers.length) return;
    console.log(`notifyStoreFollowers [${type}] storeId=${storeId} followers=${followers.length}`);
    const promises = followers.map((u) =>
      sendPushNotification({
        userId: u._id.toString(),
        title,
        body,
        type,
        storeId: storeId ? storeId.toString() : undefined,
        productId: productId ? productId.toString() : undefined,
        data: {
          type,
          storeId: storeId ? storeId.toString() : "",
          productId: productId ? productId.toString() : "",
        },
      })
    );
    await Promise.allSettled(promises);
  } catch (e) {
    console.error("notifyStoreFollowers error:", e.message);
  }
}

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
// CREATE or UPDATE store product
router.post("/", async (req, res) => {
  try {
    const { storeId, productId, sellerId, price, currency, stockCount } = req.body;

    if (!storeId || !productId || !sellerId || !price) {
      return res.status(400).json({
        message: "storeId, productId, sellerId, and price are required",
      });
    }

    const existing = await StoreProduct.findOne({
      storeId,
      productId,
    });

    if (existing) {
      const wasOutOfStock = existing.stockCount === 0 && stockCount > 0;

      existing.price = price;
      existing.currency = currency || existing.currency;
      existing.stockCount = stockCount;
      existing.isAvailable = stockCount > 0;

      await existing.save();

      // Restock notification — fire without blocking response
      if (wasOutOfStock) {
        const [storeDoc, productDoc] = await Promise.all([
          Store.findById(storeId).select("storeName"),
          Product.findById(productId).select("name"),
        ]);
        const storeName = storeDoc?.storeName || "A store";
        const productName = productDoc?.name || "A product";
        notifyStoreFollowers({
          storeId,
          storeName,
          title: "Back in stock ✨",
          body: `${productName} is back in stock at ${storeName}`,
          type: "restock",
          productId,
        });
      }

      return res.status(200).json(existing);
    }

    const storeProduct = await StoreProduct.create({
      storeId,
      productId,
      sellerId,
      price,
      currency,
      soldCount: 0,
      stockCount,
      isAvailable: stockCount > 0,
    });

    // New product notification — fire without blocking response
    const [storeDoc, productDoc] = await Promise.all([
      Store.findById(storeId).select("storeName"),
      Product.findById(productId).select("name"),
    ]);
    const storeName = storeDoc?.storeName || "A store";
    const productName = productDoc?.name || "A product";
    notifyStoreFollowers({
      storeId,
      storeName,
      title: `New arrival at ${storeName} 🛍️`,
      body: `${storeName} just added ${productName} to their store`,
      type: "followed_store_new_product",
      productId,
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
.sort({ soldCount: -1, createdAt: -1 });
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
trendingScore:
  (item.soldCount || 0) * 5 +
  reviewCount * 2 +
  avgRating * 3,        };
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
// PUT update a store product (price / stock / availability)
router.put("/:id", async (req, res) => {
  try {
    const sp = await StoreProduct.findById(req.params.id);
    if (!sp) return res.status(404).json({ message: "Store product not found" });

    const { price, stockCount, isAvailable } = req.body;

    if (price !== undefined) sp.price = Number(price);
    if (stockCount !== undefined) {
      sp.stockCount = Number(stockCount);
      sp.isAvailable = Number(stockCount) > 0;
    }
    if (isAvailable !== undefined && stockCount === undefined) {
      sp.isAvailable = Boolean(isAvailable);
    }

    await sp.save();

    const populated = await StoreProduct.findById(sp._id)
      .populate("productId", "name imageUrl brand category")
      .populate("storeId", "storeName");

    res.status(200).json(populated);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// DELETE a product from the store
router.delete("/:id", async (req, res) => {
  try {
    const sp = await StoreProduct.findByIdAndDelete(req.params.id);
    if (!sp) return res.status(404).json({ message: "Store product not found" });
    res.status(200).json({ message: "Product removed from store" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

module.exports = router;