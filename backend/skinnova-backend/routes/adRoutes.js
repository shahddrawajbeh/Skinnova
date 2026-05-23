const express = require("express");
const router = express.Router();
const Ad = require("../models/ad");

// Store owner creates ad request
router.post("/", async (req, res) => {
  try {
    const {
  storeId,
  sellerId,
  title,
  subtitle,
  imageUrl,
  buttonText,
  startDate,
  endDate,
} = req.body;

const ad = new Ad({
  storeId,
  sellerId,
  title,
  subtitle,
  imageUrl,
  buttonText,
  startDate,
  endDate,
  status: "pending",
});
    await ad.save();

    res.status(201).json({
      message: "Ad submitted and waiting for admin approval",
      ad,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to create ad",
      error: error.message,
    });
  }
});

// User gets only approved ads for slider
router.get("/approved", async (req, res) => {
  try {
    const ads = await Ad.find({
      status: "approved",
      isActive: true,
    })
      .populate("storeId")
      .sort({ createdAt: -1 });

    res.json(ads);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch approved ads",
      error: error.message,
    });
  }
});

// Admin gets pending ads
router.get("/pending", async (req, res) => {
  try {
    const ads = await Ad.find({ status: "pending" })
      .populate("storeId")
      .sort({ createdAt: -1 });

    res.json(ads);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch pending ads",
      error: error.message,
    });
  }
});

// Admin approves ad
router.get("/approved", async (req, res) => {
  try {
    const now = new Date();

    const ads = await Ad.find({
      status: "approved",
      isActive: true,
      startDate: { $lte: now },
      $or: [
        { endDate: { $gte: now } },
        { endDate: null }
      ],
    })
      .populate("storeId")
      .sort({ createdAt: -1 });

    res.json(ads);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch approved ads",
      error: error.message,
    });
  }
});
router.get("/seller/:sellerId", async (req, res) => {
  try {
    const ads = await Ad.find({ sellerId: req.params.sellerId })
      .populate("storeId")
      .sort({ createdAt: -1 });

    res.status(200).json(ads);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// Admin rejects ad
router.put("/:id/reject", async (req, res) => {
  try {
    const { adminNote } = req.body;

    const ad = await Ad.findByIdAndUpdate(
      req.params.id,
      {
        status: "rejected",
        adminNote: adminNote || "Rejected by admin",
      },
      { new: true }
    );

    if (!ad) {
      return res.status(404).json({ message: "Ad not found" });
    }

    res.json({
      message: "Ad rejected",
      ad,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to reject ad",
      error: error.message,
    });
  }
});

module.exports = router;