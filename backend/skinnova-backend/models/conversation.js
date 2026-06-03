const mongoose = require("mongoose");

const conversationSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    sellerId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    storeId: { type: mongoose.Schema.Types.ObjectId, ref: "Store", required: true },
    lastMessage: { type: String, default: "" },
    lastMessageTime: { type: Date },
    userUnreadCount: { type: Number, default: 0 },
    sellerUnreadCount: { type: Number, default: 0 },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

conversationSchema.index({ userId: 1, storeId: 1 }, { unique: true });

module.exports = mongoose.model("Conversation", conversationSchema);
