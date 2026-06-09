const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const Store = require("../../models/store");
const User = require("../../models/user");
const Notification = require("../../models/notification");
const { sendNotification } = require("../../services/notificationService");

// Image upload setup
const storeUploadDir = path.join(__dirname, "../../uploads/stores");
if (!fs.existsSync(storeUploadDir)) fs.mkdirSync(storeUploadDir, { recursive: true });

const storeStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, storeUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `store-${Date.now()}${ext}`);
  },
});
const uploadStoreImage = multer({ storage: storeStorage });

// POST upload store image
router.post("/upload-image", adminMiddleware, uploadStoreImage.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "No image uploaded" });
  const imageUrl = `${req.protocol}://${req.get("host")}/uploads/stores/${req.file.filename}`;
  res.json({ imageUrl });
});

// GET all stores with filters
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { search, isActive, approvalStatus, page = 1, limit = 50 } = req.query;
    const query = {};
    if (isActive !== undefined) query.isActive = isActive === "true";
    if (approvalStatus) query.approvalStatus = approvalStatus;
    if (search) {
      query.$or = [
        { storeName: { $regex: search, $options: "i" } },
        { city: { $regex: search, $options: "i" } },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [stores, total] = await Promise.all([
      Store.find(query)
        .populate("sellerId", "fullName email")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Store.countDocuments(query),
    ]);
    res.json({ stores, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET stores pending approval
router.get("/pending-approval", adminMiddleware, async (req, res) => {
  try {
    const stores = await Store.find({ approvalStatus: "pending" })
      .populate("sellerId", "fullName email")
      .sort({ createdAt: -1 });
    res.json(stores);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single store
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const store = await Store.findById(req.params.id).populate("sellerId", "fullName email");
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create store
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const { sellerId, storeName, city, description, phone, address, logoUrl, coverImageUrl } = req.body;
    const store = new Store({
      sellerId,
      storeName,
      city,
      description,
      phone,
      address,
      logoUrl,
      coverImageUrl,
      approvalStatus: "approved",
    });
    await store.save();
    res.status(201).json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update store
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const updates = req.body;
    const store = await Store.findByIdAndUpdate(req.params.id, updates, {
      new: true,
      runValidators: true,
    }).populate("sellerId", "fullName email");
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle active
router.patch("/:id/toggle-active", adminMiddleware, async (req, res) => {
  try {
    const store = await Store.findById(req.params.id).select("isActive");
    if (!store) return res.status(404).json({ message: "Store not found" });
    store.isActive = !store.isActive;
    await store.save();
    res.json({ isActive: store.isActive });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH approve store — also promotes user to "seller" and sends notification
router.patch("/:id/approve", adminMiddleware, async (req, res) => {
  try {
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      {
        approvalStatus: "approved",
        verificationStatus: "verified",
        isActive: true,
        rejectionReason: "",
        reviewedAt: new Date(),
        reviewedBy: req.adminId,
      },
      { new: true }
    ).populate("sellerId", "fullName email _id");

    if (!store) return res.status(404).json({ message: "Store not found" });

    // Promote user to seller role
    await User.findByIdAndUpdate(store.sellerId._id, { role: "seller" });

    // Notify store owner via in-app, push, and email
    await sendNotification({
      userId: store.sellerId._id.toString(),
      title: "Store Request Approved 🎉",
      body: `Congratulations! Your store "${store.storeName}" has been approved. You can now start selling.`,
      type: "store_approved",
      storeId: store._id.toString(),
      data: { type: "store_approved", storeId: store._id.toString() },
    });

    res.json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH reject store — saves reason, sends notification, keeps user role as "user"
router.patch("/:id/reject", adminMiddleware, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      {
        approvalStatus: "rejected",
        verificationStatus: "rejected",
        isActive: false,
        rejectionReason: rejectionReason || "Your store request did not meet our requirements.",
        reviewedAt: new Date(),
        reviewedBy: req.adminId,
      },
      { new: true }
    ).populate("sellerId", "fullName email _id");

    if (!store) return res.status(404).json({ message: "Store not found" });

    // Ensure user stays as "user" role (don't promote)
    await User.findByIdAndUpdate(store.sellerId._id, { role: "user" });

    // Notify store owner via in-app, push, and email
    await sendNotification({
      userId: store.sellerId._id.toString(),
      title: "Store Request Rejected",
      body: `Your store "${store.storeName}" was not approved. Reason: ${rejectionReason || "Did not meet requirements."}`,
      type: "store_rejected",
      storeId: store._id.toString(),
      data: { type: "store_rejected", storeId: store._id.toString() },
    });

    res.json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH set store badge/verification level
router.patch("/:id/badge", adminMiddleware, async (req, res) => {
  try {
    const { verificationLevel, isVerified } = req.body;
    const updates = {};
    if (verificationLevel !== undefined) updates.verificationLevel = verificationLevel;
    if (isVerified !== undefined) {
      updates.isVerified = isVerified;
      updates.verifiedAt = isVerified ? new Date() : null;
      updates.verifiedBy = isVerified ? req.adminId : null;
    }
    const store = await Store.findByIdAndUpdate(req.params.id, updates, { new: true });
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE store
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const store = await Store.findByIdAndDelete(req.params.id);
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.json({ message: "Store deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
