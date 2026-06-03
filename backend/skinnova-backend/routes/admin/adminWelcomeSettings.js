const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const WelcomeSettings = require("../../models/WelcomeSettings");

// ── Media upload (images + videos) ───────────────────────────────────────────
const welcomeUploadDir = path.join(__dirname, "../../uploads/welcome");
if (!fs.existsSync(welcomeUploadDir)) {
  fs.mkdirSync(welcomeUploadDir, { recursive: true });
}

const welcomeStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, welcomeUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `welcome-${Date.now()}${ext}`);
  },
});

const uploadWelcomeMedia = multer({
  storage: welcomeStorage,
  limits: { fileSize: 100 * 1024 * 1024 }, // 100 MB max (for videos)
  fileFilter: (req, file, cb) => {
    const allowed = [".jpg", ".jpeg", ".png", ".webp", ".mp4", ".mov", ".webm"];
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, allowed.includes(ext));
  },
});

// ── Helper: get or create the singleton settings doc ─────────────────────────
async function getOrCreateSettings() {
  let settings = await WelcomeSettings.findOne();
  if (!settings) settings = await WelcomeSettings.create({});
  return settings;
}

// ── Public endpoint — used by the Flutter WelcomeScreen ──────────────────────
router.get("/public", async (req, res) => {
  try {
    const settings = await getOrCreateSettings();
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── Admin: get settings ───────────────────────────────────────────────────────
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const settings = await getOrCreateSettings();
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── Admin: update settings ────────────────────────────────────────────────────
router.put("/", adminMiddleware, async (req, res) => {
  try {
    const { title, subtitle, buttonText, mediaType, mediaUrl, isActive } = req.body;
    let settings = await WelcomeSettings.findOne();
    if (!settings) {
      settings = new WelcomeSettings({ title, subtitle, buttonText, mediaType, mediaUrl, isActive });
    } else {
      if (title !== undefined) settings.title = title;
      if (subtitle !== undefined) settings.subtitle = subtitle;
      if (buttonText !== undefined) settings.buttonText = buttonText;
      if (mediaType !== undefined) settings.mediaType = mediaType;
      if (mediaUrl !== undefined) settings.mediaUrl = mediaUrl;
      if (isActive !== undefined) settings.isActive = isActive;
    }
    await settings.save();
    res.json(settings);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── Admin: upload media (image or video) ──────────────────────────────────────
router.post(
  "/upload-media",
  adminMiddleware,
  uploadWelcomeMedia.single("media"),
  (req, res) => {
    if (!req.file) return res.status(400).json({ message: "No file uploaded" });
    const mediaUrl = `${req.protocol}://${req.get("host")}/uploads/welcome/${req.file.filename}`;
    const ext = path.extname(req.file.originalname).toLowerCase();
    const mediaType = [".mp4", ".mov", ".webm"].includes(ext) ? "video" : "image";
    res.json({ mediaUrl, mediaType });
  }
);

module.exports = router;
