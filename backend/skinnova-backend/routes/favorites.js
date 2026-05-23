const express = require("express");
const mongoose = require("mongoose");
const User = require("../models/user");

const router = express.Router();

// Toggle favorite
router.post("/toggle", async (req, res) => {
  try {
    const { userId, productId } = req.body;

    if (!userId || !productId) {
      return res.status(400).json({
        message: "userId and productId are required",
      });
    }

    if (
      !mongoose.Types.ObjectId.isValid(userId) ||
      !mongoose.Types.ObjectId.isValid(productId)
    ) {
      return res.status(400).json({
        message: "Invalid userId or productId",
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    const alreadyFavorite = user.favorites.some(
      (fav) => fav.toString() === productId
    );

    if (alreadyFavorite) {
      user.favorites = user.favorites.filter(
        (fav) => fav.toString() !== productId
      );
    } else {
      user.favorites.push(productId);
    }

    await user.save();

    res.status(200).json({
      message: alreadyFavorite
        ? "Removed from favorites"
        : "Added to favorites",
      favorites: user.favorites,
      isFavorite: !alreadyFavorite,
    });
  } catch (error) {
    console.log("❌ TOGGLE FAVORITE ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// Get all favorites for one user
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ message: "Invalid userId" });
    }

    const user = await User.findById(userId).populate("favorites");

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json(user.favorites);
  } catch (error) {
    console.log("❌ GET FAVORITES ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

module.exports = router;