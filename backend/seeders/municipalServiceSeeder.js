const mongoose = require("mongoose");
const dotenv = require("dotenv");
const MunicipalService = require("../models/MunicipalService");
const Department = require("../models/Department");

// Load environment variables
dotenv.config();

// Predefined municipal services with department assignments
// Department IDs will be resolved dynamically from department names
const services = [
    // ADMINISTRATIVE - handled by General Services Department
    {
        name: "Birth Certificate Application",
        description: "Apply for a new birth certificate or a certified copy of an existing birth record.",
        category: "ADMINISTRATIVE",
        departmentName: "General Services Department"
    },
    {
        name: "Death Certificate Application",
        description: "Apply for a death certificate or a certified copy of an existing death record.",
        category: "ADMINISTRATIVE",
        departmentName: "General Services Department"
    },
    {
        name: "Marriage Certificate Application",
        description: "Apply for a marriage certificate or certified copy of a marriage registration.",
        category: "ADMINISTRATIVE",
        departmentName: "General Services Department"
    },
    {
        name: "Residence Certificate Request",
        description: "Request an official certificate confirming your current residential address.",
        category: "ADMINISTRATIVE",
        departmentName: "General Services Department"
    },
    {
        name: "Property Tax Payment Assistance",
        description: "Get assistance with property tax assessments, payment processing, and dispute resolution.",
        category: "ADMINISTRATIVE",
        departmentName: "General Services Department"
    },

    // INFRASTRUCTURE
    {
        name: "Street Light Installation Request",
        description: "Request installation of a new street light in an unlit or poorly lit area.",
        category: "INFRASTRUCTURE",
        departmentName: "Electricity Department"
    },
    {
        name: "Road Repair Request",
        description: "Request repair of damaged roads, pavements, or footpaths in your locality.",
        category: "INFRASTRUCTURE",
        departmentName: "Roads and Transportation Department"
    },
    {
        name: "Water Connection Application",
        description: "Apply for a new domestic or commercial water supply connection.",
        category: "INFRASTRUCTURE",
        departmentName: "Water Supply Department"
    },
    {
        name: "Drainage and Sewage Service Request",
        description: "Request maintenance, repair, or installation of drainage and sewage systems.",
        category: "INFRASTRUCTURE",
        departmentName: "Sanitation Department"
    },

    // HEALTH_SERVICES - handled by Healthcare Department
    {
        name: "Public Health Inspection Request",
        description: "Request a public health inspection of a premises or food establishment.",
        category: "HEALTH_SERVICES",
        departmentName: "Healthcare Department"
    },
    {
        name: "Vector Control Service",
        description: "Request pest control, fumigation, or vector control services for your area.",
        category: "HEALTH_SERVICES",
        departmentName: "Healthcare Department"
    },
    {
        name: "Health Camp Registration",
        description: "Register for upcoming government-organised health camps and medical checkup drives.",
        category: "HEALTH_SERVICES",
        departmentName: "Healthcare Department"
    },

    // EDUCATION_SERVICES - handled by Education Department
    {
        name: "School Enrollment Assistance",
        description: "Get assistance with enrolling children in government schools or resolving enrollment issues.",
        category: "EDUCATION_SERVICES",
        departmentName: "Education Department"
    },
    {
        name: "Scholarship Application Support",
        description: "Get guidance and support for applying for government scholarship schemes.",
        category: "EDUCATION_SERVICES",
        departmentName: "Education Department"
    },

    // ENVIRONMENT_SERVICES - handled by Environment Department
    {
        name: "Tree Planting Request",
        description: "Request planting of trees in public spaces, roads, or parks in your locality.",
        category: "ENVIRONMENT_SERVICES",
        departmentName: "Environment Department"
    },
    {
        name: "Waste Collection Schedule Request",
        description: "Request a revised or additional waste collection schedule for your area.",
        category: "ENVIRONMENT_SERVICES",
        departmentName: "Sanitation Department"
    },

    // SOCIAL_SERVICES - handled by General Services Department
    {
        name: "Social Welfare Scheme Assistance",
        description: "Get assistance applying for government social welfare schemes and benefits.",
        category: "SOCIAL_SERVICES",
        departmentName: "General Services Department"
    },

    // EMERGENCY_SERVICES - handled by Public Safety Department
    {
        name: "Emergency Relief Application",
        description: "Apply for emergency relief assistance in the event of a natural disaster or calamity.",
        category: "EMERGENCY_SERVICES",
        departmentName: "Public Safety Department"
    }
];

const seedMunicipalServices = async () => {
    try {
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI);
        console.log("MongoDB connected successfully\n");

        // First, resolve all department names to IDs
        console.log("Resolving department names to IDs...");
        const departmentMap = {};
        for (const service of services) {
            if (!departmentMap[service.departmentName]) {
                const dept = await Department.findOne({ name: service.departmentName });
                if (!dept) {
                    throw new Error(`Department not found: ${service.departmentName}`);
                }
                departmentMap[service.departmentName] = dept._id;
                console.log(`  Resolved: ${service.departmentName} -> ${dept._id}`);
            }
        }
        console.log();

        // Drop all existing services (schema changed - added required department_id field)
        const existingCount = await MunicipalService.countDocuments();
        if (existingCount > 0) {
            console.log(`Dropping ${existingCount} existing services (schema changed)...`);
            await MunicipalService.deleteMany({});
            console.log("Existing services dropped.\n");
        }

        // Insert services with department_id
        console.log("Inserting services with department assignments...");
        const servicesToInsert = services.map(s => ({
            name: s.name,
            description: s.description,
            category: s.category,
            department_id: departmentMap[s.departmentName],
            isActive: true
        }));

        await MunicipalService.insertMany(servicesToInsert);
        console.log(`Successfully inserted ${services.length} municipal services.\n`);

        // Display all services grouped by category with department info
        console.log("=== All Municipal Services with Department Assignments ===");
        const allServices = await MunicipalService.find()
            .populate("department_id", "name")
            .sort({ category: 1, name: 1 });

        let currentCategory = null;
        allServices.forEach(s => {
            if (s.category !== currentCategory) {
                currentCategory = s.category;
                console.log(`\n[${s.category}]`);
            }
            console.log(`  - ${s.name}`);
            console.log(`    Department: ${s.department_id.name}`);
            console.log(`    ID: ${s._id}`);
        });

        console.log(`\nTotal services: ${allServices.length}`);
        process.exit(0);
    } catch (error) {
        console.error("Seeding error:", error.message);
        process.exit(1);
    }
};

// Run seeder
seedMunicipalServices();
