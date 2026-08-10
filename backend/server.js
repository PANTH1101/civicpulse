const express = require("express");
const dotenv = require("dotenv");
const connectDB = require("./config/db");
const authRoutes = require("./routes/authRoutes");
const protect = require("./middleware/authMiddleware");

dotenv.config();

const app = express();

const PORT = process.env.PORT || 5000;

connectDB();

app.use(express.json());

app.use("/api/auth", authRoutes);

app.get("/", (req, res) => {
    res.send("CivicPulse Backend is running!");
});


app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
