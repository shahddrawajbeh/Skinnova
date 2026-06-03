const User = require("../models/user");
const Notification = require("../models/notification");
const { getMessaging } = require("../services/firebase");

/**
 * Send a push notification + save in-app notification.
 *
 * @param {Object} opts
 * @param {string}   opts.userId        - Mongoose ObjectId string
 * @param {string}   opts.title
 * @param {string}   opts.body
 * @param {Object}   [opts.data]        - Custom payload (values coerced to strings for FCM)
 * @param {string}   [opts.type]        - In-app notification type
 * @param {string}   [opts.storeId]
 * @param {string}   [opts.productId]
 * @param {string}   [opts.postId]
 * @param {string}   [opts.targetLink]
 * @param {string}   [opts.imageUrl]
 * @param {boolean}  [opts.saveInApp]   - Persist in-app notification (default true)
 */
async function sendPushNotification({
  userId,
  title,
  body,
  data = {},
  type = "general",
  storeId,
  productId,
  postId,
  targetLink,
  imageUrl,
  saveInApp = true,
}) {
  try {
    // ── 1. Save in-app notification ──────────────────────────────────────────
    if (saveInApp) {
      await Notification.create({
        userId,
        title,
        body,
        type,
        storeId: storeId || null,
        productId: productId || null,
        postId: postId || null,
        targetLink: targetLink || "",
        imageUrl: imageUrl || "",
      });
    }

    // ── 2. Send FCM push ─────────────────────────────────────────────────────
    const messaging = getMessaging();
    if (!messaging) return;

    const user = await User.findById(userId).select("fcmTokens");
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) return;

    // FCM requires all data values to be strings
    const stringData = {};
    for (const [k, v] of Object.entries({ ...data, type })) {
      stringData[k] = v == null ? "" : String(v);
    }
    if (storeId) stringData.storeId = String(storeId);
    if (productId) stringData.productId = String(productId);
    if (postId) stringData.postId = String(postId);
    if (targetLink) stringData.targetLink = String(targetLink);

    const invalidTokens = [];

    for (const token of user.fcmTokens) {
      try {
        const response = await messaging.send({
          token,
          notification: { title, body },
          data: stringData,
          android: {
            notification: {
              channelId: "skinova_default",
              priority: "high",
              sound: "default",
            },
          },
        });
        console.log(`FCM SENT [${type}] userId=${userId} token=...${token.slice(-6)}:`, response);
      } catch (err) {
        console.log(`FCM ERROR [${type}] userId=${userId} code=${err.code} msg=${err.message}`);
        const code = err.code || "";
        if (
          code === "messaging/invalid-registration-token" ||
          code === "messaging/registration-token-not-registered"
        ) {
          invalidTokens.push(token);
        }
      }
    }

    // Remove stale tokens
    if (invalidTokens.length > 0) {
      await User.findByIdAndUpdate(userId, {
        $pull: { fcmTokens: { $in: invalidTokens } },
      });
      console.log(`FCM removed ${invalidTokens.length} stale token(s) for userId=${userId}`);
    }
  } catch (err) {
    console.error("sendPushNotification error:", err.message);
  }
}

/**
 * Send push to all users with a given role ("admin", "seller", "user").
 */
async function sendPushToRole({ role, title, body, data = {}, type }) {
  try {
    const users = await User.find({ role }).select("_id");
    const resolvedType = type || data.type || "general";
    console.log(`FCM sendPushToRole role=${role} userCount=${users.length} type=${resolvedType}`);
    const promises = users.map((u) =>
      sendPushNotification({
        userId: u._id.toString(),
        title,
        body,
        data,
        type: resolvedType,
        saveInApp: true,
      })
    );
    await Promise.allSettled(promises);
  } catch (err) {
    console.error("sendPushToRole error:", err.message);
  }
}

module.exports = { sendPushNotification, sendPushToRole };
