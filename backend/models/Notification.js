const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
    {
        user_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        issue_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "CivicIssue",
            required: true
        },

        type: {
            type: String,
            required: true,
            enum: [
                "ISSUE_REPORTED",
                "ISSUE_VERIFIED",
                "ISSUE_REJECTED",
                "ISSUE_ASSIGNED",
                "ISSUE_STARTED",
                "ISSUE_RESOLVED"
            ]
        },

        message: {
            type: String,
            required: true,
            trim: true
        },

        is_read: {
            type: Boolean,
            default: false
        }
    },
    {
        timestamps: true
    }
);

// Index for faster queries
notificationSchema.index({ user_id: 1, is_read: 1 });
notificationSchema.index({ user_id: 1, createdAt: -1 });

module.exports = mongoose.model("Notification", notificationSchema);
