const mongoose = require("mongoose");
const dotenv = require("dotenv");
const User = require("../models/User");
const bcrypt = require("bcryptjs");

// Load environment variables
dotenv.config();

const createModerator = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully");

        // Check if moderator already exists
        const existing = await User.findOne({ email: "moderator@test.com" });

        if (existing) {
            console.log("Moderator already exists");
            console.log(`Name: ${existing.name}`);
            console.log(`Email: ${existing.email}`);
            console.log(`Role: ${existing.role}`);
        } else {
            // Hash password
            const hashedPassword = await bcrypt.hash("password123", 10);

            // Create moderator
            const moderator = await User.create({
                name: "Test Moderator",
                email: "moderator@test.com",
                password: hashedPassword,
                role: "MODERATOR"
            });

            console.log("Moderator created successfully");
            console.log(`Name: ${moderator.name}`);
            console.log(`Email: ${moderator.email}`);
            console.log(`Role: ${moderator.role}`);
        }

        process.exit(0);
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
};

// Run
createModerator();
