const express = require("express");
const GroupPost = require("../models/group_posts");
const Group = require("../models/group");
const Product = require("../models/product");
const multer = require("multer");
const path = require("path");
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "uploads/");
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + path.extname(file.originalname));
  },
});

const upload = multer({ storage });
const router = express.Router();

router.post("/review", async (req, res) => {
  try {
    const {
      userId,
      userName,
      userAvatar,
      tag,
      content,
      images,
      productId,
      productName,
      productImage,
      repurchase,
      improvedSkin,
      wasGift,
      adverseReaction,
      texture,
      usageWeeks,

      rating,
    } = req.body;

    const newPost = new GroupPost({
      userId,
      userName,
      userAvatar: userAvatar || "",
      tag: tag || "Sensitive",
      postType: "review",
      content: content || "",
      images: images || [],
      productId: productId || null,
      productName: productName || "",
      productImage: productImage || "",
      rating: rating ?? 0,
      timeText: "Just now",
      isEdited: false,
      repurchase: repurchase ?? null,
improvedSkin: improvedSkin ?? null,
wasGift: wasGift ?? null,
adverseReaction: adverseReaction ?? null,
texture: texture || "",
usageWeeks: usageWeeks || "",
    });

    await newPost.save();

    res.status(201).json({
      message: "Review post added successfully",
      post: newPost,
    });
  } catch (error) {
    console.log("ADD REVIEW POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/question", async (req, res) => {
  try {
    const {
      userId,
      userName,
      userAvatar,
      content,
      productId,
      productName,
      productImage,
      groupId,
      groupTitle,
      groupSlug,
    } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ message: "Question content is required" });
    }

    const newPost = new GroupPost({
      userId,
      userName,
      userAvatar: userAvatar || "",
      postType: "question",
      content: content.trim(),
      productId: productId || null,
      productName: productName || "",
      productImage: productImage || "",
      groupId: groupId || null,
      groupTitle: groupTitle || "",
      groupSlug: groupSlug || "",
      timeText: "Just now",
      isEdited: false,
    });

    await newPost.save();

    res.status(201).json({
      message: "Question post added successfully",
      post: newPost,
    });
  } catch (error) {
    console.log("ADD QUESTION POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.get("/product-category-discussion/:groupSlug", async (req, res) => {
  try {
    const groupSlug = req.params.groupSlug.trim().toLowerCase();

    const posts = await GroupPost.find({
      groupSlug: groupSlug,
    }).sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch product category discussion posts",
      error: error.message,
    });
  }
});
router.get("/group/:groupSlug", async (req, res) => {
  try {
    const groupSlug = req.params.groupSlug.trim().toLowerCase();

    const group = await Group.findOne({ slug: groupSlug, isActive: true });

    if (!group) {
      return res.status(404).json({ message: "Group not found" });
    }

    const key = (group.categoryKey || group.title || group.slug)
      .toLowerCase()
      .trim();

    let productFilter = {};

    if (group.groupType === "skin_type" || group.groupType === "skin_types") {
      productFilter = {
        "recommendedFor.skinTypes": { $regex: key, $options: "i" },
      };
    } else if (group.groupType === "skin_concerns") {
      productFilter = {
        "recommendedFor.concerns": { $regex: key, $options: "i" },
      };
    } else if (group.groupType === "skin_tones") {
      productFilter = {
        "recommendedFor.skinTones": { $regex: key, $options: "i" },
      };
    }

    const relatedProducts = await Product.find(productFilter).select("_id name");

    const relatedProductIds = relatedProducts.map((p) => p._id);
    const relatedProductNames = relatedProducts.map((p) => p.name);

    const posts = await GroupPost.find({
      $or: [
        { groupSlug: group.slug },

        { productId: { $in: relatedProductIds } },
        { productName: { $in: relatedProductNames } },

        { content: { $regex: key, $options: "i" } },
        { productName: { $regex: key, $options: "i" } },
        { tag: { $regex: key, $options: "i" } },
      ],
    }).sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch related group posts",
      error: error.message,
    });
  }
});
router.get("/product-review-posts/:productId", async (req, res) => {
  try {
    const posts = await GroupPost.find({
      productId: req.params.productId,
      postType: "review",
    }).sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch product review posts",
      error: error.message,
    });
  }
});
router.get("/medication-discussion/:groupSlug", async (req, res) => {
  try {
    const groupSlug = req.params.groupSlug.trim().toLowerCase();

    const posts = await GroupPost.find({
      groupSlug: groupSlug,
    }).sort({ createdAt: -1 });

    res.status(200).json(posts);
  } catch (error) {
    res.status(500).json({
      message: "Failed to fetch medication discussion posts",
      error: error.message,
    });
  }
});
router.get("/", async (req, res) => {
  try {
    const posts = await GroupPost.find().sort({ createdAt: -1 });
    res.status(200).json(posts);
  } catch (error) {
    console.log("GET POSTS ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});


router.delete("/:id", async (req, res) => {
  try {
    const deletedPost = await GroupPost.findByIdAndDelete(req.params.id);

    if (!deletedPost) {
      return res.status(404).json({ message: "Post not found" });
    }

    res.status(200).json({
      message: "Post deleted successfully",
    });
  } catch (error) {
    console.log("DELETE POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

router.put("/:id/like", async (req, res) => {
  try {
    const { userId } = req.body;

    const post = await GroupPost.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const alreadyLiked = post.likes.includes(userId);

    if (alreadyLiked) {
      post.likes = post.likes.filter((id) => id !== userId);
    } else {
      post.likes.push(userId);
    }

    await post.save();

    res.status(200).json({
      message: alreadyLiked ? "Post unliked" : "Post liked",
      likes: post.likes,
      likesCount: post.likes.length,
    });
  } catch (error) {
    console.log("LIKE POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/:id/comments", async (req, res) => {
  try {
const {
  userId,
  userName,
  userAvatar,
  comment,
  parentCommentId,
  replyToUserName,
} = req.body;
    if (!comment || !comment.trim()) {
      return res.status(400).json({ message: "Comment is required" });
    }

    const post = await GroupPost.findById(req.params.id);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

  const newComment = {
  userId,
  userName,
  userAvatar: userAvatar || "",
  comment: comment.trim(),
  parentCommentId: parentCommentId || null,
  replyToUserName: replyToUserName || "",
  createdAt: new Date(),
    likes: [],
};

    post.comments.push(newComment);
    await post.save();

    res.status(201).json({
      message: "Comment added successfully",
      comments: post.comments,
      commentsCount: post.comments.length,
    });
  } catch (error) {
    console.log("ADD COMMENT ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.delete("/:postId/comments/:commentId", async (req, res) => {
  try {
    const post = await GroupPost.findById(req.params.postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    post.comments = post.comments.filter(
      (c) => c._id.toString() !== req.params.commentId
    );

    await post.save();

    res.status(200).json({
      message: "Comment deleted successfully",
      comments: post.comments,
      commentsCount: post.comments.length,
    });
  } catch (error) {
    console.log("DELETE COMMENT ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/:postId/comments/:commentId/like", async (req, res) => {
  try {
    const { userId } = req.body;

    const post = await GroupPost.findById(req.params.postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const comment = post.comments.id(req.params.commentId);
    if (!comment) {
      return res.status(404).json({ message: "Comment not found" });
    }

    const alreadyLiked = comment.likes.includes(userId);

    if (alreadyLiked) {
      comment.likes = comment.likes.filter((id) => id !== userId);
    } else {
      comment.likes.push(userId);
    }

    await post.save();

    res.status(200).json({
      message: alreadyLiked ? "Comment unliked" : "Comment liked",
      likes: comment.likes,
      likesCount: comment.likes.length,
      comments: post.comments,
    });
  } catch (error) {
    console.log("LIKE COMMENT ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/:postId/comments/:commentId", async (req, res) => {
  try {
    const { comment } = req.body;

    if (!comment || !comment.trim()) {
      return res.status(400).json({ message: "Comment is required" });
    }

    const post = await GroupPost.findById(req.params.postId);
    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    const targetComment = post.comments.id(req.params.commentId);
    if (!targetComment) {
      return res.status(404).json({ message: "Comment not found" });
    }

    targetComment.comment = comment.trim();

    await post.save();

    res.status(200).json({
      message: "Comment updated successfully",
      comments: post.comments,
    });
  } catch (error) {
    console.log("EDIT COMMENT ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.put("/:id", async (req, res) => {
  try {
    const { content } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ message: "Content is required" });
    }

    const post = await GroupPost.findById(req.params.id);

    if (!post) {
      return res.status(404).json({ message: "Post not found" });
    }

    post.content = content.trim();
    post.isEdited = true;

    await post.save();

    res.status(200).json({
      message: "Post updated successfully",
      post,
    });
  } catch (error) {
    console.log("EDIT POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/update", async (req, res) => {
  try {
    const {
      userId,
      userName,
      userAvatar,
      content,
      productId,
      productName,
      productImage,
      groupId,
      groupTitle,
      groupSlug,
    } = req.body;

    if (!content || !content.trim()) {
      return res.status(400).json({ message: "Update content is required" });
    }

    const newPost = new GroupPost({
      userId,
      userName,
      userAvatar: userAvatar || "",
      postType: "update",
      content: content.trim(),
      productId: productId || null,
      productName: productName || "",
      productImage: productImage || "",
      groupId: groupId || null,
      groupTitle: groupTitle || "",
      groupSlug: groupSlug || "",
      timeText: "Just now",
      isEdited: false,
    });

    await newPost.save();

    res.status(201).json({
      message: "Update post added successfully",
      post: newPost,
    });
  } catch (error) {
    console.log("ADD UPDATE POST ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.post("/upload", upload.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    res.status(200).json({
      imageUrl: `http://192.168.1.22:5000/uploads/${req.file.filename}`,
    });
  } catch (error) {
    res.status(500).json({
      message: "Upload failed",
      error: error.message,
    });
  }
});
module.exports = router;