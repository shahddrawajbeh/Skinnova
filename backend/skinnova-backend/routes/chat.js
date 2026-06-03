const express = require("express");
const router = express.Router();
const Conversation = require("../models/conversation");
const Message = require("../models/message");
const User = require("../models/user");
const Store = require("../models/store");

// POST /api/chat/start — find or create conversation, inject welcome msg if new
router.post("/start", async (req, res) => {
  const { userId, storeId } = req.body;
  if (!userId || !storeId)
    return res.status(400).json({ message: "userId and storeId required" });

  try {
    const store = await Store.findById(storeId).select("sellerId storeName");
    if (!store) return res.status(404).json({ message: "Store not found" });

    let isNew = false;
    let conversation = await Conversation.findOne({ userId, storeId });

    if (!conversation) {
      conversation = await Conversation.create({
        userId,
        sellerId: store.sellerId,
        storeId,
      });
      isNew = true;
    }

    if (isNew) {
      const user = await User.findById(userId).select("fullName");
      const firstName = user?.fullName?.trim().split(" ")[0] || "there";
      await Message.create({
        conversationId: conversation._id,
        senderId: store.sellerId,
        senderType: "seller",
        messageType: "text",
        text: `Hi ${firstName} ✨ Welcome to ${store.storeName}! How can we help you today?`,
        isSeen: false,
      });
    }

    res.status(200).json({ conversation, isNew });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/chat/conversations/:userId
router.get("/conversations/:userId", async (req, res) => {
  try {
    const conversations = await Conversation.find({
      userId: req.params.userId,
      isActive: true,
    })
      .populate("storeId", "storeName logoUrl responseTime")
      .sort({ lastMessageTime: -1 });
    res.json(conversations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/chat/seller/conversations/:sellerId
router.get("/seller/conversations/:sellerId", async (req, res) => {
  try {
    const conversations = await Conversation.find({
      sellerId: req.params.sellerId,
      isActive: true,
    })
      .populate("userId", "fullName profileImage")
      .populate("storeId", "storeName logoUrl")
      .sort({ lastMessageTime: -1 });
    res.json(conversations);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// GET /api/chat/messages/:conversationId
router.get("/messages/:conversationId", async (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 40;

  try {
    const total = await Message.countDocuments({
      conversationId: req.params.conversationId,
    });
    const messages = await Message.find({
      conversationId: req.params.conversationId,
    })
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    res.json({
      messages: messages.reverse(),
      total,
      page,
      hasMore: page * limit < total,
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// POST /api/chat/send
router.post("/send", async (req, res) => {
  const {
    conversationId,
    senderId,
    senderType,
    messageType,
    text,
    productSnapshot,
    imageUrl,
  } = req.body;

  if (!conversationId || !senderId || !senderType)
    return res.status(400).json({ message: "Required fields missing" });

  try {
    const message = await Message.create({
      conversationId,
      senderId,
      senderType,
      messageType: messageType || "text",
      text: text || "",
      productSnapshot: productSnapshot || null,
      imageUrl: imageUrl || "",
    });

    const lastMsg =
      messageType === "product" ? "📦 Shared a product" : text || "Message";

    const updatedConv = await Conversation.findByIdAndUpdate(
      conversationId,
      {
        lastMessage: lastMsg,
        lastMessageTime: new Date(),
        $inc:
          senderType === "user"
            ? { sellerUnreadCount: 1 }
            : { userUnreadCount: 1 },
      },
      { new: true }
    );

    if (updatedConv) {
      const io = req.app.get("io");
      if (io) {
        io.to(`seller_${updatedConv.sellerId}`).emit("conversation_updated", {
          conversationId,
          lastMessage: lastMsg,
          lastMessageTime: updatedConv.lastMessageTime,
          sellerUnreadCount: updatedConv.sellerUnreadCount,
          senderType,
        });
      }
    }

    res.status(201).json(message);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// PUT /api/chat/seen/:conversationId
router.put("/seen/:conversationId", async (req, res) => {
  const { viewerType } = req.body;
  if (!viewerType)
    return res.status(400).json({ message: "viewerType required" });

  try {
    await Message.updateMany(
      {
        conversationId: req.params.conversationId,
        isSeen: false,
        senderType: { $ne: viewerType },
      },
      { isSeen: true, seenAt: new Date() }
    );

    const update =
      viewerType === "user"
        ? { userUnreadCount: 0 }
        : { sellerUnreadCount: 0 };
    await Conversation.findByIdAndUpdate(req.params.conversationId, update);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;
