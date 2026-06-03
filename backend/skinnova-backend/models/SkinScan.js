const mongoose = require('mongoose');

const ConcernSchema = new mongoose.Schema(
  {
    name: { type: String, default: '' },
    severityScore: { type: Number, default: 0 },
    status: { type: String, default: '' },
    description: { type: String, default: '' },
  },
  { _id: false }
);

const ScanRoutineStepSchema = new mongoose.Schema(
  {
    stepName: { type: String, default: '' },
    why: { type: String, default: '' },
    productCategory: { type: String, default: '' },
    keyIngredient: { type: String, default: '' },
    frequency: { type: String, default: 'daily' },
    timeOfDay: { type: String, default: '' },
  },
  { _id: false }
);

const SkinScanSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    imageUrl: { type: String, default: '' },
    detectedConcerns: { type: [ConcernSchema], default: [] },
    overallStatus: { type: String, default: '' },
    skinScore: { type: Number, default: null },
    morningRoutine: { type: [ScanRoutineStepSchema], default: [] },
    eveningRoutine: { type: [ScanRoutineStepSchema], default: [] },
    rawAiResult: { type: mongoose.Schema.Types.Mixed, default: null },
  },
  { timestamps: true }
);

module.exports =
  mongoose.models.SkinScan || mongoose.model('SkinScan', SkinScanSchema);
