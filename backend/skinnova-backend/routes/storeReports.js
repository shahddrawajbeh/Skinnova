const express = require("express");
const StoreReport = require("../models/storeReport");
const Store = require("../models/store");
const User = require("../models/user");
const { sendNotificationToRole } = require("../services/notificationService");

const router = express.Router();

// POST /api/store-reports — user submits a report (goes to admin only)
router.post("/", async (req, res) => {
  try {
    const { storeId, userId, reason, details } = req.body;

    if (!storeId || !userId || !reason) {
      return res.status(400).json({ message: "storeId, userId, and reason are required" });
    }

    // Prevent duplicate pending report from same user on same store
    const existing = await StoreReport.findOne({ storeId, userId, status: "pending" });
    if (existing) {
      return res.status(409).json({
        message: "You have already reported this store. It is under review.",
      });
    }

    // Resolve reporter name server-side
    const userDoc = await User.findById(userId).select("fullName");
    const resolvedName = userDoc?.fullName?.trim() || "Customer";

    // Resolve store info (storeName + sellerId) — seller never sees this report
    const storeDoc = await Store.findById(storeId).select("storeName sellerId");
    const resolvedStoreName = storeDoc?.storeName || "";
    const resolvedSellerId = storeDoc?.sellerId || null;

    const report = await StoreReport.create({
      storeId,
      storeName: resolvedStoreName,
      sellerId: resolvedSellerId,
      userId,
      userName: resolvedName,
      reason,
      details: details || "",
    });

    // Notify all admins via in-app, push, and email
    sendNotificationToRole({
      role: "admin",
      title: "New Store Report 🚩",
      body: `${resolvedName} reported "${resolvedStoreName || "a store"}": ${reason}`,
      type: "store_report",
      data: { type: "store_report", reportId: report._id.toString(), storeId },
    }).catch(() => {});

    res.status(201).json({ message: "Report submitted successfully", report });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET /api/store-reports/pending — admin: pending reports only
router.get("/pending", async (req, res) => {
  try {
    const reports = await StoreReport.find({ status: "pending" })
      .sort({ createdAt: -1 });
    res.status(200).json(reports);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET /api/store-reports — admin: all reports with optional status filter
router.get("/", async (req, res) => {
  try {
    const filter = {};
    if (req.query.status) filter.status = req.query.status;

    const reports = await StoreReport.find(filter)
      .sort({ createdAt: -1 });

    res.status(200).json(reports);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/store-reports/:reportId/reviewed — admin marks as reviewed
router.put("/:reportId/reviewed", async (req, res) => {
  try {
    const { adminNote } = req.body;
    const update = { status: "reviewed" };
    if (adminNote !== undefined) update.adminNote = adminNote;

    const report = await StoreReport.findByIdAndUpdate(
      req.params.reportId,
      update,
      { new: true }
    );
    if (!report) return res.status(404).json({ message: "Report not found" });
    res.status(200).json({ message: "Report marked as reviewed", report });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/store-reports/:reportId/dismissed — admin dismisses report
router.put("/:reportId/dismissed", async (req, res) => {
  try {
    const { adminNote } = req.body;
    const update = { status: "dismissed" };
    if (adminNote !== undefined) update.adminNote = adminNote;

    const report = await StoreReport.findByIdAndUpdate(
      req.params.reportId,
      update,
      { new: true }
    );
    if (!report) return res.status(404).json({ message: "Report not found" });
    res.status(200).json({ message: "Report dismissed", report });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

module.exports = router;
