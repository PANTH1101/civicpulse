const express = require("express");
const {
    reportIssue,
    rejectIssue,
    verifyIssue,
    assignDepartment,
    startIssue,
    resolveIssue,
    getMyIssues,
    getSingleIssue
} = require("../controllers/issueController");
const {
    getIssueFeedback,
    getIssueFeedbackSummary
} = require("../controllers/feedbackController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", protect, reportIssue);
router.get("/my-issues", protect, getMyIssues);
router.get("/:issueId", protect, getSingleIssue);
router.get("/:issueId/feedback", protect, getIssueFeedback);
router.get("/:issueId/feedback/summary", protect, getIssueFeedbackSummary);
router.patch("/:issueId/reject", protect, rejectIssue);
router.patch("/:issueId/verify", protect, verifyIssue);
router.patch("/:issueId/assign", protect, assignDepartment);
router.patch("/:issueId/start", protect, startIssue);
router.patch("/:issueId/resolve", protect, resolveIssue);

module.exports = router;
