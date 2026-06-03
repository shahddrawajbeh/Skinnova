const express = require("express");
const router = express.Router();
const bcrypt = require("bcryptjs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const User = require("../../models/user");

// GET all admin accounts
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const admins = await User.find({ role: "admin" })
      .select("-password")
      .sort({ createdAt: -1 });
    res.json(admins);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create admin account
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const { fullName, email, password } = req.body;
    const exists = await User.findOne({ email });
    if (exists) return res.status(400).json({ message: "Email already in use" });
    const hashed = await bcrypt.hash(password, 10);
    const admin = new User({ fullName, email, password: hashed, role: "admin" });
    await admin.save();
    const saved = admin.toObject();
    delete saved.password;
    res.status(201).json(saved);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update admin
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const { fullName, email } = req.body;
    const admin = await User.findOneAndUpdate(
      { _id: req.params.id, role: "admin" },
      { fullName, email },
      { new: true, runValidators: true }
    ).select("-password");
    if (!admin) return res.status(404).json({ message: "Admin not found" });
    res.json(admin);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH change password
router.patch("/:id/change-password", adminMiddleware, async (req, res) => {
  try {
    const { newPassword } = req.body;
    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters" });
    }
    const hashed = await bcrypt.hash(newPassword, 10);
    const admin = await User.findOneAndUpdate(
      { _id: req.params.id, role: "admin" },
      { password: hashed },
      { new: true }
    ).select("-password");
    if (!admin) return res.status(404).json({ message: "Admin not found" });
    res.json({ message: "Password changed" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE admin (cannot delete self)
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    if (req.params.id === req.adminId) {
      return res.status(400).json({ message: "Cannot delete your own admin account" });
    }
    const admin = await User.findOneAndDelete({ _id: req.params.id, role: "admin" });
    if (!admin) return res.status(404).json({ message: "Admin not found" });
    res.json({ message: "Admin deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
