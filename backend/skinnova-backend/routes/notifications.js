const express = require("express");
const Notification = require("../models/notification");
const User = require("../models/user");
const { sendPushNotification, sendPushToRole } = require("../helpers/sendPushNotification");
const { sendEmail, notificationEmailHtml } = require("../helpers/sendEmail");

const router = express.Router();

// ── Test routes ────────────────────────────────────────────────────────────────

// GET /api/notifications/test-push/:userId
router.get("/test-push/:userId", async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select("fcmTokens fullName");
    if (!user) return res.status(404).json({ message: "User not found" });

    console.log(`[test-push] userId=${req.params.userId} name=${user.fullName} tokens=${user.fcmTokens.length}`);

    await sendPushNotification({
      userId: req.params.userId,
      title: "Skinova Test 🔔",
      body: "Push notification is working!",
      type: "general",
      saveInApp: true,
    });

    res.json({ message: "Test push sent", tokensCount: user.fcmTokens.length });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// GET /api/notifications/test-role/:role
router.get("/test-role/:role", async (req, res) => {
  try {
    const { role } = req.params;
    const users = await User.find({ role }).select("_id fullName fcmTokens");
    const tokensCount = users.reduce((sum, u) => sum + (u.fcmTokens || []).length, 0);

    console.log(`[test-role] role=${role} users=${users.length} tokens=${tokensCount}`);

    await sendPushToRole({
      role,
      title: `Skinova Test (${role}) 🔔`,
      body: `Test notification for role: ${role}`,
      type: "general",
    });

    res.json({ message: `Test push sent to role: ${role}`, usersCount: users.length, tokensCount });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
});

// ── Notification settings ──────────────────────────────────────────────────

// GET /api/notifications/settings/:userId
router.get("/settings/:userId", async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select("notificationSettings");
    if (!user) return res.status(404).json({ message: "User not found" });

    const settings = user.notificationSettings || {};
    res.status(200).json({
      inApp: settings.inApp !== false,
      push: settings.push !== false,
      email: settings.email !== false,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/notifications/settings/:userId
router.put("/settings/:userId", async (req, res) => {
  try {
    const { inApp, push, email } = req.body;

    const updates = {};
    if (inApp !== undefined) updates["notificationSettings.inApp"] = Boolean(inApp);
    if (push !== undefined) updates["notificationSettings.push"] = Boolean(push);
    if (email !== undefined) updates["notificationSettings.email"] = Boolean(email);

    const user = await User.findByIdAndUpdate(
      req.params.userId,
      { $set: updates },
      { new: true }
    ).select("notificationSettings");

    if (!user) return res.status(404).json({ message: "User not found" });

    const s = user.notificationSettings || {};
    res.status(200).json({
      message: "Notification settings updated",
      settings: {
        inApp: s.inApp !== false,
        push: s.push !== false,
        email: s.email !== false,
      },
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// POST /api/notifications/test-email — development only
router.post("/test-email", async (req, res) => {
  if (process.env.NODE_ENV === "production") {
    return res.status(403).json({ message: "Not available in production" });
  }
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "email is required" });

    await sendEmail({
      to: email,
      subject: "Skinova Test Email ✦",
      html: notificationEmailHtml({
        title: "Test Notification ✅",
        body: "This is a test email from Skinova. If you received this, your Gmail SMTP is working correctly.",
        data: {},
      }),
    });

    res.status(200).json({ message: `Test email sent to ${email}` });
  } catch (error) {
    res.status(500).json({ message: "Email send failed", error: error.message });
  }
});

// ── User notification endpoints ─────────────────────────────────────────────

// GET /api/notifications/:userId/unread-count
router.get("/:userId/unread-count", async (req, res) => {
  try {
    const count = await Notification.countDocuments({
      userId: req.params.userId,
      isRead: false,
    });
    res.status(200).json({ count });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET /api/notifications/:userId
router.get("/:userId", async (req, res) => {
  try {
    const notifications = await Notification.find({ userId: req.params.userId })
      .sort({ createdAt: -1 })
      .limit(50);
    res.status(200).json(notifications);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/notifications/:userId/mark-all-read
router.put("/:userId/mark-all-read", async (req, res) => {
  try {
    await Notification.updateMany(
      { userId: req.params.userId, isRead: false },
      { isRead: true }
    );
    res.status(200).json({ message: "All notifications marked as read" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/notifications/:notificationId/read
router.put("/:notificationId/read", async (req, res) => {
  try {
    const notification = await Notification.findByIdAndUpdate(
      req.params.notificationId,
      { isRead: true },
      { new: true }
    );
    if (!notification) return res.status(404).json({ message: "Not found" });
    res.status(200).json(notification);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── FCM Token Management ───────────────────────────────────────────────────────
router.post("/save-fcm-token", async (req, res) => {
  try {
    const { userId, fcmToken } = req.body;

    if (!userId || !fcmToken) {
      return res.status(400).json({ message: "userId and fcmToken are required" });
    }

    const cleanToken = fcmToken.trim();

    // احذف نفس التوكن من أي حساب ثاني
    await User.updateMany(
      { _id: { $ne: userId } },
      { $pull: { fcmTokens: cleanToken } }
    );

    // خزنه للحساب الحالي فقط
    await User.findByIdAndUpdate(userId, {
      $addToSet: { fcmTokens: cleanToken },
    });

    res.status(200).json({ message: "FCM token saved" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});
// POST /api/notifications/save-fcm-token
// router.post("/save-fcm-token", async (req, res) => {
//   try {
//     const { userId, fcmToken } = req.body;
//     if (!userId || !fcmToken) {
//       return res.status(400).json({ message: "userId and fcmToken are required" });
//     }
//     await User.findByIdAndUpdate(userId, {
//       $addToSet: { fcmTokens: fcmToken.trim() },
//     });
//     res.status(200).json({ message: "FCM token saved" });
//   } catch (err) {
//     res.status(500).json({ message: "Server error", error: err.message });
//   }
// });

// DELETE /api/notifications/remove-fcm-token
router.delete("/remove-fcm-token", async (req, res) => {
  try {
    const { userId, fcmToken } = req.body;
    if (!userId || !fcmToken) {
      return res.status(400).json({ message: "userId and fcmToken are required" });
    }
    await User.findByIdAndUpdate(userId, {
      $pull: { fcmTokens: fcmToken.trim() },
    });
    res.status(200).json({ message: "FCM token removed" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
