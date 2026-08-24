const express = require("express");
const {
    getMyDepartment,
    getMyAssignedIssues
} = require("../controllers/departmentController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/me", protect, getMyDepartment);
router.get("/my-issues", protect, getMyAssignedIssues);

module.exports = router;
