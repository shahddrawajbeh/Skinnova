const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const User = require("../../models/user");
const Store = require("../../models/store");

// GET all sellers
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { search, page = 1, limit = 50 } = req.query;
    const query = { role: "seller" };
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [sellers, total] = await Promise.all([
      User.find(query)
        .select("-password")
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      User.countDocuments(query),
    ]);

    // Attach store count for each seller
    const sellersWithStores = await Promise.all(
      sellers.map(async (seller) => {
        const storeCount = await Store.countDocuments({ sellerId: seller._id });
        return { ...seller.toObject(), storeCount };
      })
    );

    res.json({ sellers: sellersWithStores, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET stores for a seller
router.get("/:sellerId/stores", adminMiddleware, async (req, res) => {
  try {
    const stores = await Store.find({ sellerId: req.params.sellerId }).sort({ createdAt: -1 });
    res.json(stores);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT edit seller info
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const { fullName, email, isActive, city, bio } = req.body;
    const seller = await User.findOneAndUpdate(
      { _id: req.params.id, role: "seller" },
      { fullName, email, isActive, city, bio },
      { new: true, runValidators: true }
    ).select("-password");
    if (!seller) return res.status(404).json({ message: "Seller not found" });
    res.json(seller);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle active
router.patch("/:id/toggle-active", adminMiddleware, async (req, res) => {
  try {
    const seller = await User.findOne({ _id: req.params.id, role: "seller" }).select("isActive");
    if (!seller) return res.status(404).json({ message: "Seller not found" });
    seller.isActive = !seller.isActive;
    await seller.save();
    res.json({ isActive: seller.isActive });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH approve seller (set role to seller if was user)
router.patch("/:id/approve", adminMiddleware, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role: "seller", isActive: true },
      { new: true }
    ).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH reject/demote seller back to user
router.patch("/:id/reject", adminMiddleware, async (req, res) => {
  try {
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role: "user" },
      { new: true }
    ).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE seller
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const seller = await User.findOneAndDelete({ _id: req.params.id, role: "seller" });
    if (!seller) return res.status(404).json({ message: "Seller not found" });
    res.json({ message: "Seller deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
