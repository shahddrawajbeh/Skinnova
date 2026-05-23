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
      enum: ["user", "admin"],
      default: "user",
    },
    favorites: [
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
  },
  { timestamps: true }
);

module.exports = mongoose.model("User", userSchema);