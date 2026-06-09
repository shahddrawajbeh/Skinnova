const User = require("../models/user");
const { sendPushNotification, sendPushToRole } = require("../helpers/sendPushNotification");
const { sendEmail, notificationEmailHtml } = require("../helpers/sendEmail");

/**
 * Send in-app + push + email notification to a single user.
 *
 * Wraps the existing sendPushNotification() helper (preserving all current
 * in-app and FCM behaviour) and adds email delivery on top.
 *
 * Email is skipped when:
 *  - The user has notificationSettings.email === false
 *  - EMAIL_USER / EMAIL_PASS are not configured
 *  - The user record has no email address
 *
 * Errors in the email step are logged but never thrown — the calling route
 * will never be crashed by a mail failure.
 *
 * @param {Object}  opts
 * @param {string}  opts.userId
 * @param {string}  opts.title
 * @param {string}  opts.body
 * @param {string}  [opts.type]
 * @param {string}  [opts.storeId]
 * @param {string}  [opts.productId]
 * @param {string}  [opts.postId]
 * @param {string}  [opts.targetLink]
 * @param {string}  [opts.imageUrl]
 * @param {Object}  [opts.data]
 * @param {boolean} [opts.saveInApp]   default true
 * @returns {Promise<{inApp:string, push:string, email:string}>}
 */
async function sendNotification({
  userId,
  title,
  body,
  type = "general",
  storeId,
  productId,
  postId,
  targetLink,
  imageUrl,
  data = {},
  saveInApp = true,
}) {
  const result = { inApp: "skipped", push: "skipped", email: "skipped" };

  // ── 1. In-app + Push (delegate to existing helper — behaviour unchanged) ──
  await sendPushNotification({
    userId,
    title,
    body,
    type,
    storeId,
    productId,
    postId,
    targetLink,
    imageUrl,
    data,
    saveInApp,
  });
  if (saveInApp) result.inApp = "sent";
  result.push = "sent";

  // ── 2. Email ──────────────────────────────────────────────────────────────
  try {
    const user = await User.findById(userId).select("email notificationSettings");
    if (user?.email && user.notificationSettings?.email !== false) {
      await sendEmail({
        to: user.email,
        subject: title,
        html: notificationEmailHtml({ title, body, data }),
      });
      result.email = "sent";
      console.log(`[notificationService] Email sent [${type}] userId=${userId}`);
    }
  } catch (err) {
    console.error(`[notificationService] Email failed [${type}] userId=${userId}:`, err.message);
    result.email = "failed";
  }

  return result;
}

/**
 * Send in-app + push + email notification to every user that has a given role.
 *
 * Wraps sendPushToRole() (preserving existing in-app + FCM behaviour) and
 * additionally sends an email to each user whose notificationSettings.email
 * is not explicitly set to false.
 *
 * @param {Object} opts
 * @param {string} opts.role   "admin" | "seller" | "user"
 * @param {string} opts.title
 * @param {string} opts.body
 * @param {string} [opts.type]
 * @param {Object} [opts.data]
 */
async function sendNotificationToRole({ role, title, body, type, data = {} }) {
  // ── 1. In-app + Push (delegate to existing helper) ────────────────────────
  await sendPushToRole({ role, title, body, type, data });

  // ── 2. Email to each member of the role ───────────────────────────────────
  try {
    const users = await User.find({ role }).select("email notificationSettings");
    const eligible = users.filter(
      (u) => u.email && u.notificationSettings?.email !== false
    );

    console.log(
      `[notificationService] Sending email to role=${role} eligible=${eligible.length}/${users.length}`
    );

    const emailPromises = eligible.map((u) =>
      sendEmail({
        to: u.email,
        subject: title,
        html: notificationEmailHtml({ title, body, data }),
      }).catch((err) =>
        console.error(
          `[notificationService] Email failed role=${role} userId=${u._id}:`,
          err.message
        )
      )
    );

    await Promise.allSettled(emailPromises);
  } catch (err) {
    console.error(
      `[notificationService] sendNotificationToRole role=${role} error:`,
      err.message
    );
  }
}

module.exports = { sendNotification, sendNotificationToRole };
