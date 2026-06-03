const express = require("express");
const Store = require("../models/store");
const User = require("../models/user");
const Order = require("../models/order");
const StoreProduct = require("../models/storeProduct");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { sendPushToRole, sendPushNotification } = require("../helpers/sendPushNotification");

const router = express.Router();
const storeUploadDir = path.join(__dirname, "../uploads/stores");

if (!fs.existsSync(storeUploadDir)) {
  fs.mkdirSync(storeUploadDir, { recursive: true });
}

const storeStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, storeUploadDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    cb(null, `store-${Date.now()}${ext}`);
  },
});

const uploadStoreImage = multer({ storage: storeStorage });

// Separate multer for verification documents (PDF + images)
const verifyDocDir = path.join(__dirname, "../uploads/verification-docs");
if (!fs.existsSync(verifyDocDir)) fs.mkdirSync(verifyDocDir, { recursive: true });
const uploadVerifyDoc = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => cb(null, verifyDocDir),
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname);
      cb(null, `doc-${Date.now()}${ext}`);
    },
  }),
  fileFilter: (req, file, cb) => {
    const allowed = [".jpg", ".jpeg", ".png", ".pdf"];
    const ext = path.extname(file.originalname).toLowerCase();
    cb(null, allowed.includes(ext));
  },
});

// ── Public image upload (no storeId required, used before store is created) ──
router.post("/upload-image", uploadStoreImage.single("image"), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "No image uploaded" });
  const imageUrl = `${req.protocol}://${req.get("host")}/uploads/stores/${req.file.filename}`;
  res.json({ imageUrl });
});

// ── Upload verification document ──────────────────────────────────────────────
router.post("/upload-document", uploadVerifyDoc.single("document"), (req, res) => {
  if (!req.file) return res.status(400).json({ message: "No document uploaded" });
  const docUrl = `${req.protocol}://${req.get("host")}/uploads/verification-docs/${req.file.filename}`;
  res.json({ documentUrl: docUrl });
});

// GET all stores — public: only approved + active stores are visible
router.get("/", async (req, res) => {
  try {
    const stores = await Store.find({ approvalStatus: "approved", isActive: true })
      .populate("sellerId", "fullName email")
      .sort({ createdAt: -1 });

    res.status(200).json(stores);
  } catch (error) {
    console.log("❌ GET STORES ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
router.get("/seller/:sellerId", async (req, res) => {
  try {
    const store = await Store.findOne({
      sellerId: req.params.sellerId,
    });

    if (!store) {
      return res.status(404).json({
        message: "No store found for this seller",
      });
    }

    res.status(200).json(store);
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// ── Admin: get all unverified stores ─────────────────────────────────────────
router.get("/admin/unverified", async (req, res) => {
  try {
    const stores = await Store.find({ isVerified: false })
      .populate("sellerId", "fullName email phone")
      .sort({ createdAt: -1 });
    res.status(200).json(stores);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Admin: get all verified stores ───────────────────────────────────────────
router.get("/admin/verified", async (req, res) => {
  try {
    const stores = await Store.find({ isVerified: true })
      .populate("sellerId", "fullName email")
      .populate("verifiedBy", "fullName")
      .sort({ verifiedAt: -1 });
    res.status(200).json(stores);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Admin: verify a store ─────────────────────────────────────────────────────
router.put("/:id/verify", async (req, res) => {
  try {
    const { adminId, verificationLevel } = req.body;
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      {
        isVerified: true,
        verifiedAt: new Date(),
        verifiedBy: adminId || null,
        verificationLevel: verificationLevel || "standard",
      },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.status(200).json({ message: "Store verified successfully", store });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Admin: remove store verification ─────────────────────────────────────────
router.put("/:id/unverify", async (req, res) => {
  try {
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      {
        isVerified: false,
        verifiedAt: null,
        verifiedBy: null,
        verificationLevel: "standard",
      },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.status(200).json({ message: "Store verification removed", store });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET all pending store reviews (admin)
router.get("/reviews/pending", async (req, res) => {
  try {
    const stores = await Store.find({ "reviews.status": "pending" }).populate(
      "reviews.userId",
      "fullName"
    );
    const pending = [];
    for (const store of stores) {
      for (const review of store.reviews) {
        if (review.status === "pending") {
          const populatedName =
            review.userId &&
            typeof review.userId === "object" &&
            review.userId.fullName
              ? review.userId.fullName.trim()
              : "";
          const resolvedName =
            review.userName && review.userName.trim()
              ? review.userName.trim()
              : populatedName || "Customer";

          pending.push({
            storeId: store._id,
            storeName: store.storeName,
            reviewId: review._id,
            userId: review.userId,
            userName: resolvedName,
            rating: review.rating,
            comment: review.comment,
            createdAt: review.createdAt,
            status: review.status,
          });
        }
      }
    }
    res.status(200).json(pending);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// Approve a store review (admin)
router.put("/reviews/:storeId/:reviewId/approve", async (req, res) => {
  try {
    const store = await Store.findById(req.params.storeId);
    if (!store) return res.status(404).json({ message: "Store not found" });

    const review = store.reviews.id(req.params.reviewId);
    if (!review) return res.status(404).json({ message: "Review not found" });

    review.status = "approved";

    const approvedReviews = store.reviews.filter((r) => r.status === "approved");
    store.rating =
      approvedReviews.length > 0
        ? approvedReviews.reduce((sum, r) => sum + r.rating, 0) / approvedReviews.length
        : 0;

    await store.save();
    res.status(200).json({ message: "Review approved", store });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// Reject a store review (admin)
router.put("/reviews/:storeId/:reviewId/reject", async (req, res) => {
  try {
    const store = await Store.findById(req.params.storeId);
    if (!store) return res.status(404).json({ message: "Store not found" });

    const review = store.reviews.id(req.params.reviewId);
    if (!review) return res.status(404).json({ message: "Review not found" });

    review.status = "rejected";
    await store.save();
    res.status(200).json({ message: "Review rejected" });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET approved reviews for a store (seller view)
router.get("/:id/reviews", async (req, res) => {
  try {
    const store = await Store.findById(req.params.id).populate(
      "reviews.userId",
      "fullName profileImage"
    );
    if (!store) return res.status(404).json({ message: "Store not found" });

    const approved = store.reviews
      .filter((r) => r.status === "approved")
      .sort((a, b) => b.createdAt - a.createdAt)
      .map((r) => ({
        _id: r._id,
        userId: r.userId,
        userName: r.userName,
        rating: r.rating,
        comment: r.comment,
        createdAt: r.createdAt,
      }));

    res.status(200).json(approved);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET single store by id
router.get("/:id", async (req, res) => {
  try {
    const store = await Store.findById(req.params.id)
      .populate("sellerId", "fullName email")
      .populate("reviews.userId", "fullName");

    if (!store) {
      return res.status(404).json({ message: "Store not found" });
    }

    res.status(200).json(store);
  } catch (error) {
    console.log("❌ GET STORE DETAILS ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// CREATE new store
router.post("/", async (req, res) => {
  try {
    const {
      sellerId,
      storeName,
      logoUrl,
      coverImageUrl,
      description,
      city,
      address,
      phone,
      deliveryInfo,
      returnPolicy,
    } = req.body;

    if (!sellerId || !storeName || !city) {
      return res.status(400).json({
        message: "sellerId, storeName, and city are required",
      });
    }

    const storeData = {
      sellerId,
      storeName,
      logoUrl,
      coverImageUrl,
      description,
      city,
      address,
      phone,
    };

    if (deliveryInfo) storeData.deliveryInfo = deliveryInfo;
    if (returnPolicy) storeData.returnPolicy = returnPolicy;

    const store = await Store.create(storeData);
    res.status(201).json(store);
  } catch (error) {
    console.log("❌ CREATE STORE ERROR:", error);
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});
// Safe UPDATE store — only seller-editable fields
router.put("/:id", async (req, res) => {
  try {
    const ALLOWED_SCALAR = [
      "storeName", "description", "city", "address", "phone",
      "logoUrl", "coverImageUrl", "isActive", "returnPolicy",
      "responseTime", "shippingTime",
      "deliveryInfo.standardFee", "deliveryInfo.expressFee", "deliveryInfo.freeDeliveryOver",
      "deliveryInfo.methods",
    ];
    const ALLOWED_ARRAYS = [
      "deliveryInfo.areas", "deliveryInfo.workingHours",
      "deliveryInfo.deliverySteps", "galleryImages",
    ];

    const update = {};
    for (const key of ALLOWED_SCALAR) {
      if (req.body[key] !== undefined) update[key] = req.body[key];
    }
    for (const key of ALLOWED_ARRAYS) {
      if (req.body[key] !== undefined) {
        if (!Array.isArray(req.body[key])) continue;
        update[key] = req.body[key];
      }
    }

    const store = await Store.findByIdAndUpdate(
      req.params.id,
      { $set: update },
      { new: true }
    );

    if (!store) return res.status(404).json({ message: "Store not found" });
    res.status(200).json(store);
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/stores/:storeId/follow/:userId
router.put("/:storeId/follow/:userId", async (req, res) => {
  try {
    const { storeId, userId } = req.params;

    const user = await User.findById(userId).select("followedStores");
    if (!user) return res.status(404).json({ message: "User not found" });

    const alreadyFollowing = user.followedStores.some(
      (id) => id.toString() === storeId
    );

    if (!alreadyFollowing) {
      await User.findByIdAndUpdate(userId, {
        $addToSet: { followedStores: storeId },
      });
      await Store.findByIdAndUpdate(storeId, { $inc: { followersCount: 1 } });

      // Notify store owner of new follower (fire without blocking)
      Store.findById(storeId).select("storeName sellerId").then((storeDoc) => {
        if (storeDoc && storeDoc.sellerId) {
          sendPushNotification({
            userId: storeDoc.sellerId.toString(),
            title: "New Store Follower 🏪",
            body: `Someone started following "${storeDoc.storeName}"`,
            type: "store_new_follower",
            storeId: storeId,
            data: { type: "store_new_follower", storeId: storeId, followerId: userId },
          }).catch(() => {});
        }
      }).catch(() => {});
    }

    const store = await Store.findById(storeId).select("followersCount");
    if (!store) return res.status(404).json({ message: "Store not found" });

    res.status(200).json({
      message: "Store followed",
      followersCount: store.followersCount,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// PUT /api/stores/:storeId/unfollow/:userId
router.put("/:storeId/unfollow/:userId", async (req, res) => {
  try {
    const { storeId, userId } = req.params;

    const user = await User.findById(userId).select("followedStores");
    if (!user) return res.status(404).json({ message: "User not found" });

    const wasFollowing = user.followedStores.some(
      (id) => id.toString() === storeId
    );

    if (wasFollowing) {
      await User.findByIdAndUpdate(userId, {
        $pull: { followedStores: storeId },
      });
      // Safely decrement — never below 0
      const store = await Store.findById(storeId).select("followersCount");
      if (store) {
        store.followersCount = Math.max(0, (store.followersCount || 0) - 1);
        await store.save();
      }
    }

    const updatedStore = await Store.findById(storeId).select("followersCount");
    if (!updatedStore) return res.status(404).json({ message: "Store not found" });

    res.status(200).json({
      message: "Store unfollowed",
      followersCount: updatedStore.followersCount,
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// GET store analytics summary
router.get("/:id/analytics", async (req, res) => {
  try {
    const store = await Store.findById(req.params.id);
    if (!store) return res.status(404).json({ message: "Store not found" });

    const [products, orders] = await Promise.all([
      StoreProduct.find({ storeId: req.params.id }).populate("productId", "name imageUrl brand"),
      Order.find({ storeId: req.params.id })
        .populate("userId", "fullName")
        .sort({ createdAt: -1 }),
    ]);

    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const ordersThisMonth = orders.filter((o) => o.createdAt >= startOfMonth);
    const completedOrders = orders.filter((o) => o.status === "delivered");
    const pendingOrders = orders.filter((o) => o.status === "pending");
    const cancelledOrders = orders.filter((o) => o.status === "cancelled");

    const revenueThisMonth = ordersThisMonth
      .filter((o) => o.status !== "cancelled")
      .reduce((sum, o) => sum + (o.total || 0), 0);

    const totalRevenue = completedOrders.reduce(
      (sum, o) => sum + (o.total || 0),
      0
    );

    const lowStockProducts = products.filter(
      (p) => p.stockCount > 0 && p.stockCount <= 5
    );
    const outOfStockProducts = products.filter(
      (p) => p.stockCount === 0 || !p.isAvailable
    );
    const approvedReviews = store.reviews.filter(
      (r) => r.status === "approved"
    );

    res.status(200).json({
      productsCount: products.length,
      availableProducts: products.filter((p) => p.isAvailable).length,
      lowStockCount: lowStockProducts.length,
      outOfStockCount: outOfStockProducts.length,
      totalOrders: orders.length,
      pendingOrders: pendingOrders.length,
      completedOrders: completedOrders.length,
      cancelledOrders: cancelledOrders.length,
      ordersThisMonth: ordersThisMonth.length,
      revenueThisMonth: parseFloat(revenueThisMonth.toFixed(2)),
      totalRevenue: parseFloat(totalRevenue.toFixed(2)),
      ratingAverage: store.rating || 0,
      reviewsCount: approvedReviews.length,
      followersCount: store.followersCount || 0,
      recentOrders: orders.slice(0, 5).map((o) => ({
        _id: o._id,
        customerName: (o.userId && o.userId.fullName) || o.fullName || "Customer",
        total: o.total,
        status: o.status,
        itemsCount: (o.items || []).length,
        createdAt: o.createdAt,
      })),
      topProducts: [...products]
        .sort((a, b) => (b.soldCount || 0) - (a.soldCount || 0))
        .slice(0, 5)
        .map((p) => ({
          name: (p.productId && p.productId.name) || "Product",
          imageUrl: (p.productId && p.productId.imageUrl) || "",
          brand: (p.productId && p.productId.brand) || "",
          soldCount: p.soldCount || 0,
          price: p.price,
          currency: p.currency || "ILS",
        })),
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});
router.put("/:id/upload-logo", uploadStoreImage.single("image"), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ message: "No image uploaded" });
    }

    const logoUrl = `${req.protocol}://${req.get("host")}/uploads/stores/${req.file.filename}`;

    const store = await Store.findByIdAndUpdate(
      req.params.id,
      { logoUrl },
      { new: true }
    );

    if (!store) {
      return res.status(404).json({ message: "Store not found" });
    }

    res.status(200).json({
      message: "Store logo uploaded successfully",
      logoUrl,
      store,
    });
  } catch (error) {
    res.status(500).json({
      message: "Server error",
      error: error.message,
    });
  }
});

// ── Upload cover image ─────────────────────────────────────────────────────
router.put("/:id/upload-cover", uploadStoreImage.single("image"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: "No image uploaded" });
    const coverImageUrl = `${req.protocol}://${req.get("host")}/uploads/stores/${req.file.filename}`;
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      { coverImageUrl },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.status(200).json({ message: "Cover image uploaded", coverImageUrl, store });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Add gallery image ──────────────────────────────────────────────────────
router.post("/:id/gallery", uploadStoreImage.single("image"), async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ message: "No image uploaded" });
    const imageUrl = `${req.protocol}://${req.get("host")}/uploads/stores/${req.file.filename}`;
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      { $addToSet: { galleryImages: imageUrl } },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.status(200).json({ message: "Gallery image added", imageUrl, galleryImages: store.galleryImages });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Remove gallery image ───────────────────────────────────────────────────
router.delete("/:id/gallery", async (req, res) => {
  try {
    const { url } = req.body;
    if (!url) return res.status(400).json({ message: "Image URL required" });
    const store = await Store.findByIdAndUpdate(
      req.params.id,
      { $pull: { galleryImages: url } },
      { new: true }
    );
    if (!store) return res.status(404).json({ message: "Store not found" });
    res.status(200).json({ message: "Gallery image removed", galleryImages: store.galleryImages });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ── Store Request Flow (user-facing) ─────────────────────────────────────────

// POST /request — Normal user submits a store request
router.post("/request", async (req, res) => {
  try {
    const {
      userId,
      storeName,
      city,
      address,
      phone,
      description,
      logoUrl,
      coverImageUrl,
      verificationDocumentUrl,
      verificationDocumentType,
    } = req.body;

    if (!userId || !storeName || !city) {
      return res.status(400).json({ message: "userId, storeName, and city are required" });
    }

    // Prevent duplicate pending/approved requests
    const existing = await Store.findOne({
      sellerId: userId,
      approvalStatus: { $in: ["pending", "approved"] },
    });

    if (existing) {
      return res.status(409).json({
        message: "You already have a pending or approved store request",
        store: existing,
      });
    }

    const hasDoc = verificationDocumentUrl && verificationDocumentUrl.trim().length > 0;

    const store = new Store({
      sellerId: userId,
      storeName: storeName.trim(),
      city: city.trim(),
      address: address || "",
      phone: phone || "",
      description: description || "",
      logoUrl: logoUrl || "",
      coverImageUrl: coverImageUrl || "",
      verificationDocumentUrl: verificationDocumentUrl || "",
      verificationDocumentType: verificationDocumentType || "other",
      approvalStatus: "pending",
      verificationStatus: hasDoc ? "pending_review" : "not_submitted",
      isActive: false,
      isVerified: false,
      verificationLevel: "standard",
    });

    await store.save();

    // Notify admins of new store request (fire without blocking)
    sendPushToRole({
      role: "admin",
      title: "New Store Request 🏪",
      body: `"${storeName.trim()}" has submitted a store request for review.`,
      data: { type: "new_store_request", storeId: store._id.toString() },
    }).catch(() => {});

    res.status(201).json({ message: "Store request submitted", store });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// GET /my-request/:userId — Get the user's store request/status
router.get("/my-request/:userId", async (req, res) => {
  try {
    const store = await Store.findOne({ sellerId: req.params.userId })
      .sort({ createdAt: -1 });

    if (!store) return res.status(404).json({ message: "No store request found" });
    res.json(store);
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

// PUT /request/:storeId/resubmit — User edits and resubmits a rejected store request
router.put("/request/:storeId/resubmit", async (req, res) => {
  try {
    const store = await Store.findById(req.params.storeId);
    if (!store) return res.status(404).json({ message: "Store not found" });

    if (store.approvalStatus !== "rejected") {
      return res.status(400).json({ message: "Only rejected stores can be resubmitted" });
    }

    const {
      storeName,
      city,
      address,
      phone,
      description,
      logoUrl,
      coverImageUrl,
      verificationDocumentUrl,
      verificationDocumentType,
    } = req.body;

    const hasDoc = verificationDocumentUrl && verificationDocumentUrl.trim().length > 0;

    Object.assign(store, {
      storeName: storeName || store.storeName,
      city: city || store.city,
      address: address || store.address,
      phone: phone || store.phone,
      description: description || store.description,
      logoUrl: logoUrl || store.logoUrl,
      coverImageUrl: coverImageUrl || store.coverImageUrl,
      verificationDocumentUrl: verificationDocumentUrl || store.verificationDocumentUrl,
      verificationDocumentType: verificationDocumentType || store.verificationDocumentType,
      approvalStatus: "pending",
      verificationStatus: hasDoc ? "pending_review" : store.verificationStatus,
      rejectionReason: "",
      reviewedAt: null,
      reviewedBy: null,
      isActive: false,
    });

    await store.save();
    res.json({ message: "Store request resubmitted", store });
  } catch (err) {
    res.status(500).json({ message: "Server error", error: err.message });
  }
});

module.exports = router;