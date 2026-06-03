const User = require("../models/user");

// Reads x-admin-id header, verifies the user exists and has role "admin"
const adminMiddleware = async (req, res, next) => {
  try {
    const adminId = req.headers["x-admin-id"];
    if (!adminId) {
      return res.status(401).json({ message: "Unauthorized: Admin ID required" });
    }

    const user = await User.findById(adminId).select("role isActive");
    if (!user) {
      return res.status(401).json({ message: "Unauthorized: User not found" });
    }
    if (user.role !== "admin") {
      return res.status(403).json({ message: "Forbidden: Admin access only" });
    }
    if (user.isActive === false) {
      return res.status(403).json({ message: "Forbidden: Account deactivated" });
    }

    req.adminId = adminId;
    next();
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
};

module.exports = adminMiddleware;
