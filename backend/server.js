// Load environment variables FIRST, before any other imports
require("dotenv").config();

// Import Express framework
const express = require("express");

// Import CORS middleware
const cors = require("cors");

// Import function to connect to MongoDB
const connectDB = require("./config/db");

// Import authentication routes
const authRoutes = require("./routes/authRoutes");

// Import issue routes
const issueRoutes = require("./routes/issueRoutes");

// Import department routes
const departmentRoutes = require("./routes/departmentRoutes");

// Import notification routes
const notificationRoutes = require("./routes/notificationRoutes");

// Import feedback routes
const feedbackRoutes = require("./routes/feedbackRoutes");

// Import public notice routes
const publicNoticeRoutes = require("./routes/publicNoticeRoutes");

// Import municipal service routes
const serviceRoutes = require("./routes/serviceRoutes");

// Import user routes (specification-compliant)
const userRoutes = require("./routes/userRoutes");

// Create an Express application
const app = express();

// Set the server port from .env or use 5000 as default
const PORT = process.env.PORT || 4000;

// Connect to MongoDB database
connectDB();

// ---------------------------------------------------------------------------
// CORS Configuration (Task 10)
// ---------------------------------------------------------------------------
// Configure CORS to allow Flutter frontend communication
// Supports:
// - Flutter web/desktop: http://localhost:4000
// - Android emulator: http://10.0.2.2:4000
// - Physical device: http://<MAC-LAN-IP>:4000
// ---------------------------------------------------------------------------
const allowedOrigins = process.env.CORS_ORIGIN 
    ? process.env.CORS_ORIGIN.split(',').map(origin => origin.trim())
    : ['http://localhost:3000', 'http://localhost:4000', 'http://localhost:5173', 'http://localhost:5174', 'http://localhost:5175', 'http://10.0.2.2:4000'];

const corsOptions = {
    origin: function (origin, callback) {
        // Allow requests with no origin (like mobile apps, Postman, curl)
        if (!origin) {
            return callback(null, true);
        }
        
        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            // Log rejected origin for debugging
            console.warn(`CORS: Rejected origin ${origin}`);
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true, // Allow cookies/authentication headers
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    exposedHeaders: ['Content-Range', 'X-Content-Range'],
    maxAge: 600 // Cache preflight request for 10 minutes
};

// Apply CORS middleware
app.use(cors(corsOptions));

// Middleware to parse incoming JSON data
app.use(express.json());

// Use authentication routes with /api/auth prefix
app.use("/api/auth", authRoutes);

// Use issue routes with /api/issues prefix
app.use("/api/issues", issueRoutes);

// Use department routes with /api/departments prefix
app.use("/api/departments", departmentRoutes);

// Use notification routes with /api/notifications prefix
app.use("/api/notifications", notificationRoutes);

// Use feedback routes with /api/feedback prefix
app.use("/api/feedback", feedbackRoutes);

// Use public notice routes with /api/notices prefix
app.use("/api/notices", publicNoticeRoutes);

// Use municipal service routes with /api/services prefix
// This covers both service browsing (/api/services) and service requests (/api/services/requests/*)
app.use("/api/services", serviceRoutes);

// ---------------------------------------------------------------------------
// SPECIFICATION-COMPLIANT ENDPOINTS (/api/v1/*)
// Task 11.1: Add /api/v1 routing structure
// ---------------------------------------------------------------------------
// Use user routes with /api/v1/users prefix (specification-compliant)
app.use("/api/v1/users", userRoutes);

// Create a GET route for the root URL
app.get("/", (req, res) => {

    // Send response to confirm that the backend is running
    res.send("CivicPulse Backend is running!");
});

// Start the Express server on the specified port
app.listen(PORT, () => {

    // Display server URL in the console
    console.log(`Server running on http://localhost:${PORT}`);
});