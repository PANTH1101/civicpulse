const CivicIssue = require("../models/CivicIssue");
const User = require("../models/User");
const Department = require("../models/Department");
const Notification = require("../models/Notification");

const reportIssue = async (req, res) => {
    try {
        const { title, description, category, location } = req.body;

        // Check required fields
        if (!title || !description || !category || !location) {
            return res.status(400).json({
                message: "Title, description, category and location are required"
            });
        }

        // Trim fields
        const trimmedTitle = title.trim();
        const trimmedDescription = description.trim();
        const trimmedCategory = category.trim().toUpperCase();
        const trimmedLocation = location.trim();

        // Check for empty values after trimming
        if (!trimmedTitle || !trimmedDescription || !trimmedCategory || !trimmedLocation) {
            return res.status(400).json({
                message: "Title, description, category and location cannot be empty"
            });
        }

        // Validate category
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

        if (!validCategories.includes(trimmedCategory)) {
            return res.status(400).json({
                message: "Invalid category"
            });
        }

        // Get citizen ID from authenticated user (set by middleware)
        const citizenId = req.user.userId;

        // Verify user exists and is a CITIZEN
        const user = await User.findById(citizenId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (user.role !== "CITIZEN") {
            return res.status(403).json({
                message: "Only citizens can report issues"
            });
        }

        // Create civic issue with REPORTED status
        const issue = await CivicIssue.create({
            title: trimmedTitle,
            description: trimmedDescription,
            category: trimmedCategory,
            location: trimmedLocation,
            status: "REPORTED",
            reportedBy: citizenId,
            assignedTo: null,
            department_id: null,
            verifiedBy: null
        });

        // Populate reportedBy to return user details
        await issue.populate("reportedBy", "name email");

        // Create notifications for all moderators
        const moderators = await User.find({ role: "MODERATOR" });
        
        const notificationPromises = moderators.map(moderator =>
            Notification.create({
                user_id: moderator._id,
                issue_id: issue._id,
                type: "ISSUE_REPORTED",
                message: `New civic issue reported: ${issue.title}`
            })
        );

        await Promise.all(notificationPromises);

        res.status(201).json({
            message: "Issue reported successfully",
            issue: {
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                status: issue.status,
                reportedBy: {
                    id: issue.reportedBy._id,
                    name: issue.reportedBy.name,
                    email: issue.reportedBy.email
                },
                assignedTo: issue.assignedTo,
                department_id: issue.department_id,
                verifiedBy: issue.verifiedBy,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }
        });

    } catch (error) {
        console.error("Report issue error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const rejectIssue = async (req, res) => {
    try {
        const { issueId } = req.params;

        // Get moderator ID from authenticated user
        const moderatorId = req.user.userId;

        // Verify user is a MODERATOR
        const moderator = await User.findById(moderatorId);

        if (!moderator) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (moderator.role !== "MODERATOR") {
            return res.status(403).json({
                message: "Only moderators can review issues"
            });
        }

        // Find the issue
        const issue = await CivicIssue.findById(issueId);

        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check if issue status is REPORTED
        if (issue.status !== "REPORTED") {
            return res.status(400).json({
                message: `Cannot review issue with status ${issue.status}. Only REPORTED issues can be reviewed.`
            });
        }

        // Reject the issue
        issue.status = "REJECTED";
        issue.verifiedBy = moderatorId;
        // department_id remains null
        await issue.save();

        // Populate references
        await issue.populate("reportedBy", "name email");
        await issue.populate("verifiedBy", "name email");

        // Create notification for the citizen who reported the issue
        await Notification.create({
            user_id: issue.reportedBy._id,
            issue_id: issue._id,
            type: "ISSUE_REJECTED",
            message: `Your civic issue '${issue.title}' has been rejected.`
        });

        res.status(200).json({
            message: "Issue rejected successfully",
            issue: {
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                status: issue.status,
                reportedBy: {
                    id: issue.reportedBy._id,
                    name: issue.reportedBy.name,
                    email: issue.reportedBy.email
                },
                verifiedBy: {
                    id: issue.verifiedBy._id,
                    name: issue.verifiedBy.name,
                    email: issue.verifiedBy.email
                },
                assignedTo: issue.assignedTo,
                department_id: issue.department_id,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }
        });

    } catch (error) {
        console.error("Reject issue error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const verifyIssue = async (req, res) => {
    try {
        const { issueId } = req.params;

        // Get moderator ID from authenticated user
        const moderatorId = req.user.userId;

        // Verify user is a MODERATOR
        const moderator = await User.findById(moderatorId);

        if (!moderator) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (moderator.role !== "MODERATOR") {
            return res.status(403).json({
                message: "Only moderators can review issues"
            });
        }

        // Find the issue
        const issue = await CivicIssue.findById(issueId);

        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check if issue status is REPORTED
        if (issue.status !== "REPORTED") {
            return res.status(400).json({
                message: `Cannot review issue with status ${issue.status}. Only REPORTED issues can be reviewed.`
            });
        }

        // Verify the issue (status remains REPORTED, ready for department assignment)
        issue.verifiedBy = moderatorId;
        // status remains REPORTED
        // department_id remains null
        await issue.save();

        // Populate references
        await issue.populate("reportedBy", "name email");
        await issue.populate("verifiedBy", "name email");

        // Create notification for the citizen who reported the issue
        await Notification.create({
            user_id: issue.reportedBy._id,
            issue_id: issue._id,
            type: "ISSUE_VERIFIED",
            message: `Your civic issue '${issue.title}' has been verified.`
        });

        res.status(200).json({
            message: "Issue verified successfully. Ready for department assignment.",
            issue: {
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                status: issue.status,
                reportedBy: {
                    id: issue.reportedBy._id,
                    name: issue.reportedBy.name,
                    email: issue.reportedBy.email
                },
                verifiedBy: {
                    id: issue.verifiedBy._id,
                    name: issue.verifiedBy.name,
                    email: issue.verifiedBy.email
                },
                assignedTo: issue.assignedTo,
                department_id: issue.department_id,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }
        });

    } catch (error) {
        console.error("Verify issue error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const assignDepartment = async (req, res) => {
    try {
        const { issueId } = req.params;
        const { department_id } = req.body;

        // Check required field
        if (!department_id) {
            return res.status(400).json({
                message: "department_id is required"
            });
        }

        // Get moderator ID from authenticated user
        const moderatorId = req.user.userId;

        // Verify user is a MODERATOR
        const moderator = await User.findById(moderatorId);

        if (!moderator) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (moderator.role !== "MODERATOR") {
            return res.status(403).json({
                message: "Only moderators can assign departments"
            });
        }

        // Find the issue
        const issue = await CivicIssue.findById(issueId);

        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check if issue has been verified
        if (!issue.verifiedBy) {
            return res.status(400).json({
                message: "Issue must be verified before department assignment"
            });
        }

        // Check if issue status is REPORTED
        if (issue.status !== "REPORTED") {
            return res.status(400).json({
                message: `Cannot assign department to issue with status ${issue.status}. Only verified REPORTED issues can be assigned.`
            });
        }

        // Validate department exists
        const department = await Department.findById(department_id);

        if (!department) {
            return res.status(404).json({
                message: "Department not found"
            });
        }

        // Assign department and update status
        issue.department_id = department_id;
        issue.status = "ASSIGNED";
        await issue.save();

        // Populate references
        await issue.populate("reportedBy", "name email");
        await issue.populate("verifiedBy", "name email");
        await issue.populate("department_id", "name email mobile office_address");

        // Create notifications for all department users of the assigned department
        const departmentUsers = await User.find({
            role: "DEPARTMENT",
            department_id: department_id
        });

        const notificationPromises = departmentUsers.map(user =>
            Notification.create({
                user_id: user._id,
                issue_id: issue._id,
                type: "ISSUE_ASSIGNED",
                message: `A new civic issue has been assigned to your department: ${issue.title}`
            })
        );

        await Promise.all(notificationPromises);

        res.status(200).json({
            message: "Department assigned successfully",
            issue: {
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                status: issue.status,
                reportedBy: {
                    id: issue.reportedBy._id,
                    name: issue.reportedBy.name,
                    email: issue.reportedBy.email
                },
                verifiedBy: {
                    id: issue.verifiedBy._id,
                    name: issue.verifiedBy.name,
                    email: issue.verifiedBy.email
                },
                department: {
                    id: issue.department_id._id,
                    name: issue.department_id.name,
                    email: issue.department_id.email,
                    mobile: issue.department_id.mobile,
                    office_address: issue.department_id.office_address
                },
                assignedTo: issue.assignedTo,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }
        });

    } catch (error) {
        console.error("Assign department error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const startIssue = async (req, res) => {
    try {
        const { issueId } = req.params;

        // Get user ID from authenticated user
        const userId = req.user.userId;

        // Verify user exists and is a DEPARTMENT user
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (user.role !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can start issues"
            });
        }

        // Check if user has a department_id
        if (!user.department_id) {
            return res.status(400).json({
                message: "Department user has no associated department"
            });
        }

        // Find the issue
        const issue = await CivicIssue.findById(issueId);

        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check if issue has a department
        if (!issue.department_id) {
            return res.status(400).json({
                message: "Issue has no assigned department"
            });
        }

        // Verify issue belongs to user's department
        if (issue.department_id.toString() !== user.department_id.toString()) {
            return res.status(403).json({
                message: "You can only start issues assigned to your department"
            });
        }

        // Check if issue status is ASSIGNED
        if (issue.status !== "ASSIGNED") {
            return res.status(400).json({
                message: `Cannot start issue with status ${issue.status}. Only ASSIGNED issues can be started.`
            });
        }

        // Update status to IN_PROGRESS
        issue.status = "IN_PROGRESS";
        await issue.save();

        // Populate references
        await issue.populate("reportedBy", "name email");
        await issue.populate("verifiedBy", "name email");
        await issue.populate("department_id", "name email mobile office_address");

        // Create notification for the citizen who reported the issue
        await Notification.create({
            user_id: issue.reportedBy._id,
            issue_id: issue._id,
            type: "ISSUE_STARTED",
            message: `Your civic issue '${issue.title}' is now being worked on.`
        });

        res.status(200).json({
            message: "Issue moved to IN_PROGRESS",
            issue: {
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
                    email: issue.department_id.email,
                    mobile: issue.department_id.mobile,
                    office_address: issue.department_id.office_address
                } : null,
                assignedTo: issue.assignedTo,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }
        });

    } catch (error) {
        console.error("Start issue error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const resolveIssue = async (req, res) => {
    try {
        const { issueId } = req.params;
        const { resolution_description, resolution_evidence } = req.body;

        // Validate resolution evidence fields
        if (!resolution_description || !resolution_evidence) {
            return res.status(400).json({
                message: "Resolution description and resolution evidence are required"
            });
        }

        // Trim and validate
        const trimmedDescription = resolution_description.trim();
        const trimmedEvidence = resolution_evidence.trim();

        if (!trimmedDescription || !trimmedEvidence) {
            return res.status(400).json({
                message: "Resolution description and resolution evidence cannot be empty"
            });
        }

        // Get user ID from authenticated user
        const userId = req.user.userId;

        // Verify user exists and is a DEPARTMENT user
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        if (user.role !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can resolve issues"
            });
        }

        // Check if user has a department_id
        if (!user.department_id) {
            return res.status(400).json({
                message: "Department user has no associated department"
            });
        }

        // Find the issue
        const issue = await CivicIssue.findById(issueId);

        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check if issue has a department
        if (!issue.department_id) {
            return res.status(400).json({
                message: "Issue has no assigned department"
            });
        }

        // Verify issue belongs to user's department
        if (issue.department_id.toString() !== user.department_id.toString()) {
            return res.status(403).json({
                message: "You can only resolve issues assigned to your department"
            });
        }

        // Check if issue status is IN_PROGRESS
        if (issue.status !== "IN_PROGRESS") {
            return res.status(400).json({
                message: `Cannot resolve issue with status ${issue.status}. Only IN_PROGRESS issues can be resolved.`
            });
        }

        // Update status to RESOLVED with resolution evidence
        issue.status = "RESOLVED";
        issue.resolution_description = trimmedDescription;
        issue.resolution_evidence = trimmedEvidence;
        issue.resolvedBy = userId;
        issue.resolvedAt = new Date();
        await issue.save();

        // Populate references
        await issue.populate("reportedBy", "name email");
        await issue.populate("verifiedBy", "name email");
        await issue.populate("department_id", "name email mobile office_address");
        await issue.populate("resolvedBy", "name email");

        // Create notification for the citizen who reported the issue
        await Notification.create({
            user_id: issue.reportedBy._id,
            issue_id: issue._id,
            type: "ISSUE_RESOLVED",
            message: `Your civic issue '${issue.title}' has been resolved.`
        });

        res.status(200).json({
            message: "Issue resolved successfully",
            issue: {
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
                assignedTo: issue.assignedTo,
                createdAt: issue.createdAt,
                updatedAt: issue.updatedAt
            }
        });

    } catch (error) {
        console.error("Resolve issue error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const getMyIssues = async (req, res) => {
    try {
        // Get citizen ID from authenticated user
        const userId = req.user.userId;

        // Build query - only issues reported by this user
        const query = {
            reportedBy: userId
        };

        // Optional status filter
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
                    message: "Invalid category"
                });
            }
        }

        // Pagination
        const pageNum = parseInt(page) || 1;
        const limitNum = parseInt(limit) || 10;
        const maxLimit = 50;

        // Validate pagination values
        if (pageNum < 1) {
            return res.status(400).json({
                message: "Page must be a positive integer"
            });
        }

        if (limitNum < 1) {
            return res.status(400).json({
                message: "Limit must be a positive integer"
            });
        }

        // Cap limit at maximum
        const finalLimit = limitNum > maxLimit ? maxLimit : limitNum;

        // Calculate skip
        const skip = (pageNum - 1) * finalLimit;

        // Get total count for pagination
        const total = await CivicIssue.countDocuments(query);

        // Get issues with pagination
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
            message: "My issues retrieved successfully",
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
        console.error("Get my issues error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const getSingleIssue = async (req, res) => {
    try {
        const { issueId } = req.params;
        const userId = req.user.userId;

        // Validate issue ID format
        const mongoose = require("mongoose");
        if (!mongoose.Types.ObjectId.isValid(issueId)) {
            return res.status(400).json({
                message: "Invalid issue ID"
            });
        }

        // Find the issue
        const issue = await CivicIssue.findById(issueId)
            .populate("reportedBy", "name email")
            .populate("verifiedBy", "name email")
            .populate("department_id", "name email mobile office_address")
            .populate("resolvedBy", "name email");

        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Verify issue belongs to authenticated user
        if (issue.reportedBy._id.toString() !== userId) {
            return res.status(403).json({
                message: "You can only view your own issues"
            });
        }

        res.status(200).json({
            message: "Issue retrieved successfully",
            issue: {
                id: issue._id,
                title: issue.title,
                description: issue.description,
                category: issue.category,
                location: issue.location,
                status: issue.status,
                reportedBy: {
                    id: issue.reportedBy._id,
                    name: issue.reportedBy.name,
                    email: issue.reportedBy.email
                },
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
                assignedTo: issue.assignedTo,
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
            }
        });

    } catch (error) {
        console.error("Get single issue error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    reportIssue,
    rejectIssue,
    verifyIssue,
    assignDepartment,
    startIssue,
    resolveIssue,
    getMyIssues,
    getSingleIssue
};
