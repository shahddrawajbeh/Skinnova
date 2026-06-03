const express = require("express");
const router = express.Router();
const mongoose = require("mongoose");
const ProductUsageReminder = require("../models/productUsageReminder");

// POST / — create a new reminder
router.post("/", async (req, res) => {
  try {
    const {
      userId,
      productId,
      productNameSnapshot,
      productImageSnapshot,
      brandSnapshot,
      directionsOfUseSnapshot,
      reminderTimes,
      frequencyType,
    } = req.body;

    if (!userId || !productNameSnapshot) {
      return res
        .status(400)
        .json({ message: "userId and productNameSnapshot are required" });
    }
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid userId" });
    }

    const validProductId =
      productId && mongoose.Types.ObjectId.isValid(productId)
        ? productId
        : null;

    // Prevent duplicate active reminders for the same product
    if (validProductId) {
      const existing = await ProductUsageReminder.findOne({
        userId,
        productId: validProductId,
        isActive: true,
      });
      if (existing) {
        return res.status(409).json({
          message: "Active reminder already exists for this product",
          reminderId: existing._id,
        });
      }
    }

    const reminder = await ProductUsageReminder.create({
      userId,
      productId: validProductId,
      productNameSnapshot,
      productImageSnapshot: productImageSnapshot || "",
      brandSnapshot: brandSnapshot || "",
      directionsOfUseSnapshot: directionsOfUseSnapshot || "",
      reminderTimes: reminderTimes || [],
      frequencyType: frequencyType || "daily",
    });

    res.status(201).json({ message: "Reminder created", reminder });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET /user/:userId — list all reminders for a user
router.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid userId" });
    }
    const reminders = await ProductUsageReminder.find({ userId })
      .sort({ createdAt: -1 })
      .lean();
    res.json({ reminders });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT /:reminderId — update reminder times / frequency / isActive
router.put("/:reminderId", async (req, res) => {
  try {
    const { reminderId } = req.params;
    const { userId, reminderTimes, frequencyType, isActive } = req.body;

    if (!mongoose.Types.ObjectId.isValid(reminderId)) {
      return res.status(400).json({ message: "Invalid reminderId" });
    }
    const reminder = await ProductUsageReminder.findById(reminderId);
    if (!reminder) {
      return res.status(404).json({ message: "Reminder not found" });
    }
    if (reminder.userId.toString() !== userId?.toString()) {
      return res.status(403).json({ message: "Not authorized" });
    }

    if (reminderTimes !== undefined) reminder.reminderTimes = reminderTimes;
    if (frequencyType !== undefined) reminder.frequencyType = frequencyType;
    if (isActive !== undefined) reminder.isActive = isActive;

    await reminder.save();
    res.json({ message: "Reminder updated", reminder });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH /:reminderId/toggle — flip isActive
router.patch("/:reminderId/toggle", async (req, res) => {
  try {
    const { reminderId } = req.params;
    const { userId } = req.body;

    if (!mongoose.Types.ObjectId.isValid(reminderId)) {
      return res.status(400).json({ message: "Invalid reminderId" });
    }
    const reminder = await ProductUsageReminder.findById(reminderId);
    if (!reminder) {
      return res.status(404).json({ message: "Reminder not found" });
    }
    if (reminder.userId.toString() !== userId?.toString()) {
      return res.status(403).json({ message: "Not authorized" });
    }

    reminder.isActive = !reminder.isActive;
    await reminder.save();
    res.json({ message: "Reminder toggled", isActive: reminder.isActive, reminder });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE /:reminderId — delete reminder
router.delete("/:reminderId", async (req, res) => {
  try {
    const { reminderId } = req.params;
    const { userId } = req.query;

    if (!mongoose.Types.ObjectId.isValid(reminderId)) {
      return res.status(400).json({ message: "Invalid reminderId" });
    }
    const reminder = await ProductUsageReminder.findById(reminderId);
    if (!reminder) {
      return res.status(404).json({ message: "Reminder not found" });
    }
    if (reminder.userId.toString() !== userId?.toString()) {
      return res.status(403).json({ message: "Not authorized" });
    }

    await ProductUsageReminder.findByIdAndDelete(reminderId);
    res.json({ message: "Reminder deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
