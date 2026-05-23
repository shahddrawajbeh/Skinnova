const mongoose = require("mongoose");

const storeSchema = new mongoose.Schema(
  {
    sellerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    storeName: {
      type: String,
      required: true,
      trim: true,
    },

    logoUrl: {
      type: String,
      default: "",
    },

    coverImageUrl: {
      type: String,
      default: "",
    },

    description: {
      type: String,
      default: "",
    },

    city: {
      type: String,
      required: true,
      trim: true,
    },

    address: {
      type: String,
      default: "",
    },

    phone: {
      type: String,
      default: "",
    },

    rating: {
      type: Number,
      default: 0,
    },
reviews: [
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },
    comment: {
      type: String,
      default: "",
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
],
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Store", storeSchema);