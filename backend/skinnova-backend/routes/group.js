const User = require("../models/user");
const express = require("express");
const Group = require("../models/group");
const GroupMembership = require("../models/GroupMembership");
const Product = require("../models/product");
const GroupPost = require("../models/group_posts");

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

router.get("/:slug/members", async (req, res) => {
  try {
    const slug = req.params.slug.trim().toLowerCase();
    const { userId } = req.query;

    const group = await Group.findOne({ slug, isActive: true });
    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const memberships = await GroupMembership.find({ groupId: group._id }).sort({
      createdAt: -1,
    });
    const userIds = memberships.map((m) => m.userId);

    const users = await User.find({ _id: { $in: userIds } }).select(
      "fullName profileImage following followers"
    );
    const usersById = {};
    users.forEach((u) => {
      usersById[u._id.toString()] = u;
    });

    let requestingUser = null;
    if (userId) {
      requestingUser = await User.findById(userId).select("following followers");
    }

    const members = memberships
      .map((m) => {
        const user = usersById[m.userId];
        if (!user) return null;

        const userIdStr = user._id.toString();
        const isFollowedByMe = requestingUser
          ? requestingUser.following.some((id) => id.toString() === userIdStr)
          : false;
        const isMutual =
          isFollowedByMe && requestingUser
            ? requestingUser.followers.some((id) => id.toString() === userIdStr)
            : false;

        return {
          _id: userIdStr,
          fullName: user.fullName,
          profileImage: user.profileImage,
          joinedAt: m.createdAt,
          isFollowedByMe,
          isMutual,
        };
      })
      .filter(Boolean);

    res.status(200).json(members);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch group members",
      error: error.message,
    });
  }
});

router.get("/my-groups/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const memberships = await GroupMembership.find({ userId }).sort({ createdAt: -1 });
    const groupIds = memberships.map((m) => m.groupId);

    const groups = await Group.find({ _id: { $in: groupIds }, isActive: true });

    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);

    const result = await Promise.all(
      groups.map(async (group) => {
        const hasNewActivity = await GroupPost.exists({
          groupId: group._id,
          isHidden: { $ne: true },
          approvalStatus: { $ne: "rejected" },
          createdAt: { $gte: since },
        });

        return {
          ...group.toObject(),
          hasNewActivity: !!hasNewActivity,
        };
      })
    );

    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch your groups",
      error: error.message,
    });
  }
});

router.get("/friends-activity/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select("following");
    if (!user || !user.following || user.following.length === 0) {
      return res.status(200).json([]);
    }

    const since = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const followingIds = user.following.map((id) => id.toString());

    const memberships = await GroupMembership.find({
      userId: { $in: followingIds },
      createdAt: { $gte: since },
    }).sort({ createdAt: -1 });

    if (memberships.length === 0) {
      return res.status(200).json([]);
    }

    const friendIds = [...new Set(memberships.map((m) => m.userId))];
    const groupIds = [...new Set(memberships.map((m) => m.groupId.toString()))];

    const friends = await User.find({ _id: { $in: friendIds } }).select(
      "fullName profileImage"
    );
    const friendsById = {};
    friends.forEach((f) => {
      friendsById[f._id.toString()] = f;
    });

    const groups = await Group.find({ _id: { $in: groupIds } });
    const groupsById = {};
    groups.forEach((g) => {
      groupsById[g._id.toString()] = g;
    });

    const result = await Promise.all(
      memberships.map(async (m) => {
        const friend = friendsById[m.userId];
        const group = groupsById[m.groupId.toString()];
        if (!friend || !group) return null;

        const newPostsCount = await GroupPost.countDocuments({
          groupId: group._id,
          isHidden: { $ne: true },
          approvalStatus: { $ne: "rejected" },
          createdAt: { $gte: m.createdAt },
        });

        return {
          friendId: friend._id.toString(),
          friendName: friend.fullName,
          friendAvatar: friend.profileImage,
          groupSlug: group.slug,
          groupTitle: group.title,
          activityAt: m.createdAt,
          newPostsCount,
        };
      })
    );

    res.status(200).json(result.filter(Boolean));
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch friends activity",
      error: error.message,
    });
  }
});

router.get("/suggested/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findById(userId).select("onboarding");
    const onboarding = (user && user.onboarding) || {};

    const memberships = await GroupMembership.find({ userId });
    const joinedGroupIds = memberships.map((m) => m.groupId.toString());

    const groups = await Group.find({
      _id: { $nin: joinedGroupIds },
      isActive: true,
    });

    const matched = [];
    const unmatched = [];

    groups.forEach((group) => {
      const key = (group.categoryKey || group.title || "").toLowerCase().trim();
      let isMatch = false;

      if (group.groupType === "medications") {
        const chronicCondition = (onboarding.chronicCondition || "").toLowerCase().trim();
        const specialConditions = onboarding.specialConditions || [];

        isMatch =
          (chronicCondition && chronicCondition.includes(key)) ||
          specialConditions.some((c) => c.toLowerCase().trim() === key);
      } else if (group.groupType === "skin_types") {
        const concerns = onboarding.skinConcerns || [];
        isMatch = concerns.some((c) => c.toLowerCase().trim() === key);
      } else if (group.groupType === "skin_tones") {
        const userTone = (onboarding.skinPhototype || "").toLowerCase().trim();
        isMatch = userTone === key;
      } else {
        const userSkinType = (onboarding.skinType || "").toLowerCase().trim();
        isMatch =
          userSkinType === key ||
          userSkinType === `${key} skin` ||
          userSkinType.replace(" skin", "") === key;
      }

      if (isMatch) {
        matched.push(group);
      } else {
        unmatched.push(group);
      }
    });

    matched.sort((a, b) => (b.membersCount || 0) - (a.membersCount || 0));
    unmatched.sort((a, b) => (b.membersCount || 0) - (a.membersCount || 0));

    res.status(200).json([...matched, ...unmatched]);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch suggested groups",
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