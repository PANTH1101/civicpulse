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

        // Build query - ALWAYS filter by authenticated user's department_id
        // SECURITY: Never trust client-provided department_id
        const query = {
            department_id: user.department_id
        };

        // Optional filters
        const { status, category, page, limit } = req.query;

        // Validate and apply status filter
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

        // Validate and apply category filter
        if (category) {
            const validCategories = [
                "ROADS",
                "WATER",
                "ELECTRICITY",
                "SANITATION",
                "PUBLIC_SAFETY",
                "HEALTHCARE",
                "EDUCATION",
                "ENVIRONMENT",
                "OTHER"
            ];
            if (validCategories.includes(category.toUpperCase())) {
                query.category = category.toUpperCase();
            } else {
                return res.status(400).json({
                    message: "Invalid category. Valid values: ROADS, WATER, ELECTRICITY, SANITATION, PUBLIC_SAFETY, HEALTHCARE, EDUCATION, ENVIRONMENT, OTHER"
                });
            }
        }

        // Pagination
        const pageNum = parseInt(page) || 1;
        const limitNum = parseInt(limit);
        const maxLimit = 50;

        // Validate pagination values
        if (pageNum < 1) {
            return res.status(400).json({
                message: "Page must be a positive integer"
            });
        }

        // Check if limit was provided and is valid
        if (limit !== undefined) {
            if (isNaN(limitNum) || limitNum < 1) {
                return res.status(400).json({
                    message: "Limit must be a positive integer"
                });
            }
        }
        
        // Use default if not provided
        const finalLimit = (limit !== undefined && !isNaN(limitNum) && limitNum > 0) 
            ? (limitNum > maxLimit ? maxLimit : limitNum)
            : 10;

        // Calculate skip
        const skip = (pageNum - 1) * finalLimit;

        // Get total count for pagination
        const total = await CivicIssue.countDocuments(query);

        // Get issues assigned to this department with pagination
        const issues = await CivicIssue.find(query)
            .populate("reportedBy", "name email")
            .populate("verifiedBy", "name email")
            .populate("department_id", "name email mobile office_address")
            .populate("resolvedBy", "name email")
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(finalLimit);

        // Calculate total pages
        const totalPages = Math.ceil(total / finalLimit);

        res.status(200).json({
            message: "Department issues retrieved successfully",
            count: issues.length,
            total: total,
            page: pageNum,
            limit: finalLimit,
            totalPages: totalPages,
            issues: issues.map(issue => ({
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                image_url: issue.image_url,
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
                    email: issue.department_id.email,
                    mobile: issue.department_id.mobile,
                    office_address: issue.department_id.office_address
                } : null,
                resolution_description: issue.resolution_description,
                resolution_evidence: issue.resolution_evidence,
                resolvedBy: issue.resolvedBy ? {
                    id: issue.resolvedBy._id,
                    name: issue.resolvedBy.name,
                    email: issue.resolvedBy.email
                } : null,
                resolvedAt: issue.resolvedAt,
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
