const mongoose = require("mongoose");
const dotenv = require("dotenv");
const bcrypt = require("bcryptjs");
const Department = require("../models/Department");
const User = require("../models/User");

// Load environment variables
dotenv.config();

const seedDepartmentUsers = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully\n");

        // Get all predefined departments
        const departments = await Department.find();

        if (departments.length === 0) {
            console.log("No departments found. Please run department seeder first.");
            process.exit(1);
        }

        console.log(`Found ${departments.length} departments\n`);

        let createdCount = 0;
        let skippedCount = 0;

        // Development-only password (should be changed in production)
        const defaultPassword = "department123";
        const hashedPassword = await bcrypt.hash(defaultPassword, 10);

        for (const department of departments) {
            // Check if department user already exists
            const existingUser = await User.findOne({ 
                email: department.email,
                role: "DEPARTMENT"
            });

            if (existingUser) {
                console.log(`Skipped: ${department.name}`);
                console.log(`  Email: ${department.email}`);
                console.log(`  User already exists with ID: ${existingUser._id}`);
                console.log(`  Linked to Department: ${existingUser.department_id}`);
                console.log("");
                skippedCount++;
            } else {
                // Create department user
                const departmentUser = await User.create({
                    name: department.name,
                    email: department.email,
                    password: hashedPassword,
                    role: "DEPARTMENT",
                    department_id: department._id
                });

                console.log(`Created: ${department.name}`);
                console.log(`  Email: ${department.email}`);
                console.log(`  User ID: ${departmentUser._id}`);
                console.log(`  Department ID: ${departmentUser.department_id}`);
                console.log(`  Role: ${departmentUser.role}`);
                console.log("");
                createdCount++;
            }
        }

        console.log("=== Seeding Summary ===");
        console.log(`Created: ${createdCount}`);
        console.log(`Skipped: ${skippedCount}`);
        console.log(`Total Department Users: ${createdCount + skippedCount}`);
        console.log("\n=== Default Password (Development Only) ===");
        console.log(`Password: ${defaultPassword}`);
        console.log("⚠️  Change passwords in production!");

        // Verify the relationships
        console.log("\n=== Verification ===");
        const departmentUsers = await User.find({ role: "DEPARTMENT" }).populate("department_id");
        
        for (const user of departmentUsers) {
            console.log(`✓ ${user.name}`);
            console.log(`  User ID: ${user._id}`);
            console.log(`  Department ID: ${user.department_id._id}`);
            console.log(`  Match: ${user.department_id.name === user.name ? "✓" : "✗"}`);
        }

        process.exit(0);
    } catch (error) {
        console.error("Seeding error:", error.message);
        process.exit(1);
    }
};

// Run seeder
seedDepartmentUsers();
