const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const User = require("../../models/user");
const Store = require("../../models/store");

// GET all users with optional search
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { search, role, page = 1, limit = 50 } = req.query;
    const query = {};
    if (role) query.role = role;
    if (search) {
      query.$or = [
        { fullName: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ];
    }
   const skip = (parseInt(page) - 1) * parseInt(limit);

const [usersRaw, total] = await Promise.all([
  User.find(query)
    .select("-password")
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(parseInt(limit))
    .lean(),
  User.countDocuments(query),
]);

const users = await Promise.all(
  usersRaw.map(async (user) => {
    if (user.role === "saller") {
      const store = await Store.findOne({ sellerId: user._id }).lean();

      return {
        ...user,
        storeLogo: store?.logoUrl || "",
        storeName: store?.storeName || "",
      };
    }

    return user;
  })
);

res.json({ users, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single user
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create user
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const { fullName, email, password, role } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: "Email already in use" });
    const hashed = await bcrypt.hash(password, 10);
    const user = new User({ fullName, email, password: hashed, role: role || "user" });
    await user.save();
    const saved = user.toObject();
    delete saved.password;
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update user
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const { fullName, email, role, isActive, city, bio } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { fullName, email, role, isActive, city, bio },
      { new: true, runValidators: true }
    ).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle active
router.patch("/:id/toggle-active", adminMiddleware, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("isActive");
    if (!user) return res.status(404).json({ message: "User not found" });
    user.isActive = !user.isActive;
    await user.save();
    res.json({ isActive: user.isActive });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH change role
router.patch("/:id/role", adminMiddleware, async (req, res) => {
  try {
    const { role } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role },
      { new: true, runValidators: true }
    ).select("-password");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE user
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json({ message: "User deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
