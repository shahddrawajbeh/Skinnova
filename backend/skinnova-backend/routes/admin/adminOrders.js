const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const Order = require("../../models/order");

// GET all orders with filters
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { status, userId, storeId, from, to, page = 1, limit = 50 } = req.query;
    const query = {};
    if (status) query.status = status;
    if (userId) query.userId = userId;
    if (storeId) query.storeId = storeId;
    if (from || to) {
      query.createdAt = {};
      if (from) query.createdAt.$gte = new Date(from);
      if (to) query.createdAt.$lte = new Date(to);
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [orders, total] = await Promise.all([
      Order.find(query)
        .populate("userId", "fullName email profileImage")
        .populate("storeId", "storeName logoUrl")
        .populate("items.productId", "name imageUrl brand")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Order.countDocuments(query),
    ]);
    res.json({ orders, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single order
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const order = await Order.findById(req.params.id)
      .populate("userId", "fullName email profileImage")
      .populate("storeId", "storeName logoUrl phone")
      .populate("items.productId", "name imageUrl brand price");
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json(order);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH update order status
router.patch("/:id/status", adminMiddleware, async (req, res) => {
  try {
    const { status } = req.body;
    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true, runValidators: true }
    );
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json(order);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE order
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const order = await Order.findByIdAndDelete(req.params.id);
    if (!order) return res.status(404).json({ message: "Order not found" });
    res.json({ message: "Order deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
