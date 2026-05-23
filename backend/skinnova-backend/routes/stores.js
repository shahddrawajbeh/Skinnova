const express = require("express");
const Store = require("../models/store");

const router = express.Router();

// GET all stores
router.get("/", async (req, res) => {
  try {
    const stores = await Store.find()
      .populate("sellerId", "fullName email")
      .sort({ createdAt: -1 });

    res.status(200).json(stores);
  } catch (error) {
    console.log("❌ GET STORES ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.get("/seller/:sellerId", async (req, res) => {
  try {
    const store = await Store.findOne({
      sellerId: req.params.sellerId,
    });

    if (!store) {
      return res.status(404).json({
        message: "No store found for this seller",
      });
    }

    res.status(200).json(store);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// GET single store by id
router.get("/:id", async (req, res) => {
  try {
    const store = await Store.findById(req.params.id).populate(
      "sellerId",
      "fullName email"
    );

    if (!store) {
      return res.status(404).json({ message: "Store not found" });
    }

    res.status(200).json(store);
  } catch (error) {
    console.log("❌ GET STORE DETAILS ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// CREATE new store
router.post("/", async (req, res) => {
  try {
    const {
      sellerId,
      storeName,
      logoUrl,
      coverImageUrl,
      description,
      city,
      address,
      phone,
    } = req.body;

    if (!sellerId || !storeName || !city) {
      return res.status(400).json({
        message: "sellerId, storeName, and city are required",
      });
    }

    const store = await Store.create({
      sellerId,
      storeName,
      logoUrl,
      coverImageUrl,
      description,
      city,
      address,
      phone,
    });

    res.status(201).json(store);
  } catch (error) {
    console.log("❌ CREATE STORE ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// UPDATE store
router.put("/:id", async (req, res) => {
  try {
    const updatedStore = await Store.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    if (!updatedStore) {
      return res.status(404).json({ message: "Store not found" });
    }

    res.status(200).json(updatedStore);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

module.exports = router;