const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const Product = require("../../models/product");

// Image upload setup
const productUploadDir = path.join(__dirname, "../../uploads/products");
if (!fs.existsSync(productUploadDir)) fs.mkdirSync(productUploadDir, { recursive: true });

const productStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, productUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `product-${Date.now()}${ext}`);
  },
});
const uploadProductImage = multer({ storage: productStorage });

// POST upload product image
router.post(
  "/upload-image",
  adminMiddleware,
  uploadProductImage.single("image"),
  (req, res) => {
    if (!req.file) return res.status(400).json({ message: "No image uploaded" });
    const imageUrl = `${req.protocol}://${req.get("host")}/uploads/products/${req.file.filename}`;
    res.json({ imageUrl });
  }
);

// GET all products with search + filter
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { search, category, brand, isHidden, page = 1, limit = 50 } = req.query;
    const query = {};
    if (category) query.category = category;
    if (brand) query.brand = { $regex: brand, $options: "i" };
    if (isHidden !== undefined) query.isHidden = isHidden === "true";
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: "i" } },
        { brand: { $regex: search, $options: "i" } },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [products, total] = await Promise.all([
      Product.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      Product.countDocuments(query),
    ]);
    res.json({ products, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single product
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findById(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    res.json(product);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create product
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const product = new Product(req.body);
    await product.save();
    res.status(201).json(product);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update product
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findByIdAndUpdate(req.params.id, req.body, {
      new: true,
      runValidators: true,
    });
    if (!product) return res.status(404).json({ message: "Product not found" });
    res.json(product);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle hidden
router.patch("/:id/toggle-hidden", adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findById(req.params.id).select("isHidden");
    if (!product) return res.status(404).json({ message: "Product not found" });
    product.isHidden = !product.isHidden;
    await product.save();
    res.json({ isHidden: product.isHidden });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE product
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const product = await Product.findByIdAndDelete(req.params.id);
    if (!product) return res.status(404).json({ message: "Product not found" });
    res.json({ message: "Product deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
