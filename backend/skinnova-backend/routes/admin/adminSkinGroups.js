const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const SkinConcernGroup = require("../../models/SkinConcernGroup");

// Image upload setup
const groupUploadDir = path.join(__dirname, "../../uploads/skin-groups");
if (!fs.existsSync(groupUploadDir)) fs.mkdirSync(groupUploadDir, { recursive: true });

const groupStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, groupUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `group-${Date.now()}${ext}`);
  },
});
const uploadGroupImage = multer({ storage: groupStorage });

// POST upload group image
router.post(
  "/upload-image",
  adminMiddleware,
  uploadGroupImage.single("image"),
  (req, res) => {
    if (!req.file) return res.status(400).json({ message: "No image uploaded" });
    const imageUrl = `${req.protocol}://${req.get("host")}/uploads/skin-groups/${req.file.filename}`;
    res.json({ imageUrl });
  }
);

// GET all skin groups (also public for app use)
router.get("/public", async (req, res) => {
  try {
    const groups = await SkinConcernGroup.find({ isActive: true })
      .sort({ displayOrder: 1 })
      .populate("products", "name imageUrl brand");
    res.json(groups);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET all (admin, includes inactive)
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const groups = await SkinConcernGroup.find()
      .sort({ displayOrder: 1 })
      .populate("products", "name imageUrl brand");
    res.json(groups);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single group
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const group = await SkinConcernGroup.findById(req.params.id).populate(
      "products",
      "name imageUrl brand"
    );
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create group
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const group = new SkinConcernGroup(req.body);
    await group.save();
    res.status(201).json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update group
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const group = await SkinConcernGroup.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    }).populate("products", "name imageUrl brand");
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle active
router.patch("/:id/toggle-active", adminMiddleware, async (req, res) => {
  try {
    const group = await SkinConcernGroup.findById(req.params.id).select("isActive");
    if (!group) return res.status(404).json({ message: "Group not found" });
    group.isActive = !group.isActive;
    await group.save();
    res.json({ isActive: group.isActive });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH add product to group
router.patch("/:id/add-product", adminMiddleware, async (req, res) => {
  try {
    const { productId } = req.body;
    const group = await SkinConcernGroup.findByIdAndUpdate(
      req.params.id,
      { $addToSet: { products: productId } },
      { new: true }
    ).populate("products", "name imageUrl brand");
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH remove product from group
router.patch("/:id/remove-product", adminMiddleware, async (req, res) => {
  try {
    const { productId } = req.body;
    const group = await SkinConcernGroup.findByIdAndUpdate(
      req.params.id,
      { $pull: { products: productId } },
      { new: true }
    ).populate("products", "name imageUrl brand");
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH reorder groups
router.patch("/reorder", adminMiddleware, async (req, res) => {
  try {
    const { orders } = req.body; // [{ id, displayOrder }]
    await Promise.all(
      orders.map(({ id, displayOrder }) =>
        SkinConcernGroup.findByIdAndUpdate(id, { displayOrder })
      )
    );
    res.json({ message: "Reordered successfully" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE group
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const group = await SkinConcernGroup.findByIdAndDelete(req.params.id);
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json({ message: "Group deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
