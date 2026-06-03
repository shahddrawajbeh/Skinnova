const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const Notification = require("../../models/notification");
const User = require("../../models/user");
const { sendPushNotification } = require("../../helpers/sendPushNotification");

// GET all notifications sent by admin
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { page = 1, limit = 50 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [notifications, total] = await Promise.all([
      Notification.find({ sentByAdmin: true })
        .populate("userId", "fullName email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Notification.countDocuments({ sentByAdmin: true }),
    ]);
    res.json({ notifications, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST send notification to all users (in-app + FCM push)
router.post("/all-users", adminMiddleware, async (req, res) => {
  try {
    const { title, body, type, imageUrl, targetLink } = req.body;
    const resolvedType = type || "promo";
    const users = await User.find({}).select("_id");

    // Save in-app notifications in bulk
    const notifications = users.map((u) => ({
      userId: u._id,
      title,
      body,
      type: resolvedType,
      imageUrl: imageUrl || "",
      targetLink: targetLink || "",
      sentByAdmin: true,
    }));
    await Notification.insertMany(notifications);

    // Send FCM push to each user (saveInApp false — already saved above)
    const pushPromises = users.map((u) =>
      sendPushNotification({
        userId: u._id.toString(),
        title,
        body,
        type: resolvedType,
        imageUrl,
        targetLink,
        saveInApp: false,
        data: { type: resolvedType, targetLink: targetLink || "" },
      })
    );
    Promise.allSettled(pushPromises).catch(() => {});

    res.json({ message: `Notification sent to ${users.length} users` });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST send notification to a specific user (in-app + FCM push)
router.post("/user/:userId", adminMiddleware, async (req, res) => {
  try {
    const { title, body, type, imageUrl, targetLink } = req.body;
    const resolvedType = type || "admin";
    const notif = await Notification.create({
      userId: req.params.userId,
      title,
      body,
      type: resolvedType,
      imageUrl: imageUrl || "",
      targetLink: targetLink || "",
      sentByAdmin: true,
    });

    sendPushNotification({
      userId: req.params.userId,
      title,
      body,
      type: resolvedType,
      imageUrl,
      targetLink,
      saveInApp: false,
      data: { type: resolvedType, targetLink: targetLink || "" },
    }).catch(() => {});

    res.status(201).json(notif);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST send notification to followers of a store (in-app + FCM push)
router.post("/store-followers/:storeId", adminMiddleware, async (req, res) => {
  try {
    const { title, body, type, imageUrl, targetLink } = req.body;
    const resolvedType = type || "store";
    const users = await User.find({
      followedStores: req.params.storeId,
    }).select("_id");

    const notifications = users.map((u) => ({
      userId: u._id,
      title,
      body,
      type: resolvedType,
      imageUrl: imageUrl || "",
      targetLink: targetLink || "",
      sentByAdmin: true,
    }));
    await Notification.insertMany(notifications);

    const pushPromises = users.map((u) =>
      sendPushNotification({
        userId: u._id.toString(),
        title,
        body,
        type: resolvedType,
        imageUrl,
        targetLink,
        storeId: req.params.storeId,
        saveInApp: false,
        data: { type: resolvedType, storeId: req.params.storeId, targetLink: targetLink || "" },
      })
    );
    Promise.allSettled(pushPromises).catch(() => {});

    res.json({ message: `Notification sent to ${users.length} store followers` });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST send notification to users by skin concern
router.post("/skin-concern", adminMiddleware, async (req, res) => {
  try {
    const { title, body, type, imageUrl, targetLink, concern } = req.body;
    const resolvedType = type || "promo";
    const users = await User.find({
      "onboarding.skinConcerns": concern,
    }).select("_id");

    const notifications = users.map((u) => ({
      userId: u._id,
      title,
      body,
      type: resolvedType,
      imageUrl: imageUrl || "",
      targetLink: targetLink || "",
      sentByAdmin: true,
    }));
    await Notification.insertMany(notifications);

    const pushPromises = users.map((u) =>
      sendPushNotification({
        userId: u._id.toString(),
        title,
        body,
        type: resolvedType,
        imageUrl,
        targetLink,
        saveInApp: false,
        data: { type: resolvedType, targetLink: targetLink || "" },
      })
    );
    Promise.allSettled(pushPromises).catch(() => {});

    res.json({ message: `Notification sent to ${users.length} users with concern: ${concern}` });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
