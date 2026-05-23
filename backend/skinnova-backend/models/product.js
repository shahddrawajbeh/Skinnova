

const mongoose = require("mongoose");

const ingredientSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, trim: true, default: "" },
  },
  { _id: false }
);



const productSchema = new mongoose.Schema(
  {
    brand: {
      type: String,
      required: true,
      trim: true,
    },

    name: {
      type: String,
      required: true,
      trim: true,
    },
    category: {
  type: String,
  trim: true,
  default: "",
  lowercase: true,
},

  shortDescription: {
      type: String,
      trim: true,
      default: "",
    },
 directionsOfUse: {
  type: String,
  trim: true,
  default: "",
},

    imageUrl: {
      type: String,
      trim: true,
      default: "",
    },

    rating: {
      type: Number,
      default: 0,
    },
reviews: [
  {
    userId: {
      type: String,
      required: true,
    },
    userName: {
      type: String,
      required: true,
    },
    rating: {
      type: Number,
      required: true,
      min: 1,
      max: 5,
    },
    title: {
      type: String,
      default: "",
    },
    comment: {
      type: String,
      default: "",
    },
    repurchase: {
      type: Boolean,
      default: null,
    },
    improvedSkin: {
      type: Boolean,
      default: null,
    },
    wasGift: {
      type: Boolean,
      default: null,
    },
    adverseReaction: {
      type: Boolean,
      default: null,
    },
    texture: {
      type: String,
      default: "",
    },
    usageWeeks: {
      type: String,
      default: "",
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
],

    whatsInside: {
      alcoholFree: { type: Boolean, default: false },
      euAllergenFree: { type: Boolean, default: false },
      fragranceFree: { type: Boolean, default: false },
      oilFree: { type: Boolean, default: false },
      parabenFree: { type: Boolean, default: false },
      siliconeFree: { type: Boolean, default: false },
      sulfateFree: { type: Boolean, default: false },
      crueltyFree: { type: Boolean, default: false },
      fungalAcneSafe: { type: Boolean, default: false },
      reefSafe: { type: Boolean, default: false },
      vegan: { type: Boolean, default: false },
    },

    ingredients: {
      type: [ingredientSchema],
      default: [],
    },

    brandOrigin: {
      type: String,
      trim: true,
      default: "",
    },

    price: {
      type: Number,
      default: 0,
    },

    currency: {
      type: String,
      trim: true,
      default: "USD",
    },

    inStock: {
      type: Boolean,
      default: true,
    },

    stockCount: {
      type: Number,
      default: 0,
    },

    size: {
      type: String,
      trim: true,
      default: "",
    },

    discountPercent: {
      type: Number,
      default: 0,
    },

    recommendedFor: {
      skinTypes: {
        type: [String],
        default: [],
      },
      concerns: {
        type: [String],
        default: [],
      },
      goals: {
        type: [String],
        default: [],
      },
    },

    isPublished: {
      type: Boolean,
      default: true,
    },
  },
  { timestamps: true }
);
//module.exports = mongoose.model("Product", productSchema);
module.exports =
  mongoose.models.Product || mongoose.model("Product", productSchema);