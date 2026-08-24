const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Department = require("../models/Department");

// Load environment variables
dotenv.config();

const dropDepartments = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully");

        // Drop the departments collection
        await Department.collection.drop();
        console.log("Departments collection dropped successfully");

        process.exit(0);
    } catch (error) {
        if (error.message === "ns not found") {
            console.log("Departments collection does not exist");
        } else {
            console.error("Error:", error.message);
        }
        process.exit(1);
    }
};

// Run drop
dropDepartments();
