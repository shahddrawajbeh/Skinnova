const Store = require("../models/store");
const StoreProduct = require("../models/storeProduct");
const Order = require("../models/order");
const User = require("../models/user");

// Optional ownership check: only enforced when the caller sends an
// `x-user-id` header (the web frontend does this; the mobile app does not,
// so existing mobile requests pass through unchanged).
const verifyStoreOwner = (resolveStoreId) => async (req, res, next) => {
  try {
    const userId = req.headers["x-user-id"];
    if (!userId) return next();

    const storeId = await resolveStoreId(req);
    if (!storeId) return next();

    const store = await Store.findById(storeId).select("sellerId");
    if (!store) return res.status(404).json({ message: "Store not found" });

    if (store.sellerId.toString() !== userId.toString()) {
      return res.status(403).json({ message: "Forbidden: not your store" });
    }

    next();
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

// Optional role check for routes not tied to a single store (e.g. the
// global product catalog). Only enforced when `x-user-id` is present.
const requireSellerOrAdmin = async (req, res, next) => {
  try {
    const userId = req.headers["x-user-id"];
    if (!userId) return next();

    const user = await User.findById(userId).select("role");
    if (!user) return res.status(401).json({ message: "Unauthorized: User not found" });

    if (!["seller", "admin"].includes(user.role)) {
      return res.status(403).json({ message: "Forbidden: seller or admin access only" });
    }

    next();
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

const resolveStoreProductStoreId = async (req) => {
  const sp = await StoreProduct.findById(req.params.id).select("storeId");
  return sp ? sp.storeId : null;
};

const resolveOrderStoreId = async (req) => {
  const order = await Order.findById(req.params.orderId).select("storeId");
  return order ? order.storeId : null;
};

module.exports = {
  verifyStoreOwner,
  requireSellerOrAdmin,
  resolveStoreProductStoreId,
  resolveOrderStoreId,
};
