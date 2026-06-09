const mongoose = require("mongoose");

const loginActivitySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    loginTime: { type: Date, default: Date.now, index: true },
    logoutTime: { type: Date, default: null },
    sessionDuration: { type: Number, default: null }, // seconds
    device: { type: String, default: "Mobile" },
    browser: { type: String, default: "" },
    ipAddress: { type: String, default: "" },
    platform: { type: String, default: "Unknown" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("LoginActivity", loginActivitySchema);
