const User = require("../models/User");
const Department = require("../models/Department");
const CivicIssue = require("../models/CivicIssue");

const getMyDepartment = async (req, res) => {
    try {
        // Get user ID from authenticated user
        const userId = req.user.userId;

        // Verify user is a DEPARTMENT user
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (user.role !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can access this endpoint"
            });
        }

        // Check if user has a department_id
        if (!user.department_id) {
            return res.status(400).json({
                message: "Department user has no associated department"
            });
        }

        // Get the department
        const department = await Department.findById(user.department_id);

        if (!department) {
            return res.status(404).json({
                message: "Department not found"
            });
        }

        res.status(200).json({
            message: "Department retrieved successfully",
            department: {
                id: department._id,
                name: department.name,
                email: department.email,
                mobile: department.mobile,
                office_address: department.office_address
            }
        });

    } catch (error) {
        console.error("Get my department error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const getMyAssignedIssues = async (req, res) => {
    try {
        // Get user ID from authenticated user
        const userId = req.user.userId;

        // Verify user is a DEPARTMENT user
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (user.role !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can access this endpoint"
            });
        }

        // Check if user has a department_id
        if (!user.department_id) {
            return res.status(400).json({
                message: "Department user has no associated department"
            });
        }

        // Build query - filter by department_id
        const query = {
            department_id: user.department_id
        };

        // Optional status filter
        const { status } = req.query;
        if (status) {
            const validStatuses = ["REPORTED", "ASSIGNED", "IN_PROGRESS", "RESOLVED", "REJECTED"];
            if (validStatuses.includes(status.toUpperCase())) {
                query.status = status.toUpperCase();
            } else {
                return res.status(400).json({
                    message: "Invalid status. Valid values: REPORTED, ASSIGNED, IN_PROGRESS, RESOLVED, REJECTED"
                });
            }
        }

        // Get issues assigned to this department
        const issues = await CivicIssue.find(query)
            .populate("reportedBy", "name email")
            .populate("verifiedBy", "name email")
            .populate("department_id", "name email mobile office_address")
            .sort({ createdAt: -1 });

        res.status(200).json({
            message: "Issues retrieved successfully",
            count: issues.length,
            issues: issues.map(issue => ({
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                status: issue.status,
                reportedBy: issue.reportedBy ? {
                    id: issue.reportedBy._id,
                    name: issue.reportedBy.name,
                    email: issue.reportedBy.email
                } : null,
                verifiedBy: issue.verifiedBy ? {
                    id: issue.verifiedBy._id,
                    name: issue.verifiedBy.name,
                    email: issue.verifiedBy.email
                } : null,
                department: issue.department_id ? {
                    id: issue.department_id._id,
                    name: issue.department_id.name,
                    email: issue.department_id.email
                } : null,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }))
        });

    } catch (error) {
        console.error("Get my assigned issues error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    getMyDepartment,
    getMyAssignedIssues
};
