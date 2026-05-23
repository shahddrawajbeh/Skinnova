const mongoose = require("mongoose");



const commentSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    userName: { type: String, required: true },
    userAvatar: { type: String, default: "" },
    comment: { type: String, required: true, trim: true },
    parentCommentId: { type: String, default: null },
    replyToUserName: { type: String, default: "" },
    createdAt: { type: Date, default: Date.now },
     likes: {
      type: [String],
      default: [],
    },
  },
  { _id: true }
);


const groupPostSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true },
    userName: { type: String, required: true },
    userAvatar: { type: String, default: "" },

    tag: { type: String, default: "Sensitive" }, 
    postType: { type: String, enum: ["review", "question", "update"], default: "review" },

    content: { type: String, default: "" },
    images: { type: [String], default: [] },

    productId: { type: mongoose.Schema.Types.ObjectId, ref: "Product", default: null },
    productName: { type: String, default: "" },
    productImage: {
  type: String,
  default: "",
  trim: true,

},
groupId: {
  type: mongoose.Schema.Types.ObjectId,
  ref: "Group",
  default: null,
},
groupTitle: {
  type: String,
  default: "",
  trim: true,
},
groupSlug: {
  type: String,
  default: "",
  trim: true,
},
likes: {
  type: [String], // نخزن userId
  default: [],
},
comments: {
  type: [commentSchema],
  default: [],
},

repurchase: { type: Boolean, default: null },
improvedSkin: { type: Boolean, default: null },
wasGift: { type: Boolean, default: null },
adverseReaction: { type: Boolean, default: null },
texture: { type: String, default: "" },
usageWeeks: { type: String, default: "" },
    rating: { type: Number, default: 0 },

    timeText: { type: String, default: "Just now" },
    isEdited: { type: Boolean, default: false },
  },
  { timestamps: true }
);






module.exports = mongoose.model("GroupPost", groupPostSchema);