const cron = require("node-cron");
const User = require("../models/user");
const SkinScan = require("../models/SkinScan");
const UserRoutine = require("../models/UserRoutine");
const RoutineProgress = require("../models/RoutineProgress");
const Notification = require("../models/notification");
const ProductUsageReminder = require("../models/productUsageReminder");
const { sendNotification } = require("../services/notificationService");

const TZ = process.env.CRON_TIMEZONE || "Asia/Jerusalem";

const SKINCARE_TIPS = [
  "Consistency matters more than using too many products.",
  "Always apply sunscreen in the morning, even on cloudy days.",
  "Patch test new products before applying them to your face.",
  "Do not mix too many active ingredients in one routine.",
  "Hydration and barrier repair are important for healthy skin.",
  "Remove makeup every night to allow your skin to breathe and repair.",
  "Drink enough water — healthy skin starts from within.",
  "Less is more: a simple routine done consistently beats a complicated one.",
  "Never skip moisturizer, even if you have oily skin.",
  "Exfoliate 1–2 times a week to gently remove dead skin cells.",
  "Retinol and acids are powerful but go slowly — introduce one at a time.",
  "A good night's sleep is one of the best things for your skin.",
  "Change your pillowcase at least once a week to avoid bacteria buildup.",
  "Apply serums before moisturizer for maximum absorption.",
  "SPF is the most important anti-aging step in any routine.",
];

// ── Helpers ────────────────────────────────────────────────────────────────────

/** Returns true if this userId already has a notification of `type` created today. */
async function alreadySentToday(userId, type) {
  const start = new Date();
  start.setHours(0, 0, 0, 0);
  const end = new Date();
  end.setHours(23, 59, 59, 999);
  const hit = await Notification.findOne({
    userId,
    type,
    createdAt: { $gte: start, $lte: end },
  }).select("_id").lean();
  return !!hit;
}

/** Returns all active non-admin users. */
async function getActiveUsers() {
  return User.find({ isActive: true, role: { $nin: ["admin"] } })
    .select("_id")
    .lean();
}

// ── Job 1: Skin Scan Reminder — daily at 19:00 ────────────────────────────────
async function sendSkinScanReminders() {
  console.log("[CRON] skin scan reminder — starting");
  try {
    const users = await getActiveUsers();
    const dayStart = new Date();
    dayStart.setHours(0, 0, 0, 0);
    const dayEnd = new Date();
    dayEnd.setHours(23, 59, 59, 999);

    let sent = 0;
    let skipped = 0;

    await Promise.allSettled(
      users.map(async (user) => {
        const userId = user._id.toString();
        try {
          // Already reminded today?
          if (await alreadySentToday(userId, "skin_scan_reminder")) {
            skipped++;
            return;
          }
          // Scanned today?
          const hasScan = await SkinScan.exists({
            userId,
            createdAt: { $gte: dayStart, $lte: dayEnd },
          });
          if (hasScan) {
            skipped++;
            return;
          }
          await sendNotification({
            userId,
            title: "Time for your skin check ✨",
            body: "You haven't scanned your skin today. Take a quick scan to keep your progress updated.",
            type: "skin_scan_reminder",
            data: { type: "skin_scan_reminder" },
          });
          sent++;
        } catch (err) {
          console.error(`[CRON] skin scan reminder userId=${userId}:`, err.message);
        }
      })
    );

    console.log(
      `[CRON] skin scan reminder — done. sent=${sent} skipped=${skipped} total=${users.length}`
    );
  } catch (err) {
    console.error("[CRON] sendSkinScanReminders error:", err.message);
  }
}

// ── Job 2: Routine Step Reminder — daily at 21:00 ────────────────────────────
async function sendRoutineReminders() {
  console.log("[CRON] routine reminder — starting");
  try {
    const users = await getActiveUsers();
    const today = new Date().toISOString().slice(0, 10); // "YYYY-MM-DD"

    let sent = 0;
    let skipped = 0;

    await Promise.allSettled(
      users.map(async (user) => {
        const userId = user._id.toString();
        try {
          if (await alreadySentToday(userId, "routine_step_reminder")) {
            skipped++;
            return;
          }
          // Active routine?
          const routine = await UserRoutine.findOne({ userId, isActive: true })
            .select("morning evening _id")
            .lean();
          if (!routine) {
            skipped++;
            return;
          }
          // Count all active steps
          const allSteps = [
            ...(routine.morning || []),
            ...(routine.evening || []),
          ].filter((s) => s.isActive);
          if (allSteps.length === 0) {
            skipped++;
            return;
          }
          // Check today's progress
          const progress = await RoutineProgress.findOne({
            userId,
            routineId: routine._id,
            date: today,
          })
            .select("completedStepIds")
            .lean();
          const completed = progress ? (progress.completedStepIds || []).length : 0;
          if (completed >= allSteps.length) {
            skipped++;
            return; // all steps done today
          }
          await sendNotification({
            userId,
            title: "Don't forget your routine 💆‍♀️",
            body: "You still have skincare steps waiting for today. Mark them as done when you finish.",
            type: "routine_step_reminder",
            data: { type: "routine_step_reminder" },
          });
          sent++;
        } catch (err) {
          console.error(`[CRON] routine reminder userId=${userId}:`, err.message);
        }
      })
    );

    console.log(
      `[CRON] routine reminder — done. sent=${sent} skipped=${skipped} total=${users.length}`
    );
  } catch (err) {
    console.error("[CRON] sendRoutineReminders error:", err.message);
  }
}

// ── Job 3: Skincare Tips — every 3rd day at 11:00 ─────────────────────────────
async function sendSkincareTips() {
  console.log("[CRON] skincare tips — starting");
  try {
    const users = await getActiveUsers();
    // Pick one random tip for today's batch (same tip for all, rotates each run)
    const tip = SKINCARE_TIPS[Math.floor(Math.random() * SKINCARE_TIPS.length)];

    let sent = 0;
    let skipped = 0;

    await Promise.allSettled(
      users.map(async (user) => {
        const userId = user._id.toString();
        try {
          if (await alreadySentToday(userId, "skincare_tip")) {
            skipped++;
            return;
          }
          await sendNotification({
            userId,
            title: "Skinova Tip 🌿",
            body: tip,
            type: "skincare_tip",
            data: { type: "skincare_tip" },
          });
          sent++;
        } catch (err) {
          console.error(`[CRON] skincare tip userId=${userId}:`, err.message);
        }
      })
    );

    console.log(
      `[CRON] skincare tips — done. sent=${sent} skipped=${skipped} total=${users.length}`
    );
  } catch (err) {
    console.error("[CRON] sendSkincareTips error:", err.message);
  }
}

// ── Product Usage Reminders ───────────────────────────────────────────────────
async function sendProductUsageReminders() {
  try {
    const now = new Date();
    const currentDay = now.getDay(); // 0=Sun, 6=Sat
    const currentHour = now.getHours();
    // Round minutes down to nearest 5
    const currentMinute = Math.floor(now.getMinutes() / 5) * 5;
    const timeStr = `${String(currentHour).padStart(2, "0")}:${String(currentMinute).padStart(2, "0")}`;

    const reminders = await ProductUsageReminder.find({ isActive: true }).lean();

    for (const reminder of reminders) {
      const matchingSlot = (reminder.reminderTimes || []).find((slot) => {
        if (!slot.enabled || slot.time !== timeStr) return false;
        // null/undefined dayOfWeek means every day
        if (slot.dayOfWeek !== null && slot.dayOfWeek !== undefined) {
          if (slot.dayOfWeek !== currentDay) return false;
        }
        return true;
      });
      if (!matchingSlot) continue;

      // Skip if already notified within the last 30 minutes
      if (reminder.lastNotifiedAt) {
        const msSince = now - new Date(reminder.lastNotifiedAt);
        if (msSince < 30 * 60 * 1000) continue;
      }

      const dirs = (reminder.directionsOfUseSnapshot || "").trim();
      const shortDirs = dirs.length > 70 ? dirs.substring(0, 70) + "…" : dirs;
      const body = shortDirs
        ? `Time to use ${reminder.productNameSnapshot}. ${shortDirs}`
        : `Time to use ${reminder.productNameSnapshot}.`;

      await sendNotification({
        userId: reminder.userId.toString(),
        title: "Time to use your product 💆‍♀️",
        body,
        type: "product_usage_reminder",
        productId: reminder.productId ? reminder.productId.toString() : undefined,
        imageUrl: reminder.productImageSnapshot || "",
        saveInApp: true,
      });

      await ProductUsageReminder.findByIdAndUpdate(reminder._id, {
        lastNotifiedAt: now,
      });
    }
  } catch (err) {
    console.error("[CRON] sendProductUsageReminders error:", err.message);
  }
}

// ── Register all cron jobs ────────────────────────────────────────────────────
function initReminderJobs() {
  // Skin scan reminder: every day at 7:00 PM
  cron.schedule("0 19 * * *", sendSkinScanReminders, { timezone: TZ });

  // Routine step reminder: every day at 9:00 PM
  cron.schedule("0 21 * * *", sendRoutineReminders, { timezone: TZ });

  // Skincare tip: every 3rd day at 11:00 AM (days 3, 6, 9, ... of month)
  cron.schedule("0 11 */3 * *", sendSkincareTips, { timezone: TZ });

  // Product usage reminders: every 5 minutes
  cron.schedule("*/5 * * * *", sendProductUsageReminders, { timezone: TZ });

  console.log(`✅ Notification reminder jobs registered (tz=${TZ})`);
}

module.exports = {
  initReminderJobs,
  sendSkinScanReminders,
  sendRoutineReminders,
  sendSkincareTips,
  sendProductUsageReminders,
};
