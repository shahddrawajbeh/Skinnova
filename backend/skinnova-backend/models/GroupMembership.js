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

module.exports =
  mongoose.models.GroupMembership ||
  mongoose.model("GroupMembership", groupMembershipSchema);
