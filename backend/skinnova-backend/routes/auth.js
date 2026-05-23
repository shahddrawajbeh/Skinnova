const express = require("express");
const bcrypt = require("bcryptjs");
const User = require("../models/user");
const multer = require("multer");
const path = require("path");
const GroupPost = require("../models/group_posts");

const router = express.Router();

router.post("/register", async (req, res) => {
  try {
    console.log("🔥 REGISTER HIT");
    console.log("BODY:", req.body);

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

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: "Incorrect password" });
    }

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
    const { fullName, email, profileImage, onboarding } = req.body;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        fullName,
        email,
        profileImage,
        onboarding,
      },
      { new: true }
    ).select("-password");

    if (!updatedUser) {
      return res.status(404).json({ message: "User not found" });
    }

    res.status(200).json({
      message: "Profile updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.log("❌ UPDATE PROFILE ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
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
    const { title } = req.body;

    const user = await User.findOne({
      "collections._id": collectionId,
    });

    if (!user) {
      return res.status(404).json({
        message: "Collection not found",
      });
    }

    const collection = user.collections.id(collectionId);

    collection.title = title;

    await user.save();

    res.status(200).json({
      message: "Collection updated successfully",
      collections: user.collections,
    });
  } catch (error) {
    console.log("❌ UPDATE COLLECTION ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.delete("/collection/:collectionId", async (req, res) => {
  try {
    const { collectionId } = req.params;

    const user = await User.findOne({
      "collections._id": collectionId,
    });

    if (!user) {
      return res.status(404).json({
        message: "Collection not found",
      });
    }

    const collection = user.collections.id(collectionId);

    if (!collection) {
      return res.status(404).json({
        message: "Collection not found",
      });
    }

    collection.deleteOne();

    await user.save();

    res.status(200).json({
      message: "Collection deleted successfully",
      collections: user.collections,
    });
  } catch (error) {
    console.log("❌ DELETE COLLECTION ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
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
    const { imageUrl } = req.body;

    const user = await User.findOne({ "collections._id": collectionId });

    if (!user) {
      return res.status(404).json({ message: "Collection not found" });
    }

    const collection = user.collections.id(collectionId);

    if (!collection.images.includes(imageUrl)) {
      collection.images.push(imageUrl);
    }

    await user.save();

    res.status(200).json({
      message: "Product added to collection",
      collection,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
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
module.exports = router;