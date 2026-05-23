const mongoose = require("mongoose");

const scanHistorySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    imageUrl: {
      type: String,
      default: "",
    },

    ocrText: {
      type: String,
      default: "",
    },

    matched: {
      type: Boolean,
      default: false,
    },

    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      default: null,
    },

    productName: {
      type: String,
      default: "",
    },

    productBrand: {
      type: String,
      default: "",
    },

    confidence: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("ScanHistory", scanHistorySchema);