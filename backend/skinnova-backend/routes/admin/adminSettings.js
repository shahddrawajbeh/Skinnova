const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const AppSettings = require("../../models/AppSettings");
const { invalidateSettingsCache } = require("../../helpers/getAppSettings");

// GET settings (public so app can read maintenance mode etc.)
router.get("/public", async (req, res) => {
  try {
    let settings = await AppSettings.findOne();
    if (!settings) settings = await AppSettings.create({});
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET settings (admin)
router.get("/", adminMiddleware, async (req, res) => {
  try {
    let settings = await AppSettings.findOne();
    if (!settings) settings = await AppSettings.create({});
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update settings
router.put("/", adminMiddleware, async (req, res) => {
  try {
    let settings = await AppSettings.findOne();
    if (!settings) {
      settings = new AppSettings(req.body);
    } else {
      Object.assign(settings, req.body);
    }
    await settings.save();
    invalidateSettingsCache(); // flush 30-s cache so changes take effect immediately
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
