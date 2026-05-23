const mongoose = require("mongoose");

const adSchema = new mongoose.Schema(
  {
    storeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Store",
      required: true,
    },
sellerId: {
  type: mongoose.Schema.Types.ObjectId,
  ref: "User",
  required: true,
},
    title: {
      type: String,
      required: true,
      trim: true,
    },

    subtitle: {
      type: String,
      default: "",
    },

    imageUrl: {
      type: String,
      required: true,
    },

    buttonText: {
      type: String,
      default: "Shop now",
    },

    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },

    adminNote: {
      type: String,
      default: "",
    },

    startDate: {
      type: Date,
      default: Date.now,
    },

    endDate: {
      type: Date,
    },

    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.models.Ad || mongoose.model("Ad", adSchema);