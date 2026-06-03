const { getAppSettings } = require("../helpers/getAppSettings");

/**
 * Blocks non-admin requests while maintenance mode is on.
 * Admin routes (paths starting with /api/admin) are always allowed through.
 */
const maintenanceMiddleware = async (req, res, next) => {
  // Never block admin routes
  if (req.path.startsWith("/api/admin") || req.originalUrl.startsWith("/api/admin")) {
    return next();
  }
  try {
    const settings = await getAppSettings();
    if (settings.maintenanceMode) {
      return res.status(503).json({
        maintenance: true,
        message: settings.maintenanceMessage ||
          "The app is currently under maintenance. Please try again later.",
      });
    }
    next();
  } catch (_) {
    // If settings can't be loaded, let the request through
    next();
  }
};

module.exports = maintenanceMiddleware;
