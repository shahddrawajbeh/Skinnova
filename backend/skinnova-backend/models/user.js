const mongoose = require("mongoose");
const collectionSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: true,
      trim: true,
    },
    images: {
      type: [String],
      default: [],
    },
  },
  { _id: true }
);
const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      trim: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    profileImage: {
    type: String,
    default: "",
    },
    collections: {
      type: [collectionSchema],
      default: [],
    },
    password: {
      type: String,
      required: true,
    },
    role: {
      type: String,
      enum: ["user", "seller", "admin"],
      default: "user",
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    favorites: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
  },
],
recentlyUsedProducts: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Product",
  },
],
savedPosts: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "GroupPost",
  },
],
followers: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
],

following: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "User",
  },
],

hiddenStores: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Store",
  },
],

followedStores: [
  {
    type: mongoose.Schema.Types.ObjectId,
    ref: "Store",
  },
],

    bio: {
      type: String,
      trim: true,
      default: "",
    },
    city: {
      type: String,
      trim: true,
      default: "",
    },
    scanPrivacy: {
      allowScanHistory: { type: Boolean, default: true },
      allowPersonalizedRecommendations: { type: Boolean, default: true },
      allowImageStorage: { type: Boolean, default: true },
    },
    onboarding: {
      gender: String,
      ageRange: String,
      skinType: String,
      skinSensitivity: String,
      skinConcerns: [String],
      skinPhototype: String,
      skincareExperience: String,
      goals: [String],
      chronicCondition: String,
      specialConditions: [String],
    },

    // FCM tokens — one per device, multiple devices supported
    fcmTokens: {
      type: [String],
      default: [],
    },

    // Password reset via OTP
    resetOtp: { type: String, default: null },
    resetOtpExpires: { type: Date, default: null },

    // Google OAuth
    googleId: { type: String, default: null, sparse: true },
    profileProvider: {
      type: String,
      enum: ["email", "google"],
      default: "email",
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);