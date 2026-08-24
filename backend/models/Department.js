const mongoose = require("mongoose");

const departmentSchema = new mongoose.Schema(
    {
        name: {
            type: String,
            required: true,
            unique: true,
            trim: true
        },

        email: {
            type: String,
            required: true,
            unique: true,
            lowercase: true,
            trim: true
        },

        mobile: {
            type: String,
            required: true,
            trim: true
        },

        office_address: {
            type: String,
            required: true,
            trim: true
        }
    },
    {
        timestamps: true
    }
);

module.exports = mongoose.model("Department", departmentSchema);
