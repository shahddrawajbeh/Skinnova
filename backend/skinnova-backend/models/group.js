const mongoose = require("mongoose");

const groupSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    slug: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    coverImage: {
      type: String,
      default: "",
    },
    profileImage: {
      type: String,
      default: "",
    },
    description: {
      type: String,
      default: "",
      trim: true,
    },
    categoryKey: {
      type: String,
      default: "",
      lowercase: true,
      trim: true,
    },
     groupType: {
      type: String,
      enum: ["skin_types", "skin_colors", "product_categories","skin_concerns","skin_tones","skin_type","medications"],
      default: "product_categories",
    },
    membersCount: {
      type: Number,
      default: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    
  },
  { timestamps: true }
);

module.exports = mongoose.model("Group", groupSchema);