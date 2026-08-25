const mongoose = require("mongoose");

const feedbackSchema = new mongoose.Schema(
    {
        issue_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "CivicIssue",
            required: true
        },

        user_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "User",
            required: true
        },

        rating: {
            type: Number,
            required: true,
            min: 1,
            max: 5,
            validate: {
                validator: Number.isInteger,
                message: "Rating must be an integer"
            }
        },

        comment: {
            type: String,
            default: null,
            trim: true,
            maxlength: 1000
        }
    },
    {
        timestamps: true
    }
);

// Create unique index to prevent duplicate feedback per issue
feedbackSchema.index({ issue_id: 1 }, { unique: true });

module.exports = mongoose.model("Feedback", feedbackSchema);
