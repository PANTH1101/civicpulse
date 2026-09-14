const mongoose = require("mongoose");

const serviceRequestSchema = new mongoose.Schema(
    {
        service_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "MunicipalService",
            required: true
        },

        department_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Department",
            required: true
        },

        // Always set from JWT — never trusted from request body
        citizen_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        notes: {
            type: String,
            default: null,
            trim: true,
            maxlength: 1000
        },

        status: {
            type: String,
            enum: [
                "PENDING",
                "ACCEPTED",
                "IN_PROGRESS",
                "COMPLETED",
                "REJECTED",
                "CANCELLED"
            ],
            default: "PENDING"
        },

        // Department-provided reason when rejecting
        rejectionReason: {
            type: String,
            default: null,
            trim: true,
            maxlength: 1000
        },

        // Lifecycle timestamps
        acceptedAt: {
            type: Date,
            default: null
        },

        startedAt: {
            type: Date,
            default: null
        },

        completedAt: {
            type: Date,
            default: null
        },

        rejectedAt: {
            type: Date,
            default: null
        },

        cancelledAt: {
            type: Date,
            default: null
        }
    },
    {
        timestamps: true
    }
);

// Indexes for common query patterns
serviceRequestSchema.index({ citizen_id: 1, status: 1 });
serviceRequestSchema.index({ citizen_id: 1, createdAt: -1 });
serviceRequestSchema.index({ department_id: 1, status: 1 });
serviceRequestSchema.index({ department_id: 1, createdAt: -1 });

module.exports = mongoose.model("ServiceRequest", serviceRequestSchema);
