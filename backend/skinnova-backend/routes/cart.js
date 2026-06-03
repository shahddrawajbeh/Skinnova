const express = require("express");
const mongoose = require("mongoose");
const router = express.Router();

const Cart = require("../models/cart");
const Product = require("../models/product");
const StoreProduct = require("../models/storeProduct");

// add product to cart
router.post("/add", async (req, res) => {
  try {
    const { userId, productId, storeId, quantity, price, currency } = req.body;

    if (!userId || !productId || !storeId || price == null) {
      return res.status(400).json({
        message: "userId, productId, storeId and price are required",
      });
    }

    if (
      !mongoose.Types.ObjectId.isValid(userId) ||
      !mongoose.Types.ObjectId.isValid(productId) ||
      !mongoose.Types.ObjectId.isValid(storeId)
    ) {
      return res.status(400).json({
        message: "Invalid userId, productId or storeId",
      });
    }

    const productExists = await Product.findById(productId);
    if (!productExists) {
      return res.status(404).json({ message: "Product not found" });
    }

    // ── Stock validation ──────────────────────────────────────────────────────
    const storeProduct = await StoreProduct.findOne({ storeId, productId });
    if (!storeProduct) {
      return res.status(404).json({
        message: "This product is not available in this store.",
      });
    }
    if (!storeProduct.isAvailable || storeProduct.stockCount <= 0) {
      return res.status(400).json({
        message: "This product is currently out of stock in this store.",
      });
    }

    const requestedQty = quantity || 1;

    // Read cart once to check existing quantity in cart
    let cart = await Cart.findOne({ userId });
    let currentCartQty = 0;
    if (cart) {
      const existingItem = cart.items.find(
        (item) =>
          item.productId.toString() === productId &&
          item.storeId?.toString() === storeId
      );
      if (existingItem) currentCartQty = existingItem.quantity;
    }

    if (currentCartQty + requestedQty > storeProduct.stockCount) {
      return res.status(400).json({
        message: `Only ${storeProduct.stockCount} item${storeProduct.stockCount === 1 ? "" : "s"} available in stock.`,
      });
    }
    // ─────────────────────────────────────────────────────────────────────────

    if (!cart) {
      cart = new Cart({
        userId,
        items: [{ productId, storeId, quantity: requestedQty, price, currency: currency || "ILS" }],
      });
    } else {
      const existingItem = cart.items.find(
        (item) =>
          item.productId.toString() === productId &&
          item.storeId?.toString() === storeId
      );
      if (existingItem) {
        existingItem.quantity += requestedQty;
      } else {
        cart.items.push({ productId, storeId, quantity: requestedQty, price, currency: currency || "ILS" });
      }
    }

    await cart.save();

    res.status(200).json({
      message: "Product added to cart successfully",
      cart,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// get user's cart
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        message: "Invalid userId",
      });
    }

    const cart = await Cart.findOne({ userId }).populate("items.productId")
.populate("items.storeId");

    if (!cart) {
      return res.status(200).json({
        items: [],
      });
    }

    res.status(200).json(cart);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// remove one product from cart
router.delete("/remove", async (req, res) => {
  try {
const { userId, productId, storeId } = req.body;
if (!userId || !productId || !storeId) {      return res.status(400).json({
        message: "userId and productId are required",
      });
    }

    const cart = await Cart.findOne({ userId });

    if (!cart) {
      return res.status(404).json({
        message: "Cart not found",
      });
    }

  cart.items = cart.items.filter(
  (item) =>
    !(
      item.productId.toString() === productId &&
      item.storeId?.toString() === storeId
    )
);

    await cart.save();

    res.status(200).json({
      message: "Product removed from cart",
      cart,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/update", async (req, res) => {
  try {
    const { userId, productId, storeId, quantity } = req.body;
    if (!userId || !productId || !storeId || quantity == null) {
      return res.status(400).json({
        message: "userId, productId, storeId and quantity are required",
      });
    }

    // ── Stock validation ──────────────────────────────────────────────────────
    const storeProduct = await StoreProduct.findOne({ storeId, productId });
    if (!storeProduct || !storeProduct.isAvailable || storeProduct.stockCount <= 0) {
      return res.status(400).json({
        message: "This product is currently out of stock in this store.",
      });
    }
    if (quantity > storeProduct.stockCount) {
      return res.status(400).json({
        message: `Only ${storeProduct.stockCount} item${storeProduct.stockCount === 1 ? "" : "s"} available in stock.`,
      });
    }
    // ─────────────────────────────────────────────────────────────────────────

    const cart = await Cart.findOne({ userId });
    if (!cart) {
      return res.status(404).json({ message: "Cart not found" });
    }

    const item = cart.items.find(
      (item) =>
        item.productId.toString() === productId &&
        item.storeId?.toString() === storeId
    );
    if (!item) {
      return res.status(404).json({ message: "Product not found in cart" });
    }

    item.quantity = quantity;
    await cart.save();

    res.status(200).json({ message: "Cart quantity updated", cart });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

module.exports = router;