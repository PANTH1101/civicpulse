const mongoose = require("mongoose");
const dotenv = require("dotenv");
const bcrypt = require("bcryptjs");
const User = require("../models/User");

dotenv.config();

const createTestCitizen = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected");

        const existing = await User.findOne({ email: "alice@example.com" });
        if (existing) {
            console.log("Test citizen already exists");
            console.log(`Name: ${existing.name}`);
            console.log(`Email: ${existing.email}`);
            console.log(`Role: ${existing.role}`);
        } else {
            const hashedPassword = await bcrypt.hash("password123", 10);
            
            const citizen = await User.create({
                name: "Alice Johnson",
                email: "alice@example.com",
                password: hashedPassword,
                role: "CITIZEN"
            });
            
            console.log("Test citizen created successfully");
            console.log(`Name: ${citizen.name}`);
            console.log(`Email: ${citizen.email}`);
            console.log(`Role: ${citizen.role}`);
            console.log(`Password: password123`);
        }
        process.exit(0);
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
};

createTestCitizen();
