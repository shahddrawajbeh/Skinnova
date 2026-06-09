const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const User = require("../../models/user");
const Order = require("../../models/order");
const Store = require("../../models/store");
const Product = require("../../models/product");
const StoreProduct = require("../../models/storeProduct");
const SkinScan = require("../../models/SkinScan");
const Notification = require("../../models/notification");
const LoginActivity = require("../../models/LoginActivity");
const { generateCsv } = require("../../utils/exportCsv");

// ── helpers ──────────────────────────────────────────────────────────────────
function dateRange(from, to) {
  if (!from && !to) return null;
  const range = {};
  if (from) range.$gte = new Date(from);
  if (to) {
    const d = new Date(to);
    d.setHours(23, 59, 59, 999);
    range.$lte = d;
  }
  return range;
}

function paginate(page, limit) {
  const p = Math.max(1, parseInt(page) || 1);
  const l = Math.min(200, Math.max(1, parseInt(limit) || 50));
  return { skip: (p - 1) * l, limit: l, page: p };
}

function sendCsv(res, filename, columns, rows) {
  const csv = generateCsv(columns, rows);
  res.setHeader("Content-Type", "text/csv; charset=utf-8");
  res.setHeader("Content-Disposition", `attachment; filename="${filename}"`);
  return res.send(csv);
}

// ── Quick hub stats ───────────────────────────────────────────────────────────
router.get("/stats", adminMiddleware, async (req, res) => {
  try {
    const [
      totalUsers,
      totalStores,
      totalOrders,
      revenueAgg,
      totalAI,
    ] = await Promise.all([
      User.countDocuments({ role: { $in: ["user", "seller"] } }),
      Store.countDocuments(),
      Order.countDocuments(),
      Order.aggregate([
        { $match: { status: "delivered" } },
        { $group: { _id: null, total: { $sum: "$total" } } },
      ]),
      SkinScan.countDocuments(),
    ]);

    res.json({
      totalUsers,
      totalStores,
      totalOrders,
      totalRevenue: revenueAgg[0]?.total || 0,
      totalAI,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 1. User Report ─────────────────────────────────────────────────────────────
router.get("/users", adminMiddleware, async (req, res) => {
  try {
    const {
      from, to, status, sort = "newest",
      search, page = 1, limit = 50, export: exp,
    } = req.query;

    const match = {};
    if (status === "active") match.isActive = { $ne: false };
    else if (status === "inactive") match.isActive = false;
    else if (status === "new") {
      match.createdAt = { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) };
    }

    const dr = dateRange(from, to);
    if (dr && status !== "new") match.createdAt = dr;

    if (search) {
      match.$or = [
        { fullName: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
        { phone: { $regex: search, $options: "i" } },
      ];
    }

    const sortMap = {
      newest: { createdAt: -1 },
      oldest: { createdAt: 1 },
      mostOrders: { ordersCount: -1 },
      mostPurchases: { totalSpent: -1 },
      mostScans: { aiScanCount: -1 },
    };

    const basePipeline = [
      { $match: match },
      {
        $lookup: {
          from: "orders",
          let: { uid: "$_id" },
          pipeline: [
            { $match: { $expr: { $eq: ["$userId", "$$uid"] } } },
            { $project: { status: 1, total: 1 } },
          ],
          as: "orders",
        },
      },
      {
        $lookup: {
          from: "skinscans",
          let: { uid: { $toString: "$_id" } },
          pipeline: [
            { $match: { $expr: { $eq: ["$userId", "$$uid"] } } },
            { $project: { _id: 1 } },
          ],
          as: "scans",
        },
      },
      {
        $addFields: {
          ordersCount: { $size: "$orders" },
          totalSpent: {
            $sum: {
              $map: {
                input: {
                  $filter: {
                    input: "$orders",
                    as: "o",
                    cond: { $eq: ["$$o.status", "delivered"] },
                  },
                },
                as: "o",
                in: "$$o.total",
              },
            },
          },
          aiScanCount: { $size: "$scans" },
          statusLabel: {
            $cond: [{ $eq: ["$isActive", false] }, "Inactive", "Active"],
          },
        },
      },
      { $project: { password: 0, orders: 0, scans: 0 } },
    ];

    const sortStage = { $sort: sortMap[sort] || { createdAt: -1 } };
    const { skip, limit: lim, page: p } = paginate(page, limit);

    const [users, countRes, summaryRes] = await Promise.all([
      User.aggregate([
        ...basePipeline,
        sortStage,
        { $skip: skip },
        { $limit: lim },
      ]),
      User.aggregate([...basePipeline, { $count: "total" }]),
      User.aggregate([
        { $match: {} },
        {
          $group: {
            _id: null,
            totalUsers: { $sum: 1 },
            activeUsers: { $sum: { $cond: [{ $ne: ["$isActive", false] }, 1, 0] } },
            inactiveUsers: { $sum: { $cond: [{ $eq: ["$isActive", false] }, 1, 0] } },
            newUsers: {
              $sum: {
                $cond: [
                  { $gte: ["$createdAt", new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)] },
                  1, 0,
                ],
              },
            },
          },
        },
      ]),
    ]);

    const summary = summaryRes[0] || {
      totalUsers: 0, activeUsers: 0, inactiveUsers: 0, newUsers: 0,
    };

    if (exp === "csv") {
      const cols = [
        { key: "fullName", label: "Name" },
        { key: "email", label: "Email" },
        { key: "phone", label: "Phone" },
        { key: "createdAt", label: "Join Date" },
        { key: "ordersCount", label: "Orders" },
        { key: "aiScanCount", label: "AI Scans" },
        { key: "totalSpent", label: "Total Purchases (ILS)" },
        { key: "statusLabel", label: "Status" },
      ];
      const rows = users.map((u) => ({
        ...u,
        createdAt: u.createdAt ? new Date(u.createdAt).toLocaleDateString() : "",
        totalSpent: (u.totalSpent || 0).toFixed(2),
      }));
      return sendCsv(res, "user_report.csv", cols, rows);
    }

    res.json({
      users,
      total: countRes[0]?.total || 0,
      page: p,
      summary,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 2. Store Report ────────────────────────────────────────────────────────────
router.get("/stores", adminMiddleware, async (req, res) => {
  try {
    const {
      from, to, filter = "all", search,
      page = 1, limit = 50, export: exp,
    } = req.query;

    const match = {};
    const dr = dateRange(from, to);
    if (dr) match.createdAt = dr;
    if (search) match.storeName = { $regex: search, $options: "i" };

    const pipeline = [
      { $match: match },
      {
        $lookup: {
          from: "orders",
          localField: "_id",
          foreignField: "storeId",
          as: "storeOrders",
        },
      },
      {
        $lookup: {
          from: "storeproducts",
          localField: "_id",
          foreignField: "storeId",
          as: "storeProducts",
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "sellerId",
          foreignField: "_id",
          as: "ownerArr",
        },
      },
      {
        $addFields: {
          revenue: {
            $sum: {
              $map: {
                input: {
                  $filter: {
                    input: "$storeOrders",
                    as: "o",
                    cond: { $eq: ["$$o.status", "delivered"] },
                  },
                },
                as: "o",
                in: "$$o.total",
              },
            },
          },
          ordersCount: { $size: "$storeOrders" },
          productsCount: { $size: "$storeProducts" },
          owner: { $arrayElemAt: ["$ownerArr.fullName", 0] },
        },
      },
      { $project: { storeOrders: 0, storeProducts: 0, ownerArr: 0 } },
    ];

    const sortMap = {
      all: { createdAt: -1 },
      topRevenue: { revenue: -1 },
      mostOrders: { ordersCount: -1 },
      highestRating: { rating: -1 },
      newest: { createdAt: -1 },
    };
    pipeline.push({ $sort: sortMap[filter] || { createdAt: -1 } });

    const { skip, limit: lim, page: p } = paginate(page, limit);

    const [stores, countRes] = await Promise.all([
      Store.aggregate([...pipeline, { $skip: skip }, { $limit: lim }]),
      Store.aggregate([...pipeline.slice(0, -1), { $count: "total" }]),
    ]);

    if (exp === "csv") {
      const cols = [
        { key: "storeName", label: "Store" },
        { key: "owner", label: "Owner" },
        { key: "createdAt", label: "Join Date" },
        { key: "revenue", label: "Revenue (ILS)" },
        { key: "ordersCount", label: "Orders" },
        { key: "productsCount", label: "Products" },
        { key: "rating", label: "Rating" },
        { key: "isApproved", label: "Approved" },
      ];
      const rows = stores.map((s) => ({
        ...s,
        createdAt: s.createdAt ? new Date(s.createdAt).toLocaleDateString() : "",
        revenue: (s.revenue || 0).toFixed(2),
        isApproved: s.isApproved ? "Yes" : "No",
      }));
      return sendCsv(res, "store_report.csv", cols, rows);
    }

    res.json({ stores, total: countRes[0]?.total || 0, page: p });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 3. Order Report ────────────────────────────────────────────────────────────
router.get("/orders", adminMiddleware, async (req, res) => {
  try {
    const {
      from, to, status, search,
      page = 1, limit = 50, export: exp,
    } = req.query;

    const match = {};
    if (status) match.status = status;
    const dr = dateRange(from, to);
    if (dr) match.createdAt = dr;
    if (search) {
      match.$or = [
        { fullName: { $regex: search, $options: "i" } },
        { "deliveryDetails.city": { $regex: search, $options: "i" } },
      ];
    }

    const { skip, limit: lim, page: p } = paginate(page, limit);

    const [orders, countRes, summaryRes] = await Promise.all([
      Order.find(match)
        .populate("userId", "fullName email")
        .populate("storeId", "storeName")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(lim)
        .lean(),
      Order.countDocuments(match),
      Order.aggregate([
        {
          $group: {
            _id: null,
            totalOrders: { $sum: 1 },
            delivered: { $sum: { $cond: [{ $eq: ["$status", "delivered"] }, 1, 0] } },
            cancelled: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } },
            totalRevenue: {
              $sum: { $cond: [{ $eq: ["$status", "delivered"] }, "$total", 0] },
            },
            avgOrderValue: { $avg: "$total" },
          },
        },
      ]),
    ]);

    const summary = summaryRes[0] || {
      totalOrders: 0, delivered: 0, cancelled: 0,
      totalRevenue: 0, avgOrderValue: 0,
    };

    if (exp === "csv") {
      const cols = [
        { key: "orderId", label: "Order ID" },
        { key: "customer", label: "Customer" },
        { key: "store", label: "Store" },
        { key: "itemsCount", label: "Items" },
        { key: "total", label: "Total (ILS)" },
        { key: "status", label: "Status" },
        { key: "paymentMethod", label: "Payment" },
        { key: "createdAt", label: "Created Date" },
      ];
      const rows = orders.map((o) => ({
        orderId: o._id?.toString().slice(-8).toUpperCase() || "",
        customer: o.userId?.fullName || o.fullName || "",
        store: o.storeId?.storeName || "",
        itemsCount: o.items?.length || 0,
        total: (o.total || 0).toFixed(2),
        status: o.status || "",
        paymentMethod: o.paymentMethod || "",
        createdAt: o.createdAt ? new Date(o.createdAt).toLocaleDateString() : "",
      }));
      return sendCsv(res, "order_report.csv", cols, rows);
    }

    res.json({
      orders,
      total: countRes,
      page: p,
      summary,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 4. Product Report ──────────────────────────────────────────────────────────
router.get("/products", adminMiddleware, async (req, res) => {
  try {
    const {
      from, to, filter = "all", search,
      page = 1, limit = 50, export: exp,
    } = req.query;

    const match = {};
    const dr = dateRange(from, to);
    if (dr) match.createdAt = dr;
    if (search) {
      match.$or = [
        { name: { $regex: search, $options: "i" } },
        { brand: { $regex: search, $options: "i" } },
      ];
    }

    const pipeline = [
      { $match: match },
      {
        $lookup: {
          from: "storeproducts",
          localField: "_id",
          foreignField: "productId",
          as: "sp",
        },
      },
      {
        $addFields: {
          totalSold: { $sum: "$sp.soldCount" },
          totalStock: { $sum: "$sp.stockCount" },
          revenue: {
            $sum: {
              $map: {
                input: "$sp",
                as: "s",
                in: { $multiply: ["$$s.soldCount", "$$s.price"] },
              },
            },
          },
          storeCount: { $size: "$sp" },
        },
      },
      { $project: { sp: 0 } },
    ];

    const sortMap = {
      all: { createdAt: -1 },
      bestSelling: { totalSold: -1 },
      leastSelling: { totalSold: 1 },
      highestRated: { rating: -1 },
      lowestRated: { rating: 1 },
      outOfStock: { totalStock: 1 },
    };
    pipeline.push({ $sort: sortMap[filter] || { createdAt: -1 } });

    const { skip, limit: lim, page: p } = paginate(page, limit);

    const [products, countRes] = await Promise.all([
      Product.aggregate([...pipeline, { $skip: skip }, { $limit: lim }]),
      Product.aggregate([...pipeline.slice(0, -1), { $count: "total" }]),
    ]);

    if (exp === "csv") {
      const cols = [
        { key: "name", label: "Product" },
        { key: "brand", label: "Brand" },
        { key: "storeCount", label: "Stores" },
        { key: "totalSold", label: "Units Sold" },
        { key: "totalStock", label: "Stock" },
        { key: "rating", label: "Rating" },
        { key: "revenue", label: "Revenue (ILS)" },
      ];
      const rows = products.map((p) => ({
        ...p,
        revenue: (p.revenue || 0).toFixed(2),
      }));
      return sendCsv(res, "product_report.csv", cols, rows);
    }

    res.json({ products, total: countRes[0]?.total || 0, page: p });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 5. AI Report ───────────────────────────────────────────────────────────────
router.get("/ai", adminMiddleware, async (req, res) => {
  try {
    const { from, to, export: exp } = req.query;
    const match = {};
    const dr = dateRange(from, to);
    if (dr) match.createdAt = dr;

    const [scansAgg, concernsAgg] = await Promise.all([
      SkinScan.aggregate([
        { $match: match },
        {
          $group: {
            _id: null,
            totalScans: { $sum: 1 },
            avgScore: { $avg: "$skinScore" },
            withMorning: {
              $sum: { $cond: [{ $gt: [{ $size: { $ifNull: ["$morningRoutine", []] } }, 0] }, 1, 0] },
            },
            withEvening: {
              $sum: { $cond: [{ $gt: [{ $size: { $ifNull: ["$eveningRoutine", []] } }, 0] }, 1, 0] },
            },
          },
        },
      ]),
      SkinScan.aggregate([
        { $match: match },
        { $unwind: { path: "$detectedConcerns", preserveNullAndEmptyArrays: false } },
        {
          $group: {
            _id: "$detectedConcerns.name",
            occurrences: { $sum: 1 },
            avgSeverity: { $avg: "$detectedConcerns.severityScore" },
          },
        },
        { $sort: { occurrences: -1 } },
        { $limit: 10 },
      ]),
    ]);

    const totalScans = scansAgg[0]?.totalScans || 0;
    const totalRoutines = (scansAgg[0]?.withMorning || 0) + (scansAgg[0]?.withEvening || 0);

    const concerns = concernsAgg.map((c) => ({
      concern: c._id || "Unknown",
      occurrences: c.occurrences,
      avgSeverity: c.avgSeverity?.toFixed(1) || "0.0",
      percentage: totalScans > 0
        ? ((c.occurrences / totalScans) * 100).toFixed(1)
        : "0.0",
    }));

    if (exp === "csv") {
      const cols = [
        { key: "concern", label: "Skin Concern" },
        { key: "occurrences", label: "Occurrences" },
        { key: "avgSeverity", label: "Avg Severity" },
        { key: "percentage", label: "Percentage (%)" },
      ];
      return sendCsv(res, "ai_report.csv", cols, concerns);
    }

    res.json({
      summary: {
        totalScans,
        totalRoutines,
        avgSkinScore: scansAgg[0]?.avgScore?.toFixed(1) || "0.0",
      },
      concerns,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 6. Login Activity Report ───────────────────────────────────────────────────
router.get("/login-activity", adminMiddleware, async (req, res) => {
  try {
    const {
      from, to, userId, device, search,
      page = 1, limit = 50, export: exp,
    } = req.query;

    const match = {};
    const dr = dateRange(from, to);
    if (dr) match.loginTime = dr;
    if (userId) match.userId = userId;
    if (device) match.device = { $regex: device, $options: "i" };

    const { skip, limit: lim, page: p } = paginate(page, limit);

    const baseQuery = LoginActivity.find(match)
      .populate("userId", "fullName email")
      .sort({ loginTime: -1 });

    if (search) {
      // Post-populate filter is tricky; handle via aggregation
    }

    const [records, total, summaryAgg] = await Promise.all([
      baseQuery.skip(skip).limit(lim).lean(),
      LoginActivity.countDocuments(match),
      LoginActivity.aggregate([
        { $match: match },
        {
          $group: {
            _id: null,
            totalLogins: { $sum: 1 },
            avgSession: { $avg: "$sessionDuration" },
            peakHour: {
              $push: { $hour: "$loginTime" },
            },
          },
        },
      ]),
    ]);

    const hours = summaryAgg[0]?.peakHour || [];
    const hourCount = {};
    hours.forEach((h) => { hourCount[h] = (hourCount[h] || 0) + 1; });
    const peakHour = Object.entries(hourCount).sort((a, b) => b[1] - a[1])[0]?.[0] ?? null;

    if (exp === "csv") {
      const cols = [
        { key: "user", label: "User" },
        { key: "email", label: "Email" },
        { key: "loginTime", label: "Login Time" },
        { key: "logoutTime", label: "Logout Time" },
        { key: "duration", label: "Duration (min)" },
        { key: "device", label: "Device" },
        { key: "platform", label: "Platform" },
        { key: "ipAddress", label: "IP Address" },
      ];
      const rows = records.map((r) => ({
        user: r.userId?.fullName || "",
        email: r.userId?.email || "",
        loginTime: r.loginTime ? new Date(r.loginTime).toLocaleString() : "",
        logoutTime: r.logoutTime ? new Date(r.logoutTime).toLocaleString() : "Active",
        duration: r.sessionDuration ? Math.round(r.sessionDuration / 60) : "",
        device: r.device || "",
        platform: r.platform || "",
        ipAddress: r.ipAddress || "",
      }));
      return sendCsv(res, "login_activity_report.csv", cols, rows);
    }

    res.json({
      records,
      total,
      page: p,
      summary: {
        totalLogins: summaryAgg[0]?.totalLogins || 0,
        avgSessionMinutes: summaryAgg[0]?.avgSession
          ? Math.round(summaryAgg[0].avgSession / 60)
          : 0,
        peakHour: peakHour !== null ? `${peakHour}:00` : "N/A",
      },
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 7. Notification Report ─────────────────────────────────────────────────────
router.get("/notifications", adminMiddleware, async (req, res) => {
  try {
    const { from, to, export: exp } = req.query;
    const match = { sentByAdmin: true };
    const dr = dateRange(from, to);
    if (dr) match.createdAt = dr;

    const [agg, total, read] = await Promise.all([
      Notification.aggregate([
        { $match: match },
        {
          $group: {
            _id: "$title",
            count: { $sum: 1 },
            readCount: { $sum: { $cond: ["$isRead", 1, 0] } },
            latest: { $max: "$createdAt" },
            type: { $first: "$type" },
          },
        },
        { $sort: { count: -1 } },
      ]),
      Notification.countDocuments(match),
      Notification.countDocuments({ ...match, isRead: true }),
    ]);

    const rows = agg.map((n) => ({
      notification: n._id || "Untitled",
      type: n.type || "",
      recipients: n.count,
      opened: n.readCount,
      openRate: n.count > 0 ? ((n.readCount / n.count) * 100).toFixed(1) + "%" : "0%",
      createdAt: n.latest ? new Date(n.latest).toLocaleDateString() : "",
    }));

    if (exp === "csv") {
      const cols = [
        { key: "notification", label: "Notification" },
        { key: "type", label: "Type" },
        { key: "recipients", label: "Recipients" },
        { key: "opened", label: "Opened" },
        { key: "openRate", label: "Open Rate" },
        { key: "createdAt", label: "Sent At" },
      ];
      return sendCsv(res, "notification_report.csv", cols, rows);
    }

    res.json({
      notifications: rows,
      summary: {
        total,
        delivered: total,
        opened: read,
        avgOpenRate: total > 0 ? ((read / total) * 100).toFixed(1) + "%" : "0%",
      },
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 8. Review Report ───────────────────────────────────────────────────────────
router.get("/reviews", adminMiddleware, async (req, res) => {
  try {
    const { from, to, search, export: exp } = req.query;

    const matchStore = {};
    if (search) matchStore.storeName = { $regex: search, $options: "i" };

    const pipeline = [
      { $match: matchStore },
      { $unwind: { path: "$reviews", preserveNullAndEmptyArrays: true } },
      ...(from || to
        ? [
            {
              $match: {
                "reviews.createdAt": dateRange(from, to) || { $exists: true },
              },
            },
          ]
        : []),
      {
        $group: {
          _id: "$_id",
          storeName: { $first: "$storeName" },
          logoUrl: { $first: "$logoUrl" },
          reviewCount: { $sum: { $cond: [{ $ifNull: ["$reviews", false] }, 1, 0] } },
          avgRating: { $avg: "$reviews.rating" },
          positiveCount: {
            $sum: { $cond: [{ $gte: ["$reviews.rating", 4] }, 1, 0] },
          },
          negativeCount: {
            $sum: { $cond: [{ $lte: ["$reviews.rating", 2] }, 1, 0] },
          },
        },
      },
      {
        $addFields: {
          positivePct: {
            $cond: [
              { $gt: ["$reviewCount", 0] },
              {
                $concat: [
                  { $toString: { $round: [{ $multiply: [{ $divide: ["$positiveCount", "$reviewCount"] }, 100] }, 0] } },
                  "%",
                ],
              },
              "0%",
            ],
          },
          negativePct: {
            $cond: [
              { $gt: ["$reviewCount", 0] },
              {
                $concat: [
                  { $toString: { $round: [{ $multiply: [{ $divide: ["$negativeCount", "$reviewCount"] }, 100] }, 0] } },
                  "%",
                ],
              },
              "0%",
            ],
          },
        },
      },
      { $sort: { reviewCount: -1 } },
    ];

    const [stores, summaryAgg] = await Promise.all([
      Store.aggregate(pipeline),
      Store.aggregate([
        {
          $unwind: { path: "$reviews", preserveNullAndEmptyArrays: false },
        },
        {
          $group: {
            _id: null,
            totalReviews: { $sum: 1 },
            highestRated: { $max: "$rating" },
            lowestRated: { $min: "$rating" },
          },
        },
      ]),
    ]);

    if (exp === "csv") {
      const cols = [
        { key: "storeName", label: "Store" },
        { key: "reviewCount", label: "Reviews" },
        { key: "avgRating", label: "Avg Rating" },
        { key: "positivePct", label: "Positive %" },
        { key: "negativePct", label: "Negative %" },
      ];
      const rows = stores.map((s) => ({
        storeName: s.storeName || "",
        reviewCount: s.reviewCount || 0,
        avgRating: s.avgRating?.toFixed(1) || "0.0",
        positivePct: s.positivePct || "0%",
        negativePct: s.negativePct || "0%",
      }));
      return sendCsv(res, "review_report.csv", cols, rows);
    }

    res.json({
      stores,
      summary: {
        totalReviews: summaryAgg[0]?.totalReviews || 0,
        highestRated: summaryAgg[0]?.highestRated || 0,
        lowestRated: summaryAgg[0]?.lowestRated || 0,
      },
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 9. Revenue Report ──────────────────────────────────────────────────────────
router.get("/revenue", adminMiddleware, async (req, res) => {
  try {
    const { from, to, export: exp } = req.query;

    const match = {};
    const dr = dateRange(from, to);
    if (dr) match.createdAt = dr;

    const [summaryAgg, storeAgg] = await Promise.all([
      Order.aggregate([
        { $match: match },
        {
          $group: {
            _id: null,
            totalRevenue: {
              $sum: { $cond: [{ $eq: ["$status", "delivered"] }, "$total", 0] },
            },
            totalOrders: { $sum: 1 },
            delivered: { $sum: { $cond: [{ $eq: ["$status", "delivered"] }, 1, 0] } },
            cancelled: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } },
            avgOrderValue: { $avg: "$total" },
          },
        },
      ]),
      Order.aggregate([
        { $match: match },
        {
          $group: {
            _id: "$storeId",
            orders: { $sum: 1 },
            revenue: {
              $sum: { $cond: [{ $eq: ["$status", "delivered"] }, "$total", 0] },
            },
            cancelled: { $sum: { $cond: [{ $eq: ["$status", "cancelled"] }, 1, 0] } },
          },
        },
        {
          $lookup: {
            from: "stores",
            localField: "_id",
            foreignField: "_id",
            as: "store",
          },
        },
        {
          $addFields: {
            storeName: { $arrayElemAt: ["$store.storeName", 0] },
            netRevenue: "$revenue",
          },
        },
        { $project: { store: 0 } },
        { $sort: { revenue: -1 } },
      ]),
    ]);

    const summary = summaryAgg[0] || {
      totalRevenue: 0, totalOrders: 0, delivered: 0,
      cancelled: 0, avgOrderValue: 0,
    };

    if (exp === "csv") {
      const cols = [
        { key: "storeName", label: "Store" },
        { key: "orders", label: "Orders" },
        { key: "revenue", label: "Revenue (ILS)" },
        { key: "cancelled", label: "Cancelled Orders" },
        { key: "netRevenue", label: "Net Revenue (ILS)" },
      ];
      const rows = storeAgg.map((s) => ({
        storeName: s.storeName || "Unknown",
        orders: s.orders || 0,
        revenue: (s.revenue || 0).toFixed(2),
        cancelled: s.cancelled || 0,
        netRevenue: (s.netRevenue || 0).toFixed(2),
      }));
      return sendCsv(res, "revenue_report.csv", cols, rows);
    }

    res.json({ summary, stores: storeAgg });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── 10. Custom Report ──────────────────────────────────────────────────────────
router.post("/custom", adminMiddleware, async (req, res) => {
  try {
    const {
      entity, columns: selectedCols, filters = {},
      sortField, sortOrder = "desc",
      page = 1, limit = 50, export: exp,
    } = req.body;

    const modelMap = {
      users: User,
      stores: Store,
      orders: Order,
      products: Product,
    };

    const Model = modelMap[entity];
    if (!Model) return res.status(400).json({ message: "Invalid entity" });

    const match = {};
    if (filters.status) {
      if (entity === "users") match.isActive = filters.status === "active" ? { $ne: false } : false;
      else if (entity === "orders") match.status = filters.status;
    }
    if (filters.search) {
      const textFields = {
        users: ["fullName", "email"],
        stores: ["storeName"],
        orders: ["fullName"],
        products: ["name", "brand"],
      };
      const fields = textFields[entity] || [];
      if (fields.length) {
        match.$or = fields.map((f) => ({ [f]: { $regex: filters.search, $options: "i" } }));
      }
    }
    const dr = dateRange(filters.from, filters.to);
    if (dr) match.createdAt = dr;

    const sortDir = sortOrder === "asc" ? 1 : -1;
    const sortObj = sortField ? { [sortField]: sortDir } : { createdAt: sortDir };

    const { skip, limit: lim, page: p } = paginate(page, limit);

    const [data, total] = await Promise.all([
      Model.find(match)
        .select(selectedCols?.join(" ") || "")
        .sort(sortObj)
        .skip(skip)
        .limit(lim)
        .lean(),
      Model.countDocuments(match),
    ]);

    if (exp === "csv" && selectedCols?.length) {
      const cols = selectedCols.map((k) => ({ key: k, label: k }));
      return sendCsv(res, `${entity}_custom_report.csv`, cols, data);
    }

    res.json({ data, total, page: p });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
