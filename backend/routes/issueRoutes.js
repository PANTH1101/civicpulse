const express = require("express");
const {
    reportIssue,
    verifyIssue,
    assignDepartment,
    startIssue,
    resolveIssue,
    getMyIssues,
    getSingleIssue,
    getModeratorIssues,
    getPendingModeration
} = require("../controllers/issueController");
const {
    getIssueFeedback,
    getIssueFeedbackSummary
} = require("../controllers/feedbackController");
const protect = require("../middleware/authMiddleware");
const { upload } = require("../config/cloudinary");

const router = express.Router();

// Multer error handler middleware
const handleMulterError = (err, req, res, next) => {
    if (err) {
        if (err.code === "LIMIT_FILE_SIZE") {
            return res.status(400).json({
                message: "File too large. Maximum size is 5MB."
            });
        }
        if (err.message) {
            return res.status(400).json({
                message: err.message
            });
        }
    }
    next();
};

// POST /api/issues - Create issue with optional image upload
router.post("/", protect, upload.single("image"), handleMulterError, reportIssue);

// Moderator routes (must come before /:issueId to avoid conflicts)
router.get("/moderator/pending", protect, getPendingModeration);
router.get("/moderator", protect, getModeratorIssues);

router.get("/my-issues", protect, getMyIssues);
router.get("/:issueId", protect, getSingleIssue);
router.get("/:issueId/feedback", protect, getIssueFeedback);
router.get("/:issueId/feedback/summary", protect, getIssueFeedbackSummary);
router.patch("/:issueId/verify", protect, verifyIssue);
router.patch("/:issueId/assign", protect, assignDepartment);
router.patch("/:issueId/start", protect, startIssue);
router.patch("/:issueId/resolve", protect, upload.single("evidence"), handleMulterError, resolveIssue);

module.exports = router;
