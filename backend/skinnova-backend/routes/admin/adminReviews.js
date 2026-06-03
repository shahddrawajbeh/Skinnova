const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const Product = require("../../models/product");
const Store = require("../../models/store");

// GET all product reviews with optional filter
router.get("/products", adminMiddleware, async (req, res) => {
  try {
    const { productId, userId, minRating, maxRating, page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    let productQuery = {};
    if (productId) productQuery._id = productId;

    const products = await Product.find(productQuery).select("name brand imageUrl reviews");
    let allReviews = [];

    products.forEach((product) => {
      product.reviews.forEach((review) => {
        if (userId && review.userId !== userId) return;
        if (minRating && review.rating < parseInt(minRating)) return;
        if (maxRating && review.rating > parseInt(maxRating)) return;
        allReviews.push({
          ...review.toObject(),
          productId: product._id,
          productName: product.name,
          productImage: product.imageUrl,
          productBrand: product.brand,
          type: "product",
        });
      });
    });

    allReviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const total = allReviews.length;
    const paginated = allReviews.slice(skip, skip + parseInt(limit));

    res.json({ reviews: paginated, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET all store reviews
router.get("/stores", adminMiddleware, async (req, res) => {
  try {
    const { storeId, status, page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    let storeQuery = {};
    if (storeId) storeQuery._id = storeId;

    const stores = await Store.find(storeQuery).select("storeName logoUrl reviews");
    let allReviews = [];

    stores.forEach((store) => {
      store.reviews.forEach((review) => {
        if (status && review.status !== status) return;
        allReviews.push({
          ...review.toObject(),
          storeId: store._id,
          storeName: store.storeName,
          storeLogo: store.logoUrl,
          type: "store",
        });
      });
    });

    allReviews.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    const total = allReviews.length;
    const paginated = allReviews.slice(skip, skip + parseInt(limit));

    res.json({ reviews: paginated, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE product review
router.delete("/products/:productId/:reviewId", adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(
      req.params.productId,
      { $pull: { reviews: { _id: req.params.reviewId } } },
      { new: true }
    );
    if (!product) return res.status(404).json({ message: "Product not found" });
    res.json({ message: "Review deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH store review status (approve/reject)
router.patch("/stores/:storeId/:reviewId/status", adminMiddleware, async (req, res) => {
  try {
    const { status } = req.body;
    const store = await Store.findOneAndUpdate(
      { _id: req.params.storeId, "reviews._id": req.params.reviewId },
      { $set: { "reviews.$.status": status } },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store or review not found" });
    res.json({ message: "Review status updated" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE store review
router.delete("/stores/:storeId/:reviewId", adminMiddleware, async (req, res) => {
  try {
    const store = await Store.findByIdAndUpdate(
      req.params.storeId,
      { $pull: { reviews: { _id: req.params.reviewId } } },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.json({ message: "Review deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
