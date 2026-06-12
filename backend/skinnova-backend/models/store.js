const mongoose = require("mongoose");

const areaSchema = new mongoose.Schema(
  {
    name: { type: String, default: "" },
    time: { type: String, default: "1–2 days" },
  },
  { _id: false }
);

const workingHourSchema = new mongoose.Schema(
  {
    day: { type: String, default: "" },
    hours: { type: String, default: "" },
    isOpen: { type: Boolean, default: true },
  },
  { _id: false }
);

const deliveryMethodsSchema = new mongoose.Schema(
  {
    localCourier: { type: Boolean, default: true },
    expressDelivery: { type: Boolean, default: true },
    storePickup: { type: Boolean, default: true },
  },
  { _id: false }
);


const deliveryInfoSchema = new mongoose.Schema(
  {
    areas: {
      type: [areaSchema],
      default: () => [
        { name: "Nablus", time: "Same day" },
        { name: "Ramallah", time: "1–2 days" },
        { name: "Jenin", time: "1–2 days" },
        { name: "Jerusalem", time: "2–3 days" },
        { name: "Tulkarm", time: "1–2 days" },
        { name: "Qalqilya", time: "1–2 days" },
        { name: "Jericho", time: "2–3 days" },
        { name: "Bethlehem", time: "2–3 days" },
      ],
    },
    freeDeliveryOver: { type: Number, default: 150 },
    standardFee: { type: Number, default: 15 },
    expressFee: { type: Number, default: 25 },
    workingHours: {
      type: [workingHourSchema],
      default: () => [
        { day: "Sunday – Thursday", hours: "10:00 AM – 8:00 PM", isOpen: true },
        { day: "Saturday", hours: "11:00 AM – 6:00 PM", isOpen: true },
        { day: "Friday", hours: "Closed", isOpen: false },
      ],
    },
    methods: {
      type: deliveryMethodsSchema,
      default: () => ({}),
    },
    deliverySteps: {
  type: [
    {
      title: { type: String, default: "" },
      subtitle: { type: String, default: "" },
      icon: { type: String, default: "local_shipping" },
    },
  ],
  default: () => [
    {
      title: "Place Your Order",
      subtitle: "Choose your products and complete checkout.",
      icon: "shopping_bag",
    },
    {
      title: "Store Confirms",
      subtitle: "The store reviews and confirms your order.",
      icon: "verified",
    },
    {
      title: "Products Prepared",
      subtitle: "Your skincare products are packed safely.",
      icon: "inventory",
    },
    {
      title: "Delivered to You",
      subtitle: "The courier delivers your order to your address.",
      icon: "local_shipping",
    },
  ],
},
  },
  { _id: false }
);

const storeSchema = new mongoose.Schema(
  {
    sellerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },

    storeName: {
      type: String,
      required: true,
      trim: true,
    },

    logoUrl: {
      type: String,
      default: "",
    },

    coverImageUrl: {
      type: String,
      default: "",
    },

    description: {
      type: String,
      default: "",
    },

    city: {
      type: String,
      required: true,
      trim: true,
    },

    address: {
      type: String,
      default: "",
    },

    phone: {
      type: String,
      default: "",
    },

    rating: {
      type: Number,
      default: 0,
    },

    responseTime: {
      type: String,
      default: "< 1h",
    },

    shippingTime: {
      type: String,
      default: "1–2d",
    },

    deliveryInfo: {
      type: deliveryInfoSchema,
      default: () => ({}),
    },

    

    reviews: [
      {
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
          required: true,
        },
        userName: {
          type: String,
          default: "",
        },
        rating: {
          type: Number,
          required: true,
          min: 1,
          max: 5,
        },
        comment: {
          type: String,
          default: "",
        },
        status: {
          type: String,
          enum: ["pending", "approved", "rejected"],
          default: "pending",
        },
        createdAt: {
          type: Date,
          default: Date.now,
        },
        sellerReply: {
          comment: { type: String, default: "" },
          repliedAt: { type: Date, default: null },
        },
      },
    ],

    followersCount: {
      type: Number,
      default: 0,
      min: 0,
    },

    isActive: {
      type: Boolean,
      default: true,
    },

    // Admin approval for newly created stores
    approvalStatus: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },

    isVerified: {
      type: Boolean,
      default: false,
    },

    verifiedAt: {
      type: Date,
      default: null,
    },

    verifiedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    verificationLevel: {
      type: String,
      enum: ["standard", "premium", "trusted"],
      default: "standard",
    },

    // Verification document fields
    verificationDocumentUrl: {
      type: String,
      default: "",
    },

    verificationDocumentType: {
      type: String,
      enum: ["business_license", "cosmetics_permit", "pharmacy_license", "id_proof", "other"],
      default: "other",
    },

    // verificationStatus tracks document review state
    verificationStatus: {
      type: String,
      enum: ["not_submitted", "pending_review", "verified", "rejected"],
      default: "not_submitted",
    },

    rejectionReason: {
      type: String,
      default: "",
    },

    reviewedAt: {
      type: Date,
      default: null,
    },

    reviewedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      default: null,
    },

    returnPolicy: {
      type: String,
      default: "",
    },

    galleryImages: {
      type: [String],
      default: [],
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("Store", storeSchema);
