const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();

const Cart = require("../models/cart");
const Order = require("../models/order");
const StoreProduct = require("../models/storeProduct");
const Store = require("../models/store");

// create order
router.post("/create", async (req, res) => {
  try {
    const {
      userId,
      fullName,
      phoneNumber,
      city,
      streetAddress,
      note,
      paymentMethod,
      deliveryFee,
    } = req.body;

    if (
      !userId ||
      !fullName ||
      !phoneNumber ||
      !city ||
      !streetAddress ||
      !paymentMethod
    ) {
      return res.status(400).json({
        message: "Missing required fields",
      });
    }

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        message: "Invalid userId",
      });
    }

    const cart = await Cart.findOne({ userId })
      .populate("items.productId")
      .populate("items.storeId");

    if (!cart || cart.items.length === 0) {
      return res.status(400).json({
        message: "Cart is empty",
      });
    }

    const groupedByStore = {};

    cart.items.forEach((item) => {
      const storeId = item.storeId?._id?.toString() || item.storeId?.toString();

      if (!storeId) return;

      if (!groupedByStore[storeId]) {
        groupedByStore[storeId] = [];
      }

      groupedByStore[storeId].push(item);
    });

    const createdOrders = [];

    for (const storeId of Object.keys(groupedByStore)) {
      const storeItems = groupedByStore[storeId];

      const orderItems = storeItems.map((item) => ({
        productId: item.productId._id,
        quantity: item.quantity,
        price: item.price,
        currency: item.currency || "ILS",
      }));

      const storeSubtotal = orderItems.reduce((sum, item) => {
        return sum + item.price * item.quantity;
      }, 0);

      const storeDeliveryFee = deliveryFee || 0;
      const storeTotal = storeSubtotal + storeDeliveryFee;

      const order = new Order({
        userId,
        storeId,
        items: orderItems,
        fullName,
        phoneNumber,
        city,
        streetAddress,
        note: note || "",
        paymentMethod,
        subtotal: storeSubtotal,
        deliveryFee: storeDeliveryFee,
        total: storeTotal,
        status: "pending",
      });

      await order.save();
      const populatedOrder = await Order.findById(order._id)
  .populate("storeId")
  .populate("items.productId");

      for (const item of storeItems) {
        await StoreProduct.findOneAndUpdate(
          {
            storeId: storeId,
            productId: item.productId._id,
            stockCount: { $gte: item.quantity },
          },
          {
            $inc: { stockCount: -item.quantity },
          }
        );
      }

createdOrders.push(populatedOrder);    }

    cart.items = [];
    await cart.save();

    res.status(201).json({
      message: "Orders created successfully",
      orders: createdOrders,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// get orders for one user
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const orders = await Order.find({ userId })
  .populate("items.productId")
  .populate("storeId")
  .sort({ createdAt: -1 });

    res.status(200).json({ orders });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/:orderId/rate-store", async (req, res) => {
  try {
    const { orderId } = req.params;
    const { userId, rating, comment } = req.body;

    if (!userId || !rating) {
      return res.status(400).json({
        message: "userId and rating are required",
      });
    }

    const order = await Order.findById(orderId);

    if (!order) {
      return res.status(404).json({
        message: "Order not found",
      });
    }

    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({
        message: "You cannot rate this order",
      });
    }

    if (order.storeRated) {
      return res.status(400).json({
        message: "Store already rated for this order",
      });
    }

    const store = await Store.findById(order.storeId);

    if (!store) {
      return res.status(404).json({
        message: "Store not found",
      });
    }

    store.reviews.push({
      userId,
      rating,
      comment: comment || "",
    });

    const totalRating = store.reviews.reduce(
      (sum, review) => sum + review.rating,
      0
    );

    store.rating = totalRating / store.reviews.length;

    await store.save();

    order.storeRated = true;
    await order.save();

    res.status(200).json({
      message: "Store rated successfully",
      store,
      order,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
module.exports = router;