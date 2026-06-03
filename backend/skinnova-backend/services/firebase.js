/**
 * Firebase Admin SDK setup.
 *
 * SETUP INSTRUCTIONS:
 * 1. Go to Firebase Console → Project Settings → Service Accounts
 * 2. Click "Generate new private key" and download the JSON file
 * 3. Save it as: backend/skinnova-backend/firebase-service-account.json
 * 4. Add that filename to your .gitignore (NEVER commit it to Git)
 * 5. Add to your .env:
 *      FIREBASE_PROJECT_ID=your-project-id
 *    (optional: use GOOGLE_APPLICATION_CREDENTIALS path instead)
 */

const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

let _initialized = false;

function initFirebase() {
  if (_initialized) return;

  const serviceAccountPath = path.join(__dirname, "../firebase-service-account.json");

  if (!fs.existsSync(serviceAccountPath)) {
    console.warn(
      "⚠️  Firebase service account file not found at firebase-service-account.json — push notifications disabled."
    );
    return;
  }

  try {
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    _initialized = true;
    console.log("✅ Firebase Admin SDK initialized");
  } catch (err) {
    console.error("❌ Firebase Admin SDK init error:", err.message);
  }
}

function getMessaging() {
  if (!_initialized) return null;
  return admin.messaging();
}

module.exports = { initFirebase, getMessaging };
