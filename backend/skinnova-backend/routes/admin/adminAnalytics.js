const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const User = require("../../models/user");
const Order = require("../../models/order");

const MONTHS = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"];

function emptyMonths() {
  return MONTHS.map((month) => ({ month, value: 0 }));
}

router.get("/charts", adminMiddleware, async (req, res) => {
  try {
    const year = new Date().getFullYear();
    const yearStart = new Date(year, 0, 1);
    const yearEnd = new Date(year + 1, 0, 1);

    const [revenueRaw, ordersRaw, productsRaw, usersRaw, storesRaw] =
      await Promise.all([
        // Monthly Revenue – delivered orders only, current year
        Order.aggregate([
          {
            $match: {
              status: "delivered",
              createdAt: { $gte: yearStart, $lt: yearEnd },
            },
          },
          {
            $group: {
              _id: { month: { $month: "$createdAt" } },
              value: { $sum: "$total" },
            },
          },
          { $sort: { "_id.month": 1 } },
        ]),

        // Monthly Orders – all statuses, current year
        Order.aggregate([
          { $match: { createdAt: { $gte: yearStart, $lt: yearEnd } } },
          {
            $group: {
              _id: { month: { $month: "$createdAt" } },
              value: { $sum: 1 },
            },
          },
          { $sort: { "_id.month": 1 } },
        ]),

        // Best-Selling Products – top 10 by quantity, all time
        Order.aggregate([
          { $unwind: "$items" },
          {
            $group: {
              _id: "$items.productId",
              value: { $sum: "$items.quantity" },
            },
          },
          { $sort: { value: -1 } },
          { $limit: 10 },
          {
            $lookup: {
              from: "products",
              localField: "_id",
              foreignField: "_id",
              as: "product",
            },
          },
          { $unwind: { path: "$product", preserveNullAndEmptyArrays: true } },
          {
            $project: {
              name: { $ifNull: ["$product.name", "Unknown"] },
              value: 1,
            },
          },
        ]),

        // Monthly New Users – current year
        User.aggregate([
          {
            $match: {
              role: { $in: ["user", "seller"] },
              createdAt: { $gte: yearStart, $lt: yearEnd },
            },
          },
          {
            $group: {
              _id: { month: { $month: "$createdAt" } },
              value: { $sum: 1 },
            },
          },
          { $sort: { "_id.month": 1 } },
        ]),

        // Store Sales Comparison – delivered orders, all time, top 10
        Order.aggregate([
          { $match: { status: "delivered" } },
          {
            $group: {
              _id: "$storeId",
              value: { $sum: "$total" },
            },
          },
          { $sort: { value: -1 } },
          { $limit: 10 },
          {
            $lookup: {
              from: "stores",
              localField: "_id",
              foreignField: "_id",
              as: "store",
            },
          },
          { $unwind: { path: "$store", preserveNullAndEmptyArrays: true } },
          {
            $project: {
              name: { $ifNull: ["$store.storeName", "Unknown"] },
              value: 1,
            },
          },
        ]),
      ]);

    // Merge raw month data into full 12-month arrays
    const revenueMonths = emptyMonths();
    revenueRaw.forEach((r) => {
      revenueMonths[r._id.month - 1].value = Math.round(r.value * 100) / 100;
    });

    const ordersMonths = emptyMonths();
    ordersRaw.forEach((r) => {
      ordersMonths[r._id.month - 1].value = r.value;
    });

    const usersMonths = emptyMonths();
    usersRaw.forEach((r) => {
      usersMonths[r._id.month - 1].value = r.value;
    });

    res.json({
      monthlyRevenue: revenueMonths,
      monthlyOrders: ordersMonths,
      bestSellingProducts: productsRaw.map((p) => ({ name: p.name, value: p.value })),
      monthlyUsers: usersMonths,
      storeSales: storesRaw.map((s) => ({
        name: s.name,
        value: Math.round(s.value * 100) / 100,
      })),
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
