const express = require("express");
const {
    getMyDepartment,
    getMyAssignedIssues
} = require("../controllers/departmentController");
const {
    getDepartmentServiceRequests
} = require("../controllers/departmentServiceController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

// Existing civic issue routes (unchanged)
router.get("/me", protect, getMyDepartment);
router.get("/my-issues", protect, getMyAssignedIssues);

// Municipal service request route for department
router.get("/service-requests", protect, getDepartmentServiceRequests);

module.exports = router;
