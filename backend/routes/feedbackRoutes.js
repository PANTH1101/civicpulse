const express = require("express");
const router = express.Router();
const protect = require("../middleware/authMiddleware");
const {
    submitFeedback,
    getMyFeedback
} = require("../controllers/feedbackController");

// POST /api/feedback - Submit feedback for a resolved issue
router.post("/", protect, submitFeedback);

// GET /api/feedback/my - Get all feedback submitted by authenticated user
router.get("/my", protect, getMyFeedback);

module.exports = router;
