const mongoose = require("mongoose");

const userSupportMessageSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },
    userName: { type: String, default: "", trim: true },
    email: { type: String, trim: true, lowercase: true, default: "" },
    type: {
      type: String,
      enum: ["contact", "bug"],
      required: true,
    },
    subject: { type: String, required: true, trim: true },
    message: { type: String, required: true, trim: true },
    status: {
      type: String,
      enum: ["open", "in_progress", "resolved", "dismissed"],
      default: "open",
    },
    adminNote: { type: String, default: "", trim: true },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.UserSupportMessage ||
  mongoose.model("UserSupportMessage", userSupportMessageSchema);
