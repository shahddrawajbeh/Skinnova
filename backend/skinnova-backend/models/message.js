const mongoose = require("mongoose");

const messageSchema = new mongoose.Schema(
  {
    conversationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Conversation",
      required: true,
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    senderType: {
      type: String,
      enum: ["user", "seller", "system"],
      required: true,
    },
    messageType: {
      type: String,
      enum: ["text", "product", "order_update", "image"],
      default: "text",
    },
    text: { type: String, default: "" },
    productSnapshot: {
      name: { type: String, default: "" },
      imageUrl: { type: String, default: "" },
      price: { type: Number, default: 0 },
      currency: { type: String, default: "ILS" },
      storeProductId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: "StoreProduct",
        default: null,
      },
    },
    imageUrl: { type: String, default: "" },
    isSeen: { type: Boolean, default: false },
    seenAt: { type: Date },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Message", messageSchema);
