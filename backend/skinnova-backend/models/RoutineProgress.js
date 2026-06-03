const mongoose = require('mongoose');

const RoutineProgressSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    routineId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'UserRoutine',
      required: true,
    },
    date: { type: String, required: true }, // "YYYY-MM-DD"
    completedStepIds: { type: [String], default: [] },
    totalPoints: { type: Number, default: 0 },
    bonusAwarded: { type: Boolean, default: false },
    streak: { type: Number, default: 0 },
  },
  { timestamps: true }
);

RoutineProgressSchema.index({ userId: 1, routineId: 1, date: 1 }, { unique: true });

module.exports =
  mongoose.models.RoutineProgress ||
  mongoose.model('RoutineProgress', RoutineProgressSchema);
