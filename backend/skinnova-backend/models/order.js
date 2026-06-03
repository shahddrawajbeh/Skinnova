const mongoose = require("mongoose");

const orderItemSchema = new mongoose.Schema({
  productId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
    required: true,
  },
  quantity: {
    type: Number,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  currency: {
    type: String,
    default: "ILS",
  },
});
const orderSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    storeId: {
  type: mongoose.Schema.Types.ObjectId,
  ref: "Store",
  required: true,
},

storeRated: {
  type: Boolean,
  default: false,
},
    items: [orderItemSchema],

    fullName: {
      type: String,
      required: true,
    },
    phoneNumber: {
      type: String,
      required: true,
    },
    city: {
      type: String,
      required: true,
    },
    streetAddress: {
      type: String,
      required: true,
    },
    note: {
      type: String,
      default: "",
    },

    paymentMethod: {
      type: String,
      enum: ["cod", "card"],
      required: true,
    },

    subtotal: {
      type: Number,
      required: true,
    },
    deliveryFee: {
      type: Number,
      required: true,
      default: 0,
    },
    total: {
      type: Number,
      required: true,
    },

    status: {
  type: String,
  enum: [
    "pending",
    "confirmed",
    "processing",
    "out_for_delivery",
    "delivered",
    "cancelled",
  ],
  default: "pending",
},

    userConfirmedDelivery: {
      type: Boolean,
      default: false,
    },
    userConfirmedDeliveryAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Order", orderSchema);