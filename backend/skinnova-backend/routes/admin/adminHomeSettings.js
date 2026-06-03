const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const HomeSettings = require("../../models/HomeSettings");

// Hero image upload setup
const heroUploadDir = path.join(__dirname, "../../uploads/hero");
if (!fs.existsSync(heroUploadDir)) fs.mkdirSync(heroUploadDir, { recursive: true });

const heroStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, heroUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `hero-${Date.now()}${ext}`);
  },
});
const uploadHeroImage = multer({ storage: heroStorage });

// POST upload hero image
router.post(
  "/upload-image",
  adminMiddleware,
  uploadHeroImage.single("image"),
  (req, res) => {
    if (!req.file) return res.status(400).json({ message: "No image uploaded" });
    const imageUrl = `${req.protocol}://${req.get("host")}/uploads/hero/${req.file.filename}`;
    res.json({ imageUrl });
  }
);

// GET home settings (singleton — always returns the first doc or creates one)
router.get("/", adminMiddleware, async (req, res) => {
  try {
    let settings = await HomeSettings.findOne();
    if (!settings) settings = await HomeSettings.create({});
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// Also expose publicly (no admin required) so the app can read hero settings
router.get("/public", async (req, res) => {
  try {
    let settings = await HomeSettings.findOne();
    if (!settings) settings = await HomeSettings.create({});
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update home settings
router.put("/", adminMiddleware, async (req, res) => {
  try {
    let settings = await HomeSettings.findOne();
    if (!settings) {
      settings = new HomeSettings(req.body);
    } else {
      Object.assign(settings, req.body);
    }
    await settings.save();
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
