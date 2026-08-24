const mongoose = require("mongoose");

const civicIssueSchema = new mongoose.Schema(
    {
        title: {
            type: String,
            required: true,
            trim: true
        },

        description: {
            type: String,
            required: true,
            trim: true
        },

        category: {
            type: String,
            required: true,
            enum: [
                "ROADS",
                "WATER",
                "ELECTRICITY",
                "SANITATION",
                "PUBLIC_SAFETY",
                "HEALTHCARE",
                "EDUCATION",
                "ENVIRONMENT",
                "OTHER"
            ]
        },

        location: {
            type: String,
            required: true,
            trim: true
        },

        status: {
            type: String,
            enum: ["REPORTED", "ASSIGNED", "IN_PROGRESS", "RESOLVED", "REJECTED"],
            default: "REPORTED"
        },

        reportedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        assignedTo: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null
        },

        department_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Department",
            default: null
        },

        verifiedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null
        },

        resolution_description: {
            type: String,
            default: null,
            trim: true
        },

        resolution_evidence: {
            type: String,
            default: null,
            trim: true
        },

        resolvedBy: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            default: null
        },

        resolvedAt: {
            type: Date,
            default: null
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("CivicIssue", civicIssueSchema);
