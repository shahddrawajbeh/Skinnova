const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();

const Cart = require("../models/cart");
const Order = require("../models/order");
const StoreProduct = require("../models/storeProduct");
const Store = require("../models/store");
const User = require("../models/user");
const { sendPushNotification, sendPushToRole } = require("../helpers/sendPushNotification");

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

    // ── Pre-validate stock for every item before creating any order ───────────
    for (const storeId of Object.keys(groupedByStore)) {
      for (const item of groupedByStore[storeId]) {
        const storeProduct = await StoreProduct.findOne({
          storeId,
          productId: item.productId._id,
        });

        if (!storeProduct || !storeProduct.isAvailable || storeProduct.stockCount <= 0) {
          const name = item.productId.name || "A product";
          return res.status(400).json({
            message: `"${name}" is no longer available. Please update your cart.`,
          });
        }

        if (storeProduct.stockCount < item.quantity) {
          const name = item.productId.name || "A product";
          return res.status(400).json({
            message: `Only ${storeProduct.stockCount} item(s) of "${name}" available in stock. Please update your cart.`,
          });
        }
      }
    }
    // ─────────────────────────────────────────────────────────────────────────

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
        const updatedSp = await StoreProduct.findOneAndUpdate(
          {
            storeId: storeId,
            productId: item.productId._id,
            stockCount: { $gte: item.quantity },
          },
          {
            $inc: {
              stockCount: -item.quantity,
              soldCount: item.quantity,
            },
          },
          { new: true }
        );

        // Mark as unavailable when stock hits zero
        if (updatedSp && updatedSp.stockCount <= 0) {
          updatedSp.isAvailable = false;
          await updatedSp.save();
        }
      }

      // Notify seller and admins of new order (fire without blocking)
      Store.findById(storeId).select("sellerId storeName").then((storeDoc) => {
        if (storeDoc) {
          const orderData = {
            type: "new_order",
            orderId: order._id.toString(),
            storeId: storeId.toString(),
          };
          // Notify seller
          sendPushNotification({
            userId: storeDoc.sellerId.toString(),
            title: "New Order Received 🛍️",
            body: `New order for ${storeDoc.storeName} — ILS ${storeTotal.toFixed(0)}`,
            type: "new_order",
            storeId: storeId.toString(),
            data: orderData,
          }).catch(() => {});
          // Notify admins
          sendPushToRole({
            role: "admin",
            title: "New Order 🛍️",
            body: `New order placed at "${storeDoc.storeName}" — ILS ${storeTotal.toFixed(0)}`,
            type: "new_order",
            data: orderData,
          }).catch(() => {});
        }
      }).catch(() => {});

      createdOrders.push(populatedOrder);
    }

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

// GET all orders for a seller's store
router.get("/store/:storeId", async (req, res) => {
  try {
    const orders = await Order.find({ storeId: req.params.storeId })
      .populate("items.productId", "name imageUrl brand")
      .populate("userId", "fullName email")
      .sort({ createdAt: -1 });
    res.status(200).json({ orders });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT update order status (seller action)
router.put("/:orderId/status", async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = [
      "confirmed",
      "processing",
      "out_for_delivery",
      "delivered",
      "cancelled",
    ];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }
    const order = await Order.findByIdAndUpdate(
      req.params.orderId,
      { status },
      { new: true }
    )
      .populate("items.productId", "name imageUrl")
      .populate("userId", "fullName");
    if (!order) return res.status(404).json({ message: "Order not found" });

    // Notify buyer of status change (fire without blocking)
    const statusLabels = {
      confirmed: "confirmed ✅",
      processing: "being processed 🔄",
      out_for_delivery: "out for delivery 🚚",
      delivered: "delivered 📦",
      cancelled: "cancelled ❌",
    };
    const notifTitle = status === "delivered" ? "Order Delivered 📦" : "Order Update";
    const notifBody = status === "delivered"
      ? "Your order has been marked as delivered. Please confirm when you receive it."
      : `Your order is now ${statusLabels[status] || status}`;
    sendPushNotification({
      userId: order.userId._id ? order.userId._id.toString() : order.userId.toString(),
      title: notifTitle,
      body: notifBody,
      type: "order_status_changed",
      data: { type: "order_status_changed", orderId: order._id.toString(), status },
    }).catch(() => {});

    res.status(200).json({ message: "Status updated", order });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET flattened purchase history for one user
router.get("/purchase-history/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ success: false, message: "Invalid userId" });
    }

    const orders = await Order.find({ userId })
      .populate("items.productId", "name imageUrl brand directionsOfUse")
      .populate("storeId", "storeName")
      .sort({ createdAt: -1 });

    const purchases = [];

    for (const order of orders) {
      for (const item of order.items) {
        const product = item.productId;
        purchases.push({
          orderId: order._id.toString(),
          productId: product?._id?.toString() ?? null,
          productName: product?.name ?? "Deleted Product",
          brand: product?.brand ?? "",
          imageUrl: product?.imageUrl ?? "",
          storeName: order.storeId?.storeName ?? "Unknown Store",
          purchasedAt: order.createdAt,
          quantity: item.quantity,
          price: item.price,
          currency: item.currency || "ILS",
          status: order.status,
          directionsOfUse: product?.directionsOfUse ?? "",
          userConfirmedDelivery: order.userConfirmedDelivery || false,
          userConfirmedDeliveryAt: order.userConfirmedDeliveryAt || null,
        });
      }
    }

    res.json({ success: true, purchases });
  } catch (err) {
    res.status(500).json({ success: false, message: "Server error", error: err.message });
  }
});

// PUT user confirms receiving a delivered order
router.put("/confirm-received/:orderId", async (req, res) => {
  try {
    const { orderId } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ message: "Order not found" });
    }
    if (order.userId.toString() !== userId.toString()) {
      return res.status(403).json({ message: "Not authorized to confirm this order" });
    }
    if (order.status !== "delivered") {
      return res.status(400).json({ message: "Order must be delivered before confirming receipt" });
    }
    if (order.userConfirmedDelivery) {
      return res.status(400).json({ message: "Receipt already confirmed for this order" });
    }

    order.userConfirmedDelivery = true;
    order.userConfirmedDeliveryAt = new Date();
    await order.save();

    // Notify seller (fire without blocking)
    Store.findById(order.storeId).select("sellerId storeName").then((storeDoc) => {
      if (storeDoc) {
        sendPushNotification({
          userId: storeDoc.sellerId.toString(),
          title: "Order Confirmed ✅",
          body: `The customer confirmed receiving the order from ${storeDoc.storeName}`,
          type: "order_confirmed_received",
          data: { type: "order_confirmed_received", orderId: orderId },
        }).catch(() => {});
      }
    }).catch(() => {});

    res.json({ message: "Order receipt confirmed", order });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
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
    const { userId, userName, rating, comment } = req.body;

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

    // Resolve name from database — do not trust client-sent value
    const userDoc = await User.findById(userId).select("fullName");
    const resolvedName =
      (userDoc && userDoc.fullName && userDoc.fullName.trim())
        ? userDoc.fullName.trim()
        : (userName && userName.trim() ? userName.trim() : "Customer");

    store.reviews.push({
      userId,
      userName: resolvedName,
      rating,
      comment: comment || "",
      status: "pending",
    });

    // Rating is recalculated only when admin approves; do not update here
    await store.save();

    order.storeRated = true;
    await order.save();

    // Notify seller and admins of new pending review (fire without blocking)
    Store.findById(order.storeId).select("sellerId storeName").then((storeDoc) => {
      if (storeDoc) {
        const storeIdStr = order.storeId.toString();
        // Notify seller
        sendPushNotification({
          userId: storeDoc.sellerId.toString(),
          title: "New Review Received ⭐",
          body: `${resolvedName} left a ${rating}-star review for ${storeDoc.storeName}`,
          type: "review_submitted",
          storeId: storeIdStr,
          data: { type: "review_submitted", storeId: storeIdStr },
        }).catch(() => {});
        // Notify admins (review needs approval)
        sendPushToRole({
          role: "admin",
          title: "New Pending Review ⭐",
          body: `${resolvedName} reviewed "${storeDoc.storeName}" (${rating}★) — needs approval`,
          type: "review_pending",
          data: { type: "review_pending", storeId: storeIdStr },
        }).catch(() => {});
      }
    }).catch(() => {});

    res.status(200).json({
      message: "Review submitted and pending admin approval",
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