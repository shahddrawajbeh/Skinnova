const mongoose = require("mongoose");

const skinConcernGroupSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, default: "" },
    imageUrl: { type: String, default: "" },
    iconName: { type: String, default: "" },
    isActive: { type: Boolean, default: true },
    displayOrder: { type: Number, default: 0 },
    // Where the group appears in the app
    showOn: {
      type: [String],
      enum: ["home", "shop", "product"],
      default: ["home"],
    },
    // Products linked to this group
    products: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: "Product",
      },
    ],
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.SkinConcernGroup ||
  mongoose.model("SkinConcernGroup", skinConcernGroupSchema);
