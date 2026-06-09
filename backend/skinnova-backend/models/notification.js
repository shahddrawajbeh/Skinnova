const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    body: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      enum: [
        "new_product",
        "restock",
        "general",
        "new_order",
        "order_status_changed",
        "review_submitted",
        "admin",
        "store",
        "store_approved",
        "store_rejected",
        "promo",
        "new_ad_request",
        "ad_approved",
        "ad_rejected",
        "new_store_request",
        "post_like",
        "post_comment",
        "new_follower",
        "store_new_follower",
        "followed_store_new_product",
        "support_contact",
        "support_bug",
        "store_report",
        "review_pending",
        "skin_scan_reminder",
        "routine_step_reminder",
        "skincare_tip",
        "product_usage_reminder",
        "order_confirmed_received",
      ],
      default: "general",
    },
    storeId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Store",
      default: null,
    },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      default: null,
    },
    postId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "GroupPost",
      default: null,
    },
    isRead: {
      type: Boolean,
      default: false,
    },
    sentByAdmin: {
      type: Boolean,
      default: false,
    },
    imageUrl: {
      type: String,
      default: "",
    },
    targetLink: {
      type: String,
      default: "",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Notification", notificationSchema);
