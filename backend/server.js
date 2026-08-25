// Import Express framework
const express = require("express");

// Import dotenv to load environment variables from .env file
const dotenv = require("dotenv");

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

// Load environment variables from .env file
dotenv.config();

// Create an Express application
const app = express();

// Set the server port from .env or use 5000 as default
const PORT = process.env.PORT || 4000;

// Connect to MongoDB database
connectDB();

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