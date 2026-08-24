const mongoose = require("mongoose");
const dotenv = require("dotenv");
const Department = require("../models/Department");

// Load environment variables
dotenv.config();

// Predefined departments
const departments = [
    {
        name: "Roads and Transportation Department",
        email: "roads@civicpulse.gov",
        mobile: "+1-555-0101",
        office_address: "123 Main Street, Building A, Floor 2, City Hall"
    },
    {
        name: "Water Supply Department",
        email: "water@civicpulse.gov",
        mobile: "+1-555-0102",
        office_address: "456 Water Works Avenue, Municipal Complex"
    },
    {
        name: "Electricity Department",
        email: "electricity@civicpulse.gov",
        mobile: "+1-555-0103",
        office_address: "789 Power Plant Road, Utility Building"
    },
    {
        name: "Sanitation Department",
        email: "sanitation@civicpulse.gov",
        mobile: "+1-555-0104",
        office_address: "321 Sanitation Drive, Waste Management Center"
    },
    {
        name: "Public Safety Department",
        email: "safety@civicpulse.gov",
        mobile: "+1-555-0105",
        office_address: "555 Safety Boulevard, Emergency Services Building"
    },
    {
        name: "Healthcare Department",
        email: "healthcare@civicpulse.gov",
        mobile: "+1-555-0106",
        office_address: "777 Health Center Lane, Medical Administration"
    },
    {
        name: "Education Department",
        email: "education@civicpulse.gov",
        mobile: "+1-555-0107",
        office_address: "888 Education Way, School District Office"
    },
    {
        name: "Environment Department",
        email: "environment@civicpulse.gov",
        mobile: "+1-555-0108",
        office_address: "999 Green Park Circle, Environmental Protection Office"
    },
    {
        name: "General Services Department",
        email: "general@civicpulse.gov",
        mobile: "+1-555-0109",
        office_address: "111 Civic Center Plaza, General Administration"
    }
];

const seedDepartments = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully");

        // Check if departments already exist
        const existingCount = await Department.countDocuments();

        if (existingCount > 0) {
            console.log(`Found ${existingCount} existing departments`);
            console.log("Checking for duplicates...");

            let insertedCount = 0;
            let skippedCount = 0;

            for (const dept of departments) {
                const existing = await Department.findOne({ email: dept.email });

                if (existing) {
                    console.log(`Skipped: ${dept.name} (already exists)`);
                    skippedCount++;
                } else {
                    await Department.create(dept);
                    console.log(`Inserted: ${dept.name}`);
                    insertedCount++;
                }
            }

            console.log(`\nSeeding complete:`);
            console.log(`- Inserted: ${insertedCount}`);
            console.log(`- Skipped: ${skippedCount}`);
            console.log(`- Total departments: ${await Department.countDocuments()}`);
        } else {
            // Insert all departments
            await Department.insertMany(departments);
            console.log(`Successfully inserted ${departments.length} predefined departments`);
        }

        // Display all departments
        console.log("\n=== All Departments ===");
        const allDepts = await Department.find().select("name email mobile");
        allDepts.forEach(dept => {
            console.log(`- ${dept.name} [${dept.email}] - ${dept.mobile}`);
        });

        process.exit(0);
    } catch (error) {
        console.error("Seeding error:", error.message);
        process.exit(1);
    }
};

// Run seeder
seedDepartments();
