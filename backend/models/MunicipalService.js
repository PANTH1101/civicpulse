const mongoose = require("mongoose");

const municipalServiceSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            unique: true,
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
                "ADMINISTRATIVE",
                "INFRASTRUCTURE",
                "HEALTH_SERVICES",
                "EDUCATION_SERVICES",
                "ENVIRONMENT_SERVICES",
                "SOCIAL_SERVICES",
                "LEGAL_SERVICES",
                "EMERGENCY_SERVICES",
                "OTHER"
            ]
        },

        isActive: {
            type: Boolean,
            default: true
        },

        department_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "Department",
            required: true
        }
    },
    {
        timestamps: true
    }
);

// Index for faster category and active queries
municipalServiceSchema.index({ category: 1, isActive: 1 });

module.exports = mongoose.model("MunicipalService", municipalServiceSchema);
