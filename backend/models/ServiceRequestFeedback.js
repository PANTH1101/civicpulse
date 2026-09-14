const mongoose = require("mongoose");

const serviceRequestFeedbackSchema = new mongoose.Schema(
    {
        service_request_id: {
            type: mongoose.Schema.Types.ObjectId,
            ref: "ServiceRequest",
            required: true
        },

        // Always set from JWT — never trusted from request body
        citizen_id: {
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

// One feedback per service request
serviceRequestFeedbackSchema.index({ service_request_id: 1 }, { unique: true });

module.exports = mongoose.model("ServiceRequestFeedback", serviceRequestFeedbackSchema);
