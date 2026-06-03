const express = require("express");
const SupportTicket = require("../models/SupportTicket");
const UserSupportMessage = require("../models/UserSupportMessage");
const { sendPushToRole, sendPushNotification } = require("../helpers/sendPushNotification");

const router = express.Router();

// ── Seller support tickets ─────────────────────────────────────────────────

// POST /api/support/seller — submit a support ticket
router.post("/seller", async (req, res) => {
  try {
    const { sellerId, storeId, subject, message, category } = req.body;

    if (!sellerId || !subject || !message) {
      return res.status(400).json({
        message: "sellerId, subject, and message are required",
      });
    }

    const ticket = await SupportTicket.create({
      sellerId,
      storeId: storeId || null,
      subject,
      message,
      category: category || "other",
    });

    // Notify admins of new seller support ticket (fire without blocking)
    sendPushToRole({
      role: "admin",
      title: "New Seller Support Ticket 🎫",
      body: `Seller ticket: ${subject}`,
      type: "support_contact",
      data: { type: "support_contact", ticketId: ticket._id.toString() },
    }).catch(() => {});

    res.status(201).json({ message: "Support ticket submitted", ticket });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET /api/support/seller/:sellerId — get tickets for a seller
router.get("/seller/:sellerId", async (req, res) => {
  try {
    const tickets = await SupportTicket.find({ sellerId: req.params.sellerId })
      .sort({ createdAt: -1 });
    res.status(200).json(tickets);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── User contact / bug report ──────────────────────────────────────────────

// POST /api/support/contact
router.post("/contact", async (req, res) => {
  try {
    const { userId, userName, email, type, subject, message } = req.body;

    if (!type || !subject || !message) {
      return res.status(400).json({ message: "type, subject, and message are required" });
    }
    if (!["contact", "bug"].includes(type)) {
      return res.status(400).json({ message: "type must be 'contact' or 'bug'" });
    }

    const msg = await UserSupportMessage.create({
      userId: userId || null,
      userName: userName || "",
      email: email || "",
      type,
      subject: subject.trim(),
      message: message.trim(),
    });

    // Notify all admins (fire without blocking)
    const notifType = type === "bug" ? "support_bug" : "support_contact";
    const notifTitle = type === "bug" ? "New Bug Report 🐛" : "New Contact Message 💬";
    const notifBody = `${userName || "A user"}: ${subject.trim()}`;

    sendPushToRole({
      role: "admin",
      title: notifTitle,
      body: notifBody,
      type: notifType,
      data: { type: notifType, messageId: msg._id.toString() },
    }).catch(() => {});

    res.status(201).json({ message: "Message submitted successfully", id: msg._id });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Admin: manage user support messages ───────────────────────────────────

// GET /api/support/user-messages
router.get("/user-messages", async (req, res) => {
  try {
    const { type, status, page = 1, limit = 50 } = req.query;
    const query = {};
    if (type) query.type = type;
    if (status) query.status = status;

    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [messages, total] = await Promise.all([
      UserSupportMessage.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      UserSupportMessage.countDocuments(query),
    ]);

    res.status(200).json({ messages, total, page: parseInt(page) });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/support/user-messages/:id/status
router.put("/user-messages/:id/status", async (req, res) => {
  try {
    const { status, adminNote } = req.body;
    const allowed = ["open", "in_progress", "resolved", "dismissed"];
    if (!allowed.includes(status)) {
      return res.status(400).json({ message: "Invalid status value" });
    }

    const updates = { status };
    if (adminNote !== undefined) updates.adminNote = adminNote;

    const msg = await UserSupportMessage.findByIdAndUpdate(
      req.params.id,
      updates,
      { new: true }
    );
    if (!msg) return res.status(404).json({ message: "Message not found" });

    res.status(200).json(msg);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// DELETE /api/support/user-messages/:id
router.delete("/user-messages/:id", async (req, res) => {
  try {
    const msg = await UserSupportMessage.findByIdAndDelete(req.params.id);
    if (!msg) return res.status(404).json({ message: "Message not found" });
    res.status(200).json({ message: "Message deleted" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

module.exports = router;
