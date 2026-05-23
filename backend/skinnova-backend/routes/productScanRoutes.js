const express = require("express");
const multer = require("multer");
const Tesseract = require("tesseract.js");
const Product = require("../models/Product");
const path = require("path");
const ScanHistory = require("../models/ScanHistory");

const router = express.Router();

const upload = multer({
  dest: "uploads/product-scans/",
});
function normalizeText(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function scoreProduct(ocrText, product) {
  const text = normalizeText(ocrText);
  const brand = normalizeText(product.brand || "");
  const name = normalizeText(product.name || "");

  let score = 0;

  if (brand && text.includes(brand)) score += 50;

  const nameWords = name.split(" ").filter((w) => w.length >= 3);
  for (const word of nameWords) {
    if (text.includes(word)) score += 10;
  }

  return score;
}
router.post("/", upload.single("image"), async (req, res) => {
  try {
    const { userId } = req.body;

    if (!req.file) {
      return res.status(400).json({
        matched: false,
        message: "No image uploaded",
      });
    }

    if (!userId) {
      return res.status(400).json({
        matched: false,
        message: "Missing userId",
      });
    }

    const imageUrl = `/uploads/product-scans/${req.file.filename}`;

    const result = await Tesseract.recognize(req.file.path, "eng");
    const ocrText = result.data.text || "";

    const products = await Product.find({ isPublished: true });

    let bestProduct = null;
    let bestScore = 0;

    for (const product of products) {
      const score = scoreProduct(ocrText, product);

      if (score > bestScore) {
        bestScore = score;
        bestProduct = product;
      }
    }

    const isMatched = bestProduct && bestScore >= 40;

    if (!isMatched) {
  return res.status(404).json({
    matched: false,
    message:
      "This product is not in our database yet. Try a clearer front photo.",
    ocrText,
    bestScore,
  });
}

await ScanHistory.create({
  userId,
  imageUrl,
  ocrText,
  matched: true,
  productId: bestProduct._id,
  productName: bestProduct.name,
  productBrand: bestProduct.brand,
  confidence: bestScore,
});
    return res.status(200).json({
      matched: true,
      product: bestProduct,
      confidence: bestScore,
      ocrText,
    });
  } catch (error) {
    console.error("Product scan error:", error);
    return res.status(500).json({
      matched: false,
      message: "Scan failed",
    });
  }
});
router.get("/history/:userId", async (req, res) => {
  try {
    const history = await ScanHistory.find({
  userId: req.params.userId,
  matched: true,
})
      .populate("productId")
      .sort({ createdAt: -1 });

    return res.status(200).json(history);
  } catch (error) {
    console.error("Fetch scan history error:", error);
    return res.status(500).json({
      message: "Failed to fetch scan history",
    });
  }
});
router.delete("/history/:scanId", async (req, res) => {
  try {
    const deletedScan = await ScanHistory.findByIdAndDelete(req.params.scanId);

    if (!deletedScan) {
      return res.status(404).json({
        message: "Scan not found",
      });
    }

    return res.status(200).json({
      message: "Scan deleted successfully",
    });
  } catch (error) {
    console.error("Delete scan error:", error);
    return res.status(500).json({
      message: "Failed to delete scan",
    });
  }
});
module.exports = router;