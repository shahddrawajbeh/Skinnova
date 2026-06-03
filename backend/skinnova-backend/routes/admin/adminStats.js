const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const User = require("../../models/user");
const Store = require("../../models/store");
const Product = require("../../models/product");
const Order = require("../../models/order");
const Ad = require("../../models/ad");
const Group = require("../../models/group");
const GroupPost = require("../../models/group_posts");

router.get("/", adminMiddleware, async (req, res) => {
  try {
    const [
      totalUsers,
      totalStores,
      pendingStores,
      totalProducts,
      totalOrders,
      totalAds,
      totalGroups,
      totalPosts,
      latestUsers,
      latestProducts,
      latestStores,
      recentOrders,
    ] = await Promise.all([
      User.countDocuments({ role: { $in: ["user", "seller"] } }),
      Store.countDocuments(),
      Store.countDocuments({ approvalStatus: "pending" }),
      Product.countDocuments(),
      Order.countDocuments(),
      Ad.countDocuments(),
      Group.countDocuments(),
      GroupPost.countDocuments(),
      User.find({ role: { $in: ["user", "seller"] } })
        .sort({ createdAt: -1 })
        .limit(5)
        .select("fullName email profileImage role createdAt"),
      Product.find().sort({ createdAt: -1 }).limit(5).select("name brand imageUrl category createdAt"),
      Store.find().sort({ createdAt: -1 }).limit(5)
        .select("storeName logoUrl city isActive approvalStatus createdAt")
        .populate("sellerId", "fullName"),
      Order.find()
        .sort({ createdAt: -1 })
        .limit(5)
        .populate("userId", "fullName email")
        .populate("storeId", "storeName"),
    ]);

    res.json({
      counts: {
        users: totalUsers,
        stores: totalStores,
        pendingStores,
        products: totalProducts,
        orders: totalOrders,
        ads: totalAds,
        groups: totalGroups,
        posts: totalPosts,
      },
      latestUsers,
      latestProducts,
      latestStores,
      recentOrders,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
