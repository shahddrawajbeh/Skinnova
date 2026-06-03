const mongoose = require("mongoose");

const welcomeSettingsSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      default: "Welcome to Skinova",
    },
    subtitle: {
      type: String,
      default:
        "Your ultimate companion for your skincare journey. Achieve healthier skin with personalized routines and progress tracking.",
    },
    buttonText: {
      type: String,
      default: "Get Started",
    },
    mediaType: {
      type: String,
      enum: ["image", "video"],
      default: "video",
    },
    mediaUrl: {
      type: String,
      default: "",
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.WelcomeSettings ||
  mongoose.model("WelcomeSettings", welcomeSettingsSchema);
