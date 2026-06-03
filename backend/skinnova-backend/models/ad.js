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

    // Where the banner appears in the app
    placement: {
      type: String,
      enum: ["home", "shop", "store", "other"],
      default: "home",
    },

    // What happens when user taps the banner
    actionType: {
      type: String,
      enum: ["store", "product", "category", "link", "none"],
      default: "none",
    },

    // The target ID or URL for the action
    actionTarget: {
      type: String,
      default: "",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.models.Ad || mongoose.model("Ad", adSchema);