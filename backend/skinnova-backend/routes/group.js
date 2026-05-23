const User = require("../models/user");
const mongoose = require("mongoose");
const groupMembershipSchema = new mongoose.Schema(
  {
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Group",
      required: true,
    },
    userId: {
      type: String,
      required: true,
      trim: true,
    },
  },
  { timestamps: true }
);

groupMembershipSchema.index({ groupId: 1, userId: 1 }, { unique: true });

const GroupMembership = mongoose.model("GroupMembership", groupMembershipSchema);




const express = require("express");
const Group = require("../models/group");
const Product = require("../models/product");

const router = express.Router();

// Create group
router.post("/", async (req, res) => {
  try {
    const {
      title,
      slug,
      coverImage,
      profileImage,
      description,
       groupType,
      categoryKey,
      membersCount,
    } = req.body;

    const existingGroup = await Group.findOne({ slug: slug.trim().toLowerCase() });
    if (existingGroup) {
      return res.status(400).json({ message: "Group already exists" });
    }

    const newGroup = new Group({
      title,
      slug: slug.trim().toLowerCase(),
      coverImage: coverImage || "",
      profileImage: profileImage || "",
      description: description || "",
      categoryKey: categoryKey ? categoryKey.trim().toLowerCase() : "",
      membersCount: membersCount || 0,
       groupType: groupType || "product_categories",
    });

    await newGroup.save();

    res.status(201).json({
      message: "Group created successfully",
      group: newGroup,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to create group",
      error: error.message,
    });
  }
});

// Get all groups
router.get("/", async (req, res) => {
  try {
    const groups = await Group.find({ isActive: true }).sort({ createdAt: -1 });
    res.status(200).json(groups);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch groups",
      error: error.message,
    });
  }
});
router.get("/type/:groupType", async (req, res) => {
  try {
    const groups = await Group.find({
      groupType: req.params.groupType,
      isActive: true,
    }).sort({ createdAt: -1 });

    res.status(200).json(groups);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch groups by type",
      error: error.message,
    });
  }
});
router.get("/:slug/people", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();
    const group = await Group.findOne({ slug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const key = (group.categoryKey || group.title || "").toLowerCase().trim();

    const users = await User.find({
      role: { $ne: "admin" },
    }).select(
      "fullName email profileImage onboarding.skinType onboarding.skinConcerns onboarding.skinPhototype onboarding.chronicCondition onboarding.specialConditions"
    );

    const matchedUsers = users.filter((user) => {
      const onboarding = user.onboarding || {};

     if (group.groupType === "medications") {
  const chronicCondition = (onboarding.chronicCondition || "")
    .toLowerCase()
    .trim();

  const specialConditions = onboarding.specialConditions || [];

  return (
    chronicCondition.includes(key) ||
    specialConditions.some((condition) => {
      return condition.toLowerCase().trim() === key;
    })
  );
}
      if (group.groupType === "skin_types") {
        const concerns = onboarding.skinConcerns || [];

        return concerns.some((concern) => {
          return concern.toLowerCase().trim() === key;
        });
      }

      if (group.groupType === "skin_tones") {
        const userTone = (onboarding.skinPhototype || "")
          .toLowerCase()
          .trim();

        return userTone === key;
      }

      const userSkinType = (onboarding.skinType || "").toLowerCase().trim();

      return (
        userSkinType === key ||
        userSkinType === `${key} skin` ||
        userSkinType.replace(" skin", "") === key
      );
    });

    res.status(200).json(matchedUsers);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch group people",
      error: error.message,
    });
  }
});
// router.get("/:slug/people", async (req, res) => {
//   try {
//     const slug = req.params.slug.trim().toLowerCase();

//     const group = await Group.findOne({ slug, isActive: true });

//     if (!group) {
//       return res.status(404).json({ message: "Group not found" });
//     }

//     const key = (group.categoryKey || group.title || "")
//       .toLowerCase()
//       .trim();

//     const users = await User.find({
//       role: { $ne: "admin" },
// }).select(
//   "fullName email profileImage onboarding.skinType onboarding.skinConcerns onboarding.skinPhototype"
// );
//     const matchedUsers = users.filter((user) => {
//   const onboarding = user.onboarding || {};

//   if (group.groupType === "skin_types") {
//     const concerns = onboarding.skinConcerns || [];

//     return concerns.some((concern) => {
//       const userConcern = concern.toLowerCase().trim();
//       return userConcern === key;
//     });
//   }

//   if (group.groupType === "skin_tones") {
//     const userTone = (onboarding.skinPhototype || "")
//       .toLowerCase()
//       .trim();

//     return userTone === key;
//   }

//   const userSkinType = (onboarding.skinType || "")
//     .toLowerCase()
//     .trim();

//   return (
//     userSkinType === key ||
//     userSkinType === `${key} skin` ||
//     userSkinType.replace(" skin", "") === key
//   );
// });

//     res.status(200).json(matchedUsers);
//   } catch (error) {
//     res.status(500).json({
//       message: "Failed to fetch group people",
//       error: error.message,
//     });
//   }
// });
// Get single group by slug
router.get("/:slug", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();

    const group = await Group.findOne({ slug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    res.status(200).json(group);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch group",
      error: error.message,
    });
  }
});
router.get("/:slug/products", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();

    const group = await Group.findOne({ slug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const products = await Product.find({
      isPublished: true,
      category: group.categoryKey,
    }).sort({ createdAt: -1 });

    res.status(200).json(products);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch group products",
      error: error.message,
    });
  }
});
router.post("/:slug/join", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    const group = await Group.findOne({ slug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const existingMembership = await GroupMembership.findOne({
      groupId: group._id,
      userId,
    });

    if (existingMembership) {
      return res.status(200).json({
        message: "Already joined",
        isJoined: true,
      });
    }

    await GroupMembership.create({
      groupId: group._id,
      userId,
    });

    group.membersCount += 1;
    await group.save();

    res.status(200).json({
      message: "Joined successfully",
      isJoined: true,
      membersCount: group.membersCount,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to join group",
      error: error.message,
    });
  }
});
router.get("/:slug/join-status/:userId", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();
    const userId = req.params.userId;

    const group = await Group.findOne({ slug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const membership = await GroupMembership.findOne({
      groupId: group._id,
      userId,
    });

    res.status(200).json({
      isJoined: !!membership,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to check join status",
      error: error.message,
    });
  }
});
router.post("/:slug/leave", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    const group = await Group.findOne({ slug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const membership = await GroupMembership.findOne({
      groupId: group._id,
      userId,
    });

    if (!membership) {
      return res.status(200).json({
        message: "User is not a member of this group",
        isJoined: false,
      });
    }

    await GroupMembership.deleteOne({
      groupId: group._id,
      userId,
    });

    if (group.membersCount > 0) {
      group.membersCount -= 1;
      await group.save();
    }

    res.status(200).json({
      message: "Left group successfully",
      isJoined: false,
      membersCount: group.membersCount,
    });
  } catch (error) {
    res.status(500).json({
      message: "Failed to leave group",
      error: error.message,
    });
  }
});

module.exports = router;