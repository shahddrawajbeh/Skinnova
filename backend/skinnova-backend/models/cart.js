const mongoose = require("mongoose");

const cartItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
    required: true,
  },

  storeId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Store",
  },

  quantity: {
    type: Number,
    default: 1,
  },

  price: {
    type: Number,
    default: 0,
  },

  currency: {
    type: String,
    default: "ILS",
  },
});

const cartSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
    },
    items: [cartItemSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model("Cart", cartSchema);