const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Department = require("../models/Department");

// Load environment variables
dotenv.config();

const getDepartments = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully\n");

        // Get all departments
        const departments = await Department.find();

        console.log("=== Departments with IDs ===");
        departments.forEach(dept => {
            console.log(`ID: ${dept._id}`);
            console.log(`Name: ${dept.name}`);
            console.log(`Email: ${dept.email}`);
            console.log(`---`);
        });

        process.exit(0);
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
};

// Run
getDepartments();
