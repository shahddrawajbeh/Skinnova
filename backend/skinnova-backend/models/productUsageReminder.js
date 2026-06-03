const mongoose = require("mongoose");

const reminderTimeSchema = new mongoose.Schema({
  dayOfWeek: { type: Number, min: 0, max: 6, default: null }, // null = every day, 0=Sun…6=Sat
  time: { type: String, required: true }, // "HH:mm" 24-hour e.g. "08:00"
  enabled: { type: Boolean, default: true },
});

const productUsageReminderSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      default: null,
    },
    productNameSnapshot: { type: String, required: true, trim: true },
    productImageSnapshot: { type: String, default: "" },
    brandSnapshot: { type: String, default: "" },
    directionsOfUseSnapshot: { type: String, default: "" },
    reminderTimes: [reminderTimeSchema],
    frequencyType: {
      type: String,
      enum: ["daily", "twice_daily", "weekly", "custom"],
      default: "daily",
    },
    isActive: { type: Boolean, default: true },
    lastNotifiedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

productUsageReminderSchema.index({ userId: 1, productId: 1 });

module.exports = mongoose.model("ProductUsageReminder", productUsageReminderSchema);
