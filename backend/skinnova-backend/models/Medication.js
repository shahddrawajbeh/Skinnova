const mongoose = require("mongoose");

const medicationSchema = new mongoose.Schema(
  {
    name: { type: String, required: true },
    soldAs: { type: [String], default: [] },
    treats: { type: [String], default: [] },
    description: { type: String, default: "" },
    medicalDescription: { type: String, default: "" },
    references: { type: [String], default: [] },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.Medication || mongoose.model("Medication", medicationSchema);