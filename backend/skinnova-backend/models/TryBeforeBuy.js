const mongoose = require("mongoose");

const tryBeforeBuySchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    productId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Product",
      required: true,
    },
    originalImageUrl: { type: String, default: "" },
    generatedImageUrl: { type: String, default: "" },
    suitabilityScore: { type: Number, default: 0 },
    expectedEffects: { type: [String], default: [] },
    warnings: { type: [String], default: [] },
    imagePrompt: { type: String, default: "" },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.TryBeforeBuy ||
  mongoose.model("TryBeforeBuy", tryBeforeBuySchema);
