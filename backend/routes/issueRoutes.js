const express = require("express");
const {
    reportIssue,
    rejectIssue,
    verifyIssue,
    assignDepartment,
    startIssue,
    resolveIssue
} = require("../controllers/issueController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/", protect, reportIssue);
router.patch("/:issueId/reject", protect, rejectIssue);
router.patch("/:issueId/verify", protect, verifyIssue);
router.patch("/:issueId/assign", protect, assignDepartment);
router.patch("/:issueId/start", protect, startIssue);
router.patch("/:issueId/resolve", protect, resolveIssue);

module.exports = router;
