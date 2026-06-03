const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const Ad = require("../../models/ad");
const { sendPushNotification } = require("../../helpers/sendPushNotification");

// Image upload setup
const adUploadDir = path.join(__dirname, "../../uploads/ads");
if (!fs.existsSync(adUploadDir)) fs.mkdirSync(adUploadDir, { recursive: true });

const adStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, adUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `ad-${Date.now()}${ext}`);
  },
});
const uploadAdImage = multer({ storage: adStorage });

// POST upload ad image
router.post(
  "/upload-image",
  adminMiddleware,
  uploadAdImage.single("image"),
  (req, res) => {
    if (!req.file) return res.status(400).json({ message: "No image uploaded" });
    const imageUrl = `${req.protocol}://${req.get("host")}/uploads/ads/${req.file.filename}`;
    res.json({ imageUrl });
  }
);

// GET all ads
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { status, placement, page = 1, limit = 50 } = req.query;
    const query = {};
    if (status) query.status = status;
    if (placement) query.placement = placement;
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [ads, total] = await Promise.all([
      Ad.find(query)
        .populate("storeId", "storeName logoUrl")
        .populate("sellerId", "fullName email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Ad.countDocuments(query),
    ]);
    res.json({ ads, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single ad
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id)
      .populate("storeId", "storeName logoUrl")
      .populate("sellerId", "fullName email");
    if (!ad) return res.status(404).json({ message: "Ad not found" });
    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create ad (admin creates directly as approved)
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const ad = new Ad({ ...req.body, status: "approved" });
    await ad.save();
    res.status(201).json(ad);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update ad
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const ad = await Ad.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!ad) return res.status(404).json({ message: "Ad not found" });
    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH approve
router.patch("/:id/approve", adminMiddleware, async (req, res) => {
  try {
    const ad = await Ad.findByIdAndUpdate(
      req.params.id,
      { status: "approved", adminNote: "" },
      { new: true }
    );
    if (!ad) return res.status(404).json({ message: "Ad not found" });

    // Notify seller that their ad was approved
    if (ad.sellerId) {
      sendPushNotification({
        userId: ad.sellerId.toString(),
        title: "Ad Approved 🎉",
        body: `Your ad "${ad.title || "banner"}" has been approved and is now live.`,
        type: "ad_approved",
        data: { type: "ad_approved", adId: ad._id.toString() },
      }).catch(() => {});
    }

    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH reject
router.patch("/:id/reject", adminMiddleware, async (req, res) => {
  try {
    const { adminNote } = req.body;
    const ad = await Ad.findByIdAndUpdate(
      req.params.id,
      { status: "rejected", adminNote: adminNote || "Rejected by admin" },
      { new: true }
    );
    if (!ad) return res.status(404).json({ message: "Ad not found" });

    // Notify seller that their ad was rejected
    if (ad.sellerId) {
      sendPushNotification({
        userId: ad.sellerId.toString(),
        title: "Ad Rejected",
        body: `Your ad "${ad.title || "banner"}" was not approved. Reason: ${adminNote || "Did not meet requirements."}`,
        type: "ad_rejected",
        data: { type: "ad_rejected", adId: ad._id.toString() },
      }).catch(() => {});
    }

    res.json(ad);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle active
router.patch("/:id/toggle-active", adminMiddleware, async (req, res) => {
  try {
    const ad = await Ad.findById(req.params.id).select("isActive");
    if (!ad) return res.status(404).json({ message: "Ad not found" });
    ad.isActive = !ad.isActive;
    await ad.save();
    res.json({ isActive: ad.isActive });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE ad
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const ad = await Ad.findByIdAndDelete(req.params.id);
    if (!ad) return res.status(404).json({ message: "Ad not found" });
    res.json({ message: "Ad deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
