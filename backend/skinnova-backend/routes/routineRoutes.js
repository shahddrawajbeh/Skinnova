const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const UserRoutine = require('../models/UserRoutine');
const RoutineProgress = require('../models/RoutineProgress');
const Product = require('../models/product');

// ─── POST /api/routines/ai ────────────────────────────────────────────────────
// Save an AI-generated routine for a user (deactivates previous active routine)
router.post('/ai', async (req, res) => {
  try {
    const { userId, detectedConcerns = [], morning = [], evening = [] } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    let routine = await UserRoutine.findOne({ userId, isActive: true });

    if (!routine) {
      routine = new UserRoutine({
        userId,
        source: 'ai',
        isActive: true,
      });
    }

    const oldCustomMorning = routine.morning.filter(s => s.source === 'custom');
    const oldCustomEvening = routine.evening.filter(s => s.source === 'custom');

    routine.source = 'ai';
    routine.detectedConcerns = detectedConcerns;

    routine.morning = [
      ...morning.map(s => ({ ...s, source: 'ai', timeOfDay: 'morning' })),
      ...oldCustomMorning,
    ];

    routine.evening = [
      ...evening.map(s => ({ ...s, source: 'ai', timeOfDay: 'evening' })),
      ...oldCustomEvening,
    ];

    await routine.save();

    res.status(201).json(routine);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/routines/active/:userId ────────────────────────────────────────
// Get the active routine for a user
router.get('/active/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const routine = await UserRoutine.findOne({ userId, isActive: true }).lean();
    if (!routine) return res.status(404).json({ error: 'No active routine found' });
    res.json(routine);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/routines/custom-step ──────────────────────────────────────────
// Add a custom step to the active routine (creates routine if none exists)
router.post('/custom-step', async (req, res) => {
  try {
    const { userId, step } = req.body;
    if (!userId || !step) return res.status(400).json({ error: 'userId and step are required' });

    let routine = await UserRoutine.findOne({ userId, isActive: true });
    if (!routine) {
      routine = new UserRoutine({ userId, source: 'manual', isActive: true });
    }

    const newStep = { ...step, source: 'custom' };
    if (step.timeOfDay === 'evening') {
      routine.evening.push(newStep);
    } else {
      routine.morning.push(newStep);
    }

    await routine.save();
    res.status(201).json(routine);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── PUT /api/routines/custom-step/:routineId/:stepId ────────────────────────
// Update a custom step
router.put('/custom-step/:routineId/:stepId', async (req, res) => {
  try {
    const { routineId, stepId } = req.params;
    const updates = req.body;

    const routine = await UserRoutine.findById(routineId);
    if (!routine) return res.status(404).json({ error: 'Routine not found' });

    let step =
      routine.morning.id(stepId) || routine.evening.id(stepId);
    if (!step) return res.status(404).json({ error: 'Step not found' });
    if (step.source !== 'custom') return res.status(403).json({ error: 'Cannot edit AI steps' });

    Object.assign(step, updates);
    await routine.save();
    res.json(routine);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── DELETE /api/routines/custom-step/:routineId/:stepId ─────────────────────
// Remove a custom step
router.delete('/custom-step/:routineId/:stepId', async (req, res) => {
  try {
    const { routineId, stepId } = req.params;

    const routine = await UserRoutine.findById(routineId);
    if (!routine) return res.status(404).json({ error: 'Routine not found' });

    const inMorning = routine.morning.id(stepId);
    const inEvening = routine.evening.id(stepId);

    if (!inMorning && !inEvening) return res.status(404).json({ error: 'Step not found' });

    if (inMorning) {
      if (inMorning.source !== 'custom') return res.status(403).json({ error: 'Cannot delete AI steps' });
      routine.morning.pull(stepId);
    } else {
      if (inEvening.source !== 'custom') return res.status(403).json({ error: 'Cannot delete AI steps' });
      routine.evening.pull(stepId);
    }

    await routine.save();
    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/routines/progress/toggle ──────────────────────────────────────
// Toggle a step done/undone for today and update points/streak
router.post('/progress/toggle', async (req, res) => {
  try {
    const { userId, routineId, stepId } = req.body;
    if (!userId || !routineId || !stepId) {
      return res.status(400).json({ error: 'userId, routineId and stepId are required' });
    }

const today = new Date().toLocaleDateString('en-CA', {
  timeZone: 'Asia/Hebron',
});
let progress = await RoutineProgress.findOne({
  userId,
  routineId,
  date: today,
});

const prevProgress = await RoutineProgress.findOne({
  userId,
  routineId,
  date: { $lt: today },
}).sort({ date: -1 });

if (!progress) {
  progress = new RoutineProgress({
    userId,
    routineId,
    date: today,
    completedStepIds: [],
    totalPoints: prevProgress ? prevProgress.totalPoints : 0,
    streak: prevProgress ? prevProgress.streak : 0,
  });
} else if (prevProgress && progress.totalPoints === 0) {
  progress.totalPoints = prevProgress.totalPoints || 0;
  progress.streak = prevProgress.streak || 0;
}
//     let progress = await RoutineProgress.findOne({ userId, routineId, date: today });
//     const prevProgress = await RoutineProgress.findOne({
//   userId,
//   routineId,
//   date: { $lt: today },
// }).sort({ date: -1 });

// if (progress && prevProgress && progress.totalPoints === 0) {
//   progress.totalPoints = prevProgress.totalPoints || 0;
//   progress.streak = prevProgress.streak || 0;
// }
//     if (!progress) {
//       // Compute streak from yesterday
//       const yesterday = new Date();
//       yesterday.setDate(yesterday.getDate() - 1);
// const yday = yesterday.toLocaleDateString('en-CA', {
//   timeZone: 'Asia/Hebron',
// });    const prevProgress = await RoutineProgress.findOne({
//   userId,
//   routineId,
//   date: { $lt: today },
// }).sort({ date: -1 });

// const streak = prevProgress ? prevProgress.streak : 0;
// const totalPoints = prevProgress ? prevProgress.totalPoints : 0;

// progress = new RoutineProgress({
//   userId,
//   routineId,
//   date: today,
//   streak,
//   totalPoints,
// });
//     }

    const idx = progress.completedStepIds.indexOf(stepId);
    let pointsDelta = 0;

    if (idx === -1) {
      progress.completedStepIds.push(stepId);
      pointsDelta = 10;
    } else {
      progress.completedStepIds.splice(idx, 1);
      pointsDelta = -10;
      // Revoke bonus if previously awarded
      if (progress.bonusAwarded) {
        pointsDelta -= 30;
        progress.bonusAwarded = false;
      }
    }

    // Check if all steps are now completed (award bonus only once)
    const routine = await UserRoutine.findById(routineId).lean();
    if (routine) {
      const allStepIds = [
        ...routine.morning.map((s) => s._id.toString()),
        ...routine.evening.map((s) => s._id.toString()),
      ];
      const allDone =
        allStepIds.length > 0 &&
        allStepIds.every((id) => progress.completedStepIds.includes(id));

      if (allDone && !progress.bonusAwarded) {
        pointsDelta += 30;
        progress.bonusAwarded = true;

        // Increment streak
        progress.streak += 1;
      }
    }

    progress.totalPoints = Math.max(0, progress.totalPoints + pointsDelta);
    await progress.save();

    res.json(progress);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── GET /api/routines/progress/:userId/:routineId ────────────────────────────
// Get today's progress for a routine
router.get('/progress/:userId/:routineId', async (req, res) => {
  try {
    const { userId, routineId } = req.params;

    const today = new Date().toLocaleDateString('en-CA', {
      timeZone: 'Asia/Hebron',
    });

    const progress = await RoutineProgress.findOne({
      userId,
      routineId,
      date: today,
    }).lean();

    if (!progress) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);

      const yday = yesterday.toLocaleDateString('en-CA', {
        timeZone: 'Asia/Hebron',
      });

     const prevProgress = await RoutineProgress.findOne({
  userId,
  routineId,
  date: { $lt: today },
}).sort({ date: -1 }).lean();

      return res.json({
        userId,
        routineId,
        date: today,
        completedStepIds: [],
        bonusAwarded: false,
totalPoints: prevProgress ? prevProgress.totalPoints : 0,
streak: prevProgress ? prevProgress.streak : 0,      });
    }

    res.json(progress);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ─── POST /api/routines/recommended-products ─────────────────────────────────
// Return top-matching products for a routine step
router.post('/recommended-products', async (req, res) => {
  try {
    const { productCategory = '', keyIngredient = '', searchTags = [], concernTarget = '' } = req.body;

    const products = await Product.find({ isPublished: { $ne: false } }).lean();

    const catLower = productCategory.toLowerCase();
    const ingLower = keyIngredient.toLowerCase();
    const tagsLower = searchTags.map((t) => t.toLowerCase());
    const concernLower = concernTarget.toLowerCase();

    const scored = products.map((p) => {
      let score = 0;
      const pCat = (p.category || '').toLowerCase();
      const pDesc = (p.shortDescription || '').toLowerCase();
      const pName = (p.name || '').toLowerCase();
      const pIngredients = (p.ingredients || []).map((i) => i.name.toLowerCase());
      const pConcerns = (p.recommendedFor?.concerns || []).map((c) => c.toLowerCase());

      if (catLower && (pCat.includes(catLower) || catLower.includes(pCat))) score += 50;
      if (ingLower) {
        if (pIngredients.some((i) => i.includes(ingLower) || ingLower.includes(i))) score += 40;
        if (pDesc.includes(ingLower) || pName.includes(ingLower)) score += 15;
      }
      tagsLower.forEach((tag) => {
        if (pDesc.includes(tag) || pName.includes(tag) || pCat.includes(tag)) score += 10;
        if (pIngredients.some((i) => i.includes(tag))) score += 8;
      });
      if (concernLower && pConcerns.some((c) => c.includes(concernLower) || concernLower.includes(c))) score += 20;

      return { product: p, score };
    });

    const top = scored
      .filter((s) => s.score > 0)
      .sort((a, b) => b.score - a.score)
      .slice(0, 5)
      .map((s) => s.product);

    res.json(top);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
