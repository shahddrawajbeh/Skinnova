const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const adminMiddleware = require("../../middleware/adminMiddleware");
const Group = require("../../models/group");
const GroupMembership = require("../../models/GroupMembership");
const GroupPost = require("../../models/group_posts");
const User = require("../../models/user");

// Image upload
const groupUploadDir = path.join(__dirname, "../../uploads/groups");
if (!fs.existsSync(groupUploadDir)) fs.mkdirSync(groupUploadDir, { recursive: true });

const groupStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, groupUploadDir),
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `group-${Date.now()}${ext}`);
  },
});
const uploadGroupImage = multer({ storage: groupStorage });

router.post("/upload-image", adminMiddleware, uploadGroupImage.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "No image uploaded" });
  const imageUrl = `${req.protocol}://${req.get("host")}/uploads/groups/${req.file.filename}`;
  res.json({ imageUrl });
});

// GET all groups (admin sees all including inactive)
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { search, groupType, page = 1, limit = 50 } = req.query;
    const query = {};
    if (groupType) query.groupType = groupType;
    if (search) {
      query.$or = [
        { title: { $regex: search, $options: "i" } },
        { slug: { $regex: search, $options: "i" } },
        { categoryKey: { $regex: search, $options: "i" } },
        { description: { $regex: search, $options: "i" } },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [groups, total] = await Promise.all([
      Group.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      Group.countDocuments(query),
    ]);
    res.json({ groups, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single group
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id);
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// POST create group
router.post("/", adminMiddleware, async (req, res) => {
  try {
    const { title, slug, coverImage, profileImage, description, groupType, categoryKey } = req.body;
    const group = new Group({ title, slug, coverImage, profileImage, description, groupType, categoryKey });
    await group.save();
    res.status(201).json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT update group
router.put("/:id", adminMiddleware, async (req, res) => {
  try {
    const { title, slug, coverImage, profileImage, description, groupType, categoryKey, isActive } = req.body;
    const group = await Group.findByIdAndUpdate(
      req.params.id,
      { title, slug, coverImage, profileImage, description, groupType, categoryKey, isActive },
      { new: true, runValidators: true }
    );
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json(group);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle active
router.patch("/:id/toggle-active", adminMiddleware, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id).select("isActive");
    if (!group) return res.status(404).json({ message: "Group not found" });
    group.isActive = !group.isActive;
    await group.save();
    res.json({ isActive: group.isActive });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE group
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const group = await Group.findByIdAndDelete(req.params.id);
    if (!group) return res.status(404).json({ message: "Group not found" });
    res.json({ message: "Group deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// ── Sub-resources ────────────────────────────────────────────────────────────

// GET /:id/posts — all posts connected to this group (by groupId or groupSlug)
router.get("/:id/posts", adminMiddleware, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id).select("slug title");
    if (!group) return res.status(404).json({ message: "Group not found" });

    const posts = await GroupPost.find({
      $or: [
        { groupId: group._id },
        { groupSlug: group.slug },
      ],
    })
      .sort({ createdAt: -1 })
      .limit(200);

    res.json({ posts, groupTitle: group.title, groupSlug: group.slug });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET /:id/members — users who joined this group
router.get("/:id/members", adminMiddleware, async (req, res) => {
  try {
    const group = await Group.findById(req.params.id).select("title membersCount");
    if (!group) return res.status(404).json({ message: "Group not found" });

    const memberships = await GroupMembership.find({ groupId: req.params.id })
      .sort({ createdAt: -1 })
      .limit(200);

    // Fetch user details for each membership
    const userIds = memberships.map((m) => m.userId);
    const users = await User.find({ _id: { $in: userIds } })
      .select("fullName email profileImage createdAt");

    // Map userId → user for quick lookup
    const userMap = {};
    users.forEach((u) => { userMap[u._id.toString()] = u; });

    const members = memberships.map((m) => ({
      membershipId: m._id,
      userId: m.userId,
      joinedAt: m.createdAt,
      user: userMap[m.userId] || null,
    }));

    res.json({
      members,
      total: members.length,
      groupTitle: group.title,
      storedMembersCount: group.membersCount,
    });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
