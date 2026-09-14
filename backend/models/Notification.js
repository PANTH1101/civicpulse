const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
    {
        user_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        // Set for civic issue notifications; null for service request notifications
        issue_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "CivicIssue",
            default: null
        },

        // Set for service request notifications; null for civic issue notifications
        service_request_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "ServiceRequest",
            default: null
        },

        // Set for public notice notifications; null for other notification types
        notice_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "PublicNotice",
            default: null
        },

        type: {
            type: String,
            required: true,
            enum: [
                // Civic Issue types (existing — do not modify)
                "ISSUE_REPORTED",
                "ISSUE_VERIFIED",
                "ISSUE_REJECTED",
                "ISSUE_ASSIGNED",
                "ISSUE_STARTED",
                "ISSUE_RESOLVED",

                // Municipal Service Request types (new)
                "SERVICE_REQUEST_SUBMITTED",
                "SERVICE_REQUEST_ACCEPTED",
                "SERVICE_REQUEST_REJECTED",
                "SERVICE_REQUEST_STARTED",
                "SERVICE_REQUEST_COMPLETED",
                "SERVICE_REQUEST_CANCELLED",

                // Public Notice types
                "PUBLIC_NOTICE_PUBLISHED"
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
