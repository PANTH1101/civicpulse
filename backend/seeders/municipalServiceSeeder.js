const mongoose = require("mongoose");
const dotenv = require("dotenv");
const MunicipalService = require("../models/MunicipalService");

// Load environment variables
dotenv.config();

// Predefined municipal services
const services = [
    // ADMINISTRATIVE
    {
        name: "Birth Certificate Application",
        description: "Apply for a new birth certificate or a certified copy of an existing birth record.",
        category: "ADMINISTRATIVE"
    },
    {
        name: "Death Certificate Application",
        description: "Apply for a death certificate or a certified copy of an existing death record.",
        category: "ADMINISTRATIVE"
    },
    {
        name: "Marriage Certificate Application",
        description: "Apply for a marriage certificate or certified copy of a marriage registration.",
        category: "ADMINISTRATIVE"
    },
    {
        name: "Residence Certificate Request",
        description: "Request an official certificate confirming your current residential address.",
        category: "ADMINISTRATIVE"
    },
    {
        name: "Property Tax Payment Assistance",
        description: "Get assistance with property tax assessments, payment processing, and dispute resolution.",
        category: "ADMINISTRATIVE"
    },

    // INFRASTRUCTURE
    {
        name: "Street Light Installation Request",
        description: "Request installation of a new street light in an unlit or poorly lit area.",
        category: "INFRASTRUCTURE"
    },
    {
        name: "Road Repair Request",
        description: "Request repair of damaged roads, pavements, or footpaths in your locality.",
        category: "INFRASTRUCTURE"
    },
    {
        name: "Water Connection Application",
        description: "Apply for a new domestic or commercial water supply connection.",
        category: "INFRASTRUCTURE"
    },
    {
        name: "Drainage and Sewage Service Request",
        description: "Request maintenance, repair, or installation of drainage and sewage systems.",
        category: "INFRASTRUCTURE"
    },

    // HEALTH_SERVICES
    {
        name: "Public Health Inspection Request",
        description: "Request a public health inspection of a premises or food establishment.",
        category: "HEALTH_SERVICES"
    },
    {
        name: "Vector Control Service",
        description: "Request pest control, fumigation, or vector control services for your area.",
        category: "HEALTH_SERVICES"
    },
    {
        name: "Health Camp Registration",
        description: "Register for upcoming government-organised health camps and medical checkup drives.",
        category: "HEALTH_SERVICES"
    },

    // EDUCATION_SERVICES
    {
        name: "School Enrollment Assistance",
        description: "Get assistance with enrolling children in government schools or resolving enrollment issues.",
        category: "EDUCATION_SERVICES"
    },
    {
        name: "Scholarship Application Support",
        description: "Get guidance and support for applying for government scholarship schemes.",
        category: "EDUCATION_SERVICES"
    },

    // ENVIRONMENT_SERVICES
    {
        name: "Tree Planting Request",
        description: "Request planting of trees in public spaces, roads, or parks in your locality.",
        category: "ENVIRONMENT_SERVICES"
    },
    {
        name: "Waste Collection Schedule Request",
        description: "Request a revised or additional waste collection schedule for your area.",
        category: "ENVIRONMENT_SERVICES"
    },

    // SOCIAL_SERVICES
    {
        name: "Social Welfare Scheme Assistance",
        description: "Get assistance applying for government social welfare schemes and benefits.",
        category: "SOCIAL_SERVICES"
    },

    // EMERGENCY_SERVICES
    {
        name: "Emergency Relief Application",
        description: "Apply for emergency relief assistance in the event of a natural disaster or calamity.",
        category: "EMERGENCY_SERVICES"
    }
];

const seedMunicipalServices = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully\n");

        // Check existing count
        const existingCount = await MunicipalService.countDocuments();

        if (existingCount > 0) {
            console.log(`Found ${existingCount} existing municipal services.`);
            console.log("Checking for new entries to insert...\n");

            let insertedCount = 0;
            let skippedCount = 0;

            for (const service of services) {
                const existing = await MunicipalService.findOne({ name: service.name });

                if (existing) {
                    console.log(`Skipped: ${service.name} (already exists)`);
                    skippedCount++;
                } else {
                    await MunicipalService.create(service);
                    console.log(`Inserted: ${service.name}`);
                    insertedCount++;
                }
            }

            console.log(`\nSeeding complete:`);
            console.log(`  Inserted: ${insertedCount}`);
            console.log(`  Skipped:  ${skippedCount}`);
            console.log(`  Total:    ${await MunicipalService.countDocuments()}`);
        } else {
            // Fresh insert
            await MunicipalService.insertMany(services);
            console.log(`Successfully inserted ${services.length} municipal services.\n`);
        }

        // Display all services grouped by category
        console.log("=== All Municipal Services ===");
        const allServices = await MunicipalService.find().sort({ category: 1, name: 1 });

        let currentCategory = null;
        allServices.forEach(s => {
            if (s.category !== currentCategory) {
                currentCategory = s.category;
                console.log(`\n[${s.category}]`);
            }
            console.log(`  - ${s.name} (ID: ${s._id})`);
        });

        process.exit(0);
    } catch (error) {
        console.error("Seeding error:", error.message);
        process.exit(1);
    }
};

// Run seeder
seedMunicipalServices();
