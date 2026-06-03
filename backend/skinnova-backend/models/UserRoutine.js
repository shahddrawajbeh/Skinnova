const mongoose = require('mongoose');

const RoutineStepSchema = new mongoose.Schema(
  {
    stepName: { type: String, required: true, trim: true },
    why: { type: String, default: '' },
    productCategory: { type: String, default: '' },
    keyIngredient: { type: String, default: '' },
    searchTags: { type: [String], default: [] },
    concernTarget: { type: String, default: '' },
    frequency: { type: String, default: 'daily' },
    timeOfDay: { type: String, enum: ['morning', 'evening', ''], default: '' },
    source: { type: String, enum: ['ai', 'custom'], default: 'ai' },
    notes: { type: String, default: '' },
    reminderTime: { type: String, default: '' },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

const UserRoutineSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    routineName: { type: String, default: 'My Skin Routine' },
    source: { type: String, enum: ['ai', 'manual'], default: 'ai' },
    detectedConcerns: { type: [String], default: [] },
    morning: { type: [RoutineStepSchema], default: [] },
    evening: { type: [RoutineStepSchema], default: [] },
    isActive: { type: Boolean, default: true },
  },
  { timestamps: true }
);

// Only one active routine per user at a time
UserRoutineSchema.index({ userId: 1, isActive: 1 });

module.exports =
  mongoose.models.UserRoutine ||
  mongoose.model('UserRoutine', UserRoutineSchema);
