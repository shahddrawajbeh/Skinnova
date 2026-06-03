const mongoose = require("mongoose");

const appSettingsSchema = new mongoose.Schema(
  {
    appName: { type: String, default: "Skinova" },
    maintenanceMode: { type: Boolean, default: false },
    maintenanceMessage: {
      type: String,
      default: "We are currently under maintenance. Please check back soon.",
    },
    allowNewRegistrations: { type: Boolean, default: true },
    allowSkinScans: { type: Boolean, default: true },
    allowProductScans: { type: Boolean, default: true },
    allowReviews: { type: Boolean, default: true },
    allowGroupPosts: { type: Boolean, default: true },
    contactEmail: { type: String, default: "" },
    contactPhone: { type: String, default: "" },
    termsUrl: { type: String, default: "" },
    privacyUrl: { type: String, default: "" },
    currency: { type: String, default: "ILS" },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.AppSettings ||
  mongoose.model("AppSettings", appSettingsSchema);
