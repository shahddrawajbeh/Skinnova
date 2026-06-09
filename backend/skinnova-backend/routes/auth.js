const express = require("express");
const bcrypt = require("bcryptjs");
const crypto = require("crypto");
const { OAuth2Client } = require("google-auth-library");
const User = require("../models/user");
const LoginActivity = require("../models/LoginActivity");
const multer = require("multer");
const path = require("path");
const GroupPost = require("../models/group_posts");
const { getAppSettings } = require("../helpers/getAppSettings");
const { sendNotification } = require("../services/notificationService");
const { sendEmail, otpEmailHtml } = require("../helpers/sendEmail");

const router = express.Router();

router.post("/register", async (req, res) => {
  try {
    console.log("🔥 REGISTER HIT");
    console.log("BODY:", req.body);

    // Feature flag: allowNewRegistrations
    const settings = await getAppSettings();
    if (!settings.allowNewRegistrations) {
      return res.status(403).json({ message: "New registrations are currently disabled." });
    }

    const { fullName, email, password } = req.body;
    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({ email: normalizedEmail });
    if (existingUser) {
      return res.status(400).json({ message: "Email already exists" });
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({
      fullName,
      email: normalizedEmail,
      password: hashedPassword,
        role: "user",
    });

    await newUser.save();

    console.log("✅ USER SAVED:", newUser);

    res.status(200).json({
      message: "User registered successfully",
      userId: newUser._id,
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({
        message: "Email already exists",
      });
    }

    console.log("❌ ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.trim().toLowerCase();

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(400).json({ message: "User not found" });
    }
if (user.isActive === false) {
  return res.status(403).json({
    message: "Your account has been deactivated. Please contact Skinova support at support@skinova.com.",
  });
}
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Incorrect password" });
    }

    // Track login activity (fire-and-forget)
    try {
      const ua = req.headers["user-agent"] || "";
      await LoginActivity.create({
        userId: user._id,
        loginTime: new Date(),
        device: req.body.device || "Mobile",
        platform: req.body.platform || "Unknown",
        browser: ua.slice(0, 120),
        ipAddress: req.ip || req.connection?.remoteAddress || "",
      });
    } catch (_) { /* non-blocking */ }

    res.status(200).json({
      message: "Login successful",
      userId: user._id,
      role: user.role,
      fullName: user.fullName,
      email: user.email,
    });
  } catch (error) {
    console.log("❌ LOGIN ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/onboarding/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const onboardingData = req.body;

    const updateFields = {};
    for (const key in onboardingData) {
      updateFields[`onboarding.${key}`] = onboardingData[key];
    }

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { $set: updateFields },
      { new: true }
    );

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({
      message: "Onboarding saved successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.log("❌ ONBOARDING ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// router.get("/user/:userId", async (req, res) => {
//   try {
//     const { userId } = req.params;

//     const user = await User.findById(userId);

//     if (!user) {
//       return res.status(404).json({ message: "User not found" });
//     }

//     res.status(200).json(user);
//   } catch (error) {
//     console.log("❌ GET USER ERROR:", error);
//     res.status(500).json({
//       message: "Server error",
//       error: error.message,
//     });
//   }
// // });
// router.get("/user/:userId", async (req, res) => {
//   try {
//     const { userId } = req.params;

//     const user = await User.findById(userId).select("-password");

//     if (!user) {
//       return res.status(404).json({ message: "User not found" });
//     }

//     res.status(200).json(user);
//   } catch (error) {
//     console.log("❌ GET USER ERROR:", error);
//     res.status(500).json({
//       message: "Server error",
//       error: error.message,
//     });
//   }
// });
router.get("/user/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId)
       .select("-password")
  .populate("favorites", "name brand imageUrl category rating")
  .populate("recentlyUsedProducts", "name brand imageUrl category rating")
  .populate("followers", "fullName profileImage")
  .populate("following", "fullName profileImage");


    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json(user);
  } catch (error) {
    console.log("❌ GET USER ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    const uniqueName = Date.now() + path.extname(file.originalname);
    cb(null, uniqueName);
  },
});

const upload = multer({ storage });

router.put("/upload-profile-image/:id", upload.single("image"), async (req, res) => {
  try {
    const userId = req.params.id;

    if (!req.file) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    const imageUrl = `http://${req.get("host")}/uploads/${req.file.filename}`;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImage: imageUrl },
      { new: true }
    );

    res.status(200).json({
      message: "Profile image uploaded successfully",
      profileImage: updatedUser.profileImage,
      user: updatedUser,
    });
  } catch (error) {
    res.status(500).json({ message: "Upload failed", error: error.message });
  }
});

router.put("/remove-profile-image/:id", async (req, res) => {
  try {
    const userId = req.params.id;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      { profileImage: "" },
      { new: true }
    ).select("-password");

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({
      message: "Profile image removed successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.log("❌ REMOVE PROFILE IMAGE ERROR:", error);
    res.status(500).json({
      message: "Failed to remove profile image",
      error: error.message,
    });
  }
});
router.put("/update-profile/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { fullName, email, profileImage, onboarding, bio, city } = req.body;

    // Email uniqueness check
    if (email) {
      const emailTaken = await User.findOne({
        email: email.toLowerCase().trim(),
        _id: { $ne: userId },
      });
      if (emailTaken) {
        return res.status(400).json({ message: "Email already in use by another account" });
      }
    }

    const updateData = {};
    if (fullName !== undefined) updateData.fullName = fullName.trim();
    if (email !== undefined) updateData.email = email.toLowerCase().trim();
    if (profileImage !== undefined) updateData.profileImage = profileImage;
    if (onboarding !== undefined) updateData.onboarding = onboarding;
    if (bio !== undefined) updateData.bio = bio.trim();
    if (city !== undefined) updateData.city = city.trim();

    const updatedUser = await User.findByIdAndUpdate(userId, updateData, { new: true })
      .select("-password");

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ message: "Profile updated successfully", user: updatedUser });
  } catch (error) {
    console.log("❌ UPDATE PROFILE ERROR:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});
router.post("/user/:userId/collections", async (req, res) => {
  try {
    const { userId } = req.params;
    const { title, images } = req.body;

    if (!title || !title.trim()) {
      return res.status(400).json({
        message: "Collection title is required",
      });
    }

    const user = await User.findById(userId);

    if (!user) {
      return res.status(404).json({
        message: "User not found",
      });
    }

    user.collections.push({
      title: title.trim(),
      images: Array.isArray(images) ? images : [],
    });

    await user.save();

    res.status(200).json({
      message: "Collection added successfully",
      collections: user.collections,
    });
  } catch (error) {
    console.log("❌ ADD COLLECTION ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.get("/public/:id", async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select(
      "fullName profileImage onboarding collections"
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({
      id: user._id,
      fullName: user.fullName,
      profileImage: user.profileImage || "",
      skinType: user.onboarding?.skinType || "",
      skinConcerns: user.onboarding?.skinConcerns || [],
      collections: user.collections || [],
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/collection/:collectionId", async (req, res) => {
  try {
    const { collectionId } = req.params;
    const { title, userId } = req.body;

    const user = await User.findOne({ "collections._id": collectionId });
    if (!user) return res.status(404).json({ message: "Collection not found" });

    if (userId && user._id.toString() !== userId) {
      return res.status(403).json({ message: "Forbidden: not your collection" });
    }

    const collection = user.collections.id(collectionId);
    collection.title = title;
    await user.save();

    res.status(200).json({ message: "Collection updated successfully", collections: user.collections });
  } catch (error) {
    console.log("❌ UPDATE COLLECTION ERROR:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.delete("/collection/:collectionId", async (req, res) => {
  try {
    const { collectionId } = req.params;
    const { userId } = req.body;

    const user = await User.findOne({ "collections._id": collectionId });
    if (!user) return res.status(404).json({ message: "Collection not found" });

    if (userId && user._id.toString() !== userId) {
      return res.status(403).json({ message: "Forbidden: not your collection" });
    }

    const collection = user.collections.id(collectionId);
    if (!collection) return res.status(404).json({ message: "Collection not found" });

    collection.deleteOne();
    await user.save();

    res.status(200).json({ message: "Collection deleted successfully", collections: user.collections });
  } catch (error) {
    console.log("❌ DELETE COLLECTION ERROR:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});


router.get("/users", async (req, res) => {
  try {
    const users = await User.find({ role: { $ne: "admin" } })
      .select("fullName profileImage role createdAt")
      .sort({ createdAt: -1 });

    res.status(200).json(users);
  } catch (error) {
    console.log("❌ GET ALL USERS ERROR:", error);
    res.status(500).json({
      message: "Failed to fetch users",
      error: error.message,
    });
  }
});
router.post("/user/:userId/save-post/:postId", async (req, res) => {
  try {
    const { userId, postId } = req.params;

    const user = await User.findById(userId);
    const post = await GroupPost.findById(postId);

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const alreadySaved = user.savedPosts.some(
      (id) => id.toString() === postId
    );

    if (alreadySaved) {
      user.savedPosts = user.savedPosts.filter(
        (id) => id.toString() !== postId
      );

      await user.save();

      return res.status(200).json({
        message: "Post removed from saved",
        isSaved: false,
        savedPosts: user.savedPosts,
      });
    }

    user.savedPosts.push(post._id);
    await user.save();

    res.status(200).json({
      message: "Post saved successfully",
      isSaved: true,
      savedPosts: user.savedPosts,
    });
  } catch (error) {
    console.log("❌ SAVE POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.get("/user/:userId/saved-posts", async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).populate({
      path: "savedPosts",
      model: "GroupPost",
      options: { sort: { createdAt: -1 } },
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json(user.savedPosts);
  } catch (error) {
    console.log("❌ GET SAVED POSTS ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/collection/:collectionId/add-product", async (req, res) => {
  try {
    const { collectionId } = req.params;
    const { imageUrl, userId } = req.body;

    const user = await User.findOne({ "collections._id": collectionId });
    if (!user) return res.status(404).json({ message: "Collection not found" });

    if (userId && user._id.toString() !== userId) {
      return res.status(403).json({ message: "Forbidden: not your collection" });
    }

    const collection = user.collections.id(collectionId);
    if (!collection.images.includes(imageUrl)) {
      collection.images.push(imageUrl);
    }

    await user.save();
    res.status(200).json({ message: "Product added to collection", collection });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Remove product from collection ─────────────────────────────────────────
router.put("/collection/:collectionId/remove-product", async (req, res) => {
  try {
    const { collectionId } = req.params;
    const { imageUrl, userId } = req.body;

    if (!imageUrl) return res.status(400).json({ message: "imageUrl is required" });

    const user = await User.findOne({ "collections._id": collectionId });
    if (!user) return res.status(404).json({ message: "Collection not found" });

    if (userId && user._id.toString() !== userId) {
      return res.status(403).json({ message: "Forbidden: not your collection" });
    }

    const collection = user.collections.id(collectionId);
    if (!collection) return res.status(404).json({ message: "Collection not found" });

    collection.images = collection.images.filter(img => img !== imageUrl);
    await user.save();

    res.status(200).json({ message: "Product removed from collection", collection });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});
router.post("/:id/follow", async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const { currentUserId } = req.body;

    if (targetUserId === currentUserId) {
      return res.status(400).json({ message: "You cannot follow yourself" });
    }

    await User.findByIdAndUpdate(targetUserId, {
      $addToSet: { followers: currentUserId },
    });

    await User.findByIdAndUpdate(currentUserId, {
      $addToSet: { following: targetUserId },
    });

    // Notify followed user via in-app, push, and email
    User.findById(currentUserId).select("fullName").then((follower) => {
      if (follower) {
        sendNotification({
          userId: targetUserId,
          title: "New Follower 👤",
          body: `${follower.fullName} started following you`,
          type: "new_follower",
          data: { type: "new_follower", followerId: currentUserId },
        }).catch(() => {});
      }
    }).catch(() => {});

    res.json({ message: "Followed successfully" });
  } catch (error) {
    res.status(500).json({ message: "Follow failed", error: error.message });
  }
});

router.post("/:id/unfollow", async (req, res) => {
  try {
    const targetUserId = req.params.id;
    const { currentUserId } = req.body;

    await User.findByIdAndUpdate(targetUserId, {
      $pull: { followers: currentUserId },
    });

    await User.findByIdAndUpdate(currentUserId, {
      $pull: { following: targetUserId },
    });

    res.json({ message: "Unfollowed successfully" });
  } catch (error) {
    res.status(500).json({ message: "Unfollow failed", error: error.message });
  }
});
router.put("/recently-used/remove", async (req, res) => {
  try {
    const { userId, productId } = req.body;

    if (!userId || !productId) {
      return res.status(400).json({ message: "userId and productId are required" });
    }

    const user = await User.findByIdAndUpdate(
      userId,
      { $pull: { recentlyUsedProducts: productId } },
      { new: true }
    ).populate("recentlyUsedProducts", "name brand imageUrl category rating");

    if (!user) return res.status(404).json({ message: "User not found" });

    res.status(200).json(user.recentlyUsedProducts);
  } catch (error) {
    res.status(500).json({
      message: "Failed to remove recently used product",
      error: error.message,
    });
  }
});

router.post("/recently-used", async (req, res) => {
  try {
    const { userId, productId } = req.body;

    if (!userId || !productId) {
      return res.status(400).json({ message: "userId and productId are required" });
    }

    await User.findByIdAndUpdate(userId, {
      $pull: { recentlyUsedProducts: productId },
    });

    const user = await User.findByIdAndUpdate(
      userId,
      {
        $push: {
          recentlyUsedProducts: {
            $each: [productId],
            $position: 0,
            $slice: 10,
          },
        },
      },
      { new: true }
    ).populate("recentlyUsedProducts", "name brand imageUrl category rating");

    res.status(200).json(user.recentlyUsedProducts);
  } catch (error) {
    res.status(500).json({
      message: "Failed to add recently used product",
      error: error.message,
    });
  }
});
// PUT /api/auth/user/:userId/hide-store/:storeId
router.put("/user/:userId/hide-store/:storeId", async (req, res) => {
  try {
    const { userId, storeId } = req.params;

    const user = await User.findByIdAndUpdate(
      userId,
      { $addToSet: { hiddenStores: storeId } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ message: "Store hidden successfully", hiddenStores: user.hiddenStores });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET /api/auth/user/:userId/followed-stores — returns populated store objects
router.get("/user/:userId/followed-stores", async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select("followedStores")
      .populate("followedStores", "storeName logoUrl city followersCount rating");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.status(200).json(user.followedStores);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET /api/auth/user/:userId/hidden-stores — returns populated store objects
router.get("/user/:userId/hidden-stores", async (req, res) => {
  try {
    const user = await User.findById(req.params.userId)
      .select("hiddenStores")
      .populate("hiddenStores", "storeName logoUrl city rating");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.status(200).json(user.hiddenStores);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/auth/user/:userId/unhide-store/:storeId
router.put("/user/:userId/unhide-store/:storeId", async (req, res) => {
  try {
    const { userId, storeId } = req.params;

    const user = await User.findByIdAndUpdate(
      userId,
      { $pull: { hiddenStores: storeId } },
      { new: true }
    );

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({ message: "Store unhidden successfully", hiddenStores: user.hiddenStores });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});
router.get("/product/:productId/recently-used-users", async (req, res) => {
  try {
    const { productId } = req.params;

    const users = await User.find({
      recentlyUsedProducts: productId,
    }).select("fullName profileImage");

    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch users",
      error: error.message,
    });
  }
});
// ── Change password ────────────────────────────────────────────────────────
router.put("/change-password/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      return res.status(400).json({ message: "currentPassword and newPassword are required" });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: "New password must be at least 6 characters" });
    }

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) return res.status(400).json({ message: "Current password is incorrect" });

    user.password = await bcrypt.hash(newPassword, 10);
    await user.save();

    res.status(200).json({ message: "Password changed successfully" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Delete account ─────────────────────────────────────────────────────────
router.delete("/delete-account/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findByIdAndDelete(userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    res.status(200).json({ message: "Account deleted successfully" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Scan privacy ───────────────────────────────────────────────────────────
router.get("/scan-privacy/:userId", async (req, res) => {
  try {
    const user = await User.findById(req.params.userId).select("scanPrivacy");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.status(200).json(user.scanPrivacy || {
      allowScanHistory: true,
      allowPersonalizedRecommendations: true,
      allowImageStorage: true,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.put("/scan-privacy/:userId", async (req, res) => {
  try {
    const { allowScanHistory, allowPersonalizedRecommendations, allowImageStorage } = req.body;
    const user = await User.findByIdAndUpdate(
      req.params.userId,
      {
        "scanPrivacy.allowScanHistory": allowScanHistory,
        "scanPrivacy.allowPersonalizedRecommendations": allowPersonalizedRecommendations,
        "scanPrivacy.allowImageStorage": allowImageStorage,
      },
      { new: true }
    ).select("scanPrivacy");
    if (!user) return res.status(404).json({ message: "User not found" });
    res.status(200).json(user.scanPrivacy);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── POST /api/auth/forgot-password ────────────────────────────────────────────
// Generates a 6-digit OTP and sends it to the user's email.
// Always returns the same response for security (does not reveal if email exists).
router.post("/forgot-password", async (req, res) => {
  try {
    const email = (req.body.email || "").trim().toLowerCase();
    if (!email) {
      return res.status(400).json({ message: "Email is required" });
    }

    const user = await User.findOne({ email });
    if (user) {
      const otp = Math.floor(100000 + Math.random() * 900000).toString();
      const hashedOtp = await bcrypt.hash(otp, 10);

      user.resetOtp = hashedOtp;
      user.resetOtpExpires = new Date(Date.now() + 15 * 60 * 1000); // 15 min
      await user.save();

      try {
        await sendEmail({
          to: user.email,
          subject: "Reset your Skinova password",
          html: otpEmailHtml(otp),
        });
      } catch (emailErr) {
        console.error("[forgot-password] email send error:", emailErr.message);
      }
    }

    res.status(200).json({
      message: "If this email is registered, we sent reset instructions.",
    });
  } catch (err) {
    console.error("forgot-password error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
});

// ── POST /api/auth/reset-password ─────────────────────────────────────────────
// Verifies the OTP and updates the password.
router.post("/reset-password", async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;

    if (!email || !otp || !newPassword) {
      return res.status(400).json({ message: "Email, OTP, and new password are required" });
    }
    if (newPassword.length < 6) {
      return res.status(400).json({ message: "Password must be at least 6 characters" });
    }

    const user = await User.findOne({ email: email.trim().toLowerCase() });
    if (!user || !user.resetOtp || !user.resetOtpExpires) {
      return res.status(400).json({ message: "Invalid or expired reset code" });
    }
    if (user.resetOtpExpires < new Date()) {
      user.resetOtp = null;
      user.resetOtpExpires = null;
      await user.save();
      return res.status(400).json({ message: "Reset code has expired. Please request a new one." });
    }

    const isValid = await bcrypt.compare(otp.trim(), user.resetOtp);
    if (!isValid) {
      return res.status(400).json({ message: "Incorrect reset code. Please try again." });
    }

    user.password = await bcrypt.hash(newPassword, 10);
    user.resetOtp = null;
    user.resetOtpExpires = null;
    await user.save();

    res.status(200).json({ message: "Password reset successfully" });
  } catch (err) {
    console.error("reset-password error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
});

// ── POST /api/auth/google ──────────────────────────────────────────────────────
// Verify a Google idToken, create the user if they don't exist, return session data.
router.post("/google", async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) {
      return res.status(400).json({ message: "idToken is required" });
    }

    if (!process.env.GOOGLE_CLIENT_ID) {
      console.error("[google auth] GOOGLE_CLIENT_ID env var not set");
      return res.status(500).json({ message: "Google Sign-In is not configured" });
    }

    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
    let payload;
    try {
      const ticket = await client.verifyIdToken({
        idToken,
        audience: process.env.GOOGLE_CLIENT_ID,
      });
      payload = ticket.getPayload();
    } catch {
      return res.status(401).json({ message: "Invalid Google token" });
    }

    const { email, name, sub: googleId } = payload;
    if (!email) {
      return res.status(400).json({ message: "Google account has no email" });
    }

    let user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      user = new User({
        fullName: name || email.split("@")[0],
        email: email.toLowerCase(),
        password: await bcrypt.hash(crypto.randomBytes(32).toString("hex"), 10),
        googleId,
        profileProvider: "google",
        role: "user",
      });
      await user.save();
    } else if (!user.googleId) {
      user.googleId = googleId;
      if (user.profileProvider === "email") user.profileProvider = "google";
      await user.save();
    }

    if (user.isActive === false) {
      return res.status(403).json({
        message: "Your account has been deactivated. Please contact Skinova support.",
      });
    }

    res.status(200).json({
      message: "Login successful",
      userId: user._id,
      fullName: user.fullName,
      email: user.email,
      role: user.role,
    });
  } catch (err) {
    console.error("google auth error:", err.message);
    res.status(500).json({ message: "Server error" });
  }
});

module.exports = router;