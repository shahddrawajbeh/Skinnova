const express = require("express");
const router = express.Router();
const adminMiddleware = require("../../middleware/adminMiddleware");
const GroupPost = require("../../models/group_posts");

// GET all group posts (admin sees all including hidden/rejected)
router.get("/", adminMiddleware, async (req, res) => {
  try {
    const { search, postType, groupSlug, productId, approvalStatus, page = 1, limit = 50 } = req.query;
    const query = {};
    if (postType) query.postType = postType;
    if (groupSlug) query.groupSlug = groupSlug;
    if (productId) query.productId = productId;
    if (approvalStatus) query.approvalStatus = approvalStatus;
    if (search) {
      query.$or = [
        { userName: { $regex: search, $options: "i" } },
        { content: { $regex: search, $options: "i" } },
        { productName: { $regex: search, $options: "i" } },
        { groupTitle: { $regex: search, $options: "i" } },
        { groupSlug: { $regex: search, $options: "i" } },
        { tag: { $regex: search, $options: "i" } },
      ];
    }
    const skip = (parseInt(page) - 1) * parseInt(limit);
    const [posts, total] = await Promise.all([
      GroupPost.find(query).sort({ createdAt: -1 }).skip(skip).limit(parseInt(limit)),
      GroupPost.countDocuments(query),
    ]);
    res.json({ posts, total, page: parseInt(page) });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET single post
router.get("/:id", adminMiddleware, async (req, res) => {
  try {
    const post = await GroupPost.findById(req.params.id);
    if (!post) return res.status(404).json({ message: "Post not found" });
    res.json(post);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH toggle hidden
router.patch("/:id/toggle-hidden", adminMiddleware, async (req, res) => {
  try {
    const post = await GroupPost.findById(req.params.id).select("isHidden");
    if (!post) return res.status(404).json({ message: "Post not found" });
    post.isHidden = !post.isHidden;
    await post.save();
    res.json({ isHidden: post.isHidden });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PATCH approval status
router.patch("/:id/approval-status", adminMiddleware, async (req, res) => {
  try {
    const { approvalStatus } = req.body;
    const post = await GroupPost.findByIdAndUpdate(
      req.params.id,
      { approvalStatus },
      { new: true, runValidators: true }
    );
    if (!post) return res.status(404).json({ message: "Post not found" });
    res.json(post);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// DELETE post
router.delete("/:id", adminMiddleware, async (req, res) => {
  try {
    const post = await GroupPost.findByIdAndDelete(req.params.id);
    if (!post) return res.status(404).json({ message: "Post not found" });
    res.json({ message: "Post deleted" });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;
