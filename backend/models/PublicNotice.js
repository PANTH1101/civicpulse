const mongoose = require("mongoose");

const publicNoticeSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: true,
            trim: true
        },

        content: {
            type: String,
            required: true,
            trim: true
        },

        category: {
            type: String,
            required: true,
            enum: [
                "GENERAL",
                "EMERGENCY",
                "MAINTENANCE",
                "EVENT",
                "POLICY",
                "ANNOUNCEMENT",
                "OTHER"
            ]
        },

        status: {
            type: String,
            enum: ["DRAFT", "PUBLISHED"],
            default: "DRAFT"
        },

        createdBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        publishedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null
        },

        publishedAt: {
            type: Date,
            default: null
        }
    },
    {
        timestamps: true
    }
);

// Index for faster queries
publicNoticeSchema.index({ status: 1, publishedAt: -1 });
publicNoticeSchema.index({ createdBy: 1, createdAt: -1 });

module.exports = mongoose.model("PublicNotice", publicNoticeSchema);
