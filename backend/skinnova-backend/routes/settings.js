const express = require("express");
const router = express.Router();
const { getAppSettings } = require("../helpers/getAppSettings");

// GET /api/settings/public — safe subset of AppSettings for the Flutter app
router.get("/public", async (req, res) => {
  try {
    const s = await getAppSettings();
    res.json({
      maintenanceMode: s.maintenanceMode,
      maintenanceMessage: s.maintenanceMessage,
      allowNewRegistrations: s.allowNewRegistrations,
      allowSkinScans: s.allowSkinScans,
      allowProductScans: s.allowProductScans,
      allowReviews: s.allowReviews,
      allowGroupPosts: s.allowGroupPosts,
      contactEmail: s.contactEmail,
      contactPhone: s.contactPhone,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
