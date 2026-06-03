const mongoose = require("mongoose");

const homeSettingsSchema = new mongoose.Schema(
  {
    heroImageUrl: { type: String, default: "" },
    heroTitle: { type: String, default: "Discover Your Skin's Best" },
    heroSubtitle: { type: String, default: "Personalized skincare, powered by AI" },
    heroButtonText: { type: String, default: "Get Started" },
    heroButtonAction: {
      type: String,
      enum: ["scan", "shop", "link", "none"],
      default: "scan",
    },
    heroButtonTarget: { type: String, default: "" },
    heroIsActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.HomeSettings ||
  mongoose.model("HomeSettings", homeSettingsSchema);
