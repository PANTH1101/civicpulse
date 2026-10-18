const PublicNotice = require("../models/PublicNotice");
const User = require("../models/User");
const Notification = require("../models/Notification");
const mongoose = require("mongoose");

// Create a new public notice (DRAFT)
// POST /api/notices
const createNotice = async (req, res) => {
    try {
        const { title, content, category, startDate, endDate } = req.body;
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Only DEPARTMENT users can create notices
        if (userRole !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can create public notices"
            });
        }

        // Get user to retrieve their department_id
        const user = await User.findById(userId);
        if (!user || !user.department_id) {
            return res.status(400).json({
                message: "User is not associated with a department"
            });
        }

        // Validate required fields
        if (!title || !content || !category) {
            return res.status(400).json({
                message: "Title, content, and category are required"
            });
        }

        // Validate category
        const validCategories = ["GENERAL", "EMERGENCY", "MAINTENANCE", "EVENT", "POLICY", "ANNOUNCEMENT", "OTHER"];
        if (!validCategories.includes(category.toUpperCase())) {
            return res.status(400).json({
                message: "Invalid category. Valid values: GENERAL, EMERGENCY, MAINTENANCE, EVENT, POLICY, ANNOUNCEMENT, OTHER"
            });
        }

        // Validate date range if both provided
        if (startDate && endDate) {
            const start = new Date(startDate);
            const end = new Date(endDate);
            if (end < start) {
                return res.status(400).json({
                    message: "End date cannot be earlier than start date"
                });
            }
        }

        // Create notice in DRAFT status with department_id from logged-in user
        const noticeData = {
            title: title.trim(),
            content: content.trim(),
            category: category.toUpperCase(),
            department_id: user.department_id,
            status: "DRAFT",
            createdBy: userId
        };

        // Add optional dates if provided
        if (startDate) noticeData.startDate = new Date(startDate);
        if (endDate) noticeData.endDate = new Date(endDate);

        const notice = await PublicNotice.create(noticeData);

        // Populate creator and department info
        await notice.populate("createdBy", "name email role");
        await notice.populate("department_id", "name email");

        return res.status(201).json({
            message: "Public notice created successfully as draft",
            notice: {
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
                department: {
                    id: notice.department_id._id,
                    name: notice.department_id.name
                },
                startDate: notice.startDate,
                endDate: notice.endDate,
                createdBy: {
                    id: notice.createdBy._id,
                    name: notice.createdBy.name,
                    email: notice.createdBy.email,
                    role: notice.createdBy.role
                },
                createdAt: notice.createdAt,
                updatedAt: notice.updatedAt
            }
        });

    } catch (error) {
        console.error("Error creating notice:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Publish a notice (change status from DRAFT to PUBLISHED)
// PATCH /api/notices/:noticeId/publish
const publishNotice = async (req, res) => {
    try {
        const { noticeId } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Only DEPARTMENT users can publish notices
        if (userRole !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can publish notices"
            });
        }

        // Get user to check their department_id
        const user = await User.findById(userId);
        if (!user || !user.department_id) {
            return res.status(400).json({
                message: "User is not associated with a department"
            });
        }

        // Validate notice ID
        if (!mongoose.Types.ObjectId.isValid(noticeId)) {
            return res.status(400).json({
                message: "Invalid notice ID format"
            });
        }

        // Find the notice
        const notice = await PublicNotice.findById(noticeId);
        if (!notice) {
            return res.status(404).json({
                message: "Notice not found"
            });
        }

        // Verify notice belongs to user's department
        if (notice.department_id.toString() !== user.department_id.toString()) {
            return res.status(403).json({
                message: "You can only publish notices from your own department"
            });
        }

        // Check if already published
        if (notice.status === "PUBLISHED") {
            return res.status(400).json({
                message: "Notice is already published"
            });
        }

        // Update to published
        notice.status = "PUBLISHED";
        notice.publishedBy = userId;
        notice.publishedAt = new Date();
        await notice.save();

        // Populate creator, publisher, and department info
        await notice.populate("createdBy", "name email role");
        await notice.populate("publishedBy", "name email role");
        await notice.populate("department_id", "name email");

        // Create notifications for ALL CITIZEN users
        const citizens = await User.find({ role: "CITIZEN" });

        // Check for existing notifications to prevent duplicates
        const existingNotifications = await Notification.find({
            notice_id: notice._id,
            type: "PUBLIC_NOTICE_PUBLISHED"
        }).distinct("user_id");

        // Filter out citizens who already received notification for this notice
        const citizensToNotify = citizens.filter(
            citizen => !existingNotifications.some(
                existingUserId => existingUserId.toString() === citizen._id.toString()
            )
        );

        // Create notifications for citizens who haven't received one yet
        if (citizensToNotify.length > 0) {
            const notificationPromises = citizensToNotify.map(citizen =>
                Notification.create({
                    user_id: citizen._id,
                    issue_id: null,
                    service_request_id: null,
                    notice_id: notice._id,
                    type: "PUBLIC_NOTICE_PUBLISHED",
                    message: `New public notice published: ${notice.title}`,
                    is_read: false
                })
            );

            await Promise.all(notificationPromises);
        }

        return res.status(200).json({
            message: "Notice published successfully",
            notice: {
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
                department: {
                    id: notice.department_id._id,
                    name: notice.department_id.name
                },
                startDate: notice.startDate,
                endDate: notice.endDate,
                createdBy: {
                    id: notice.createdBy._id,
                    name: notice.createdBy.name,
                    email: notice.createdBy.email,
                    role: notice.createdBy.role
                },
                publishedBy: {
                    id: notice.publishedBy._id,
                    name: notice.publishedBy.name,
                    email: notice.publishedBy.email,
                    role: notice.publishedBy.role
                },
                publishedAt: notice.publishedAt,
                createdAt: notice.createdAt,
                updatedAt: notice.updatedAt
            }
        });

    } catch (error) {
        console.error("Error publishing notice:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Get all published notices (for citizens and all users)
// GET /api/notices
const getPublishedNotices = async (req, res) => {
    try {
        // Find all published notices, sorted by publishedAt descending
        const notices = await PublicNotice.find({ status: "PUBLISHED" })
            .populate("createdBy", "name email role")
            .populate("publishedBy", "name email role")
            .populate("department_id", "name email")
            .sort({ publishedAt: -1 });

        return res.status(200).json({
            message: "Published notices retrieved successfully",
            count: notices.length,
            notices: notices.map(notice => ({
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
                department: notice.department_id ? {
                    id: notice.department_id._id,
                    name: notice.department_id.name
                } : null,
                startDate: notice.startDate,
                endDate: notice.endDate,
                createdBy: {
                    id: notice.createdBy._id,
                    name: notice.createdBy.name,
                    role: notice.createdBy.role
                },
                publishedBy: notice.publishedBy ? {
                    id: notice.publishedBy._id,
                    name: notice.publishedBy.name,
                    role: notice.publishedBy.role
                } : null,
                publishedAt: notice.publishedAt,
                createdAt: notice.createdAt
            }))
        });

    } catch (error) {
        console.error("Error getting published notices:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Get a single notice by ID
// GET /api/notices/:noticeId
const getSingleNotice = async (req, res) => {
    try {
        const { noticeId } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Validate notice ID
        if (!mongoose.Types.ObjectId.isValid(noticeId)) {
            return res.status(400).json({
                message: "Invalid notice ID format"
            });
        }

        // Find the notice
        const notice = await PublicNotice.findById(noticeId)
            .populate("createdBy", "name email role")
            .populate("publishedBy", "name email role")
            .populate("department_id", "name email office_address mobile");

        if (!notice) {
            return res.status(404).json({
                message: "Notice not found"
            });
        }

        // If notice is DRAFT, only department users from the same department can view it
        if (notice.status === "DRAFT") {
            if (userRole !== "DEPARTMENT") {
                return res.status(403).json({
                    message: "Draft notices are not accessible to citizens"
                });
            }
            // Check if user belongs to the same department
            const user = await User.findById(userId);
            if (!user.department_id || user.department_id.toString() !== notice.department_id._id.toString()) {
                return res.status(403).json({
                    message: "You can only view draft notices from your own department"
                });
            }
        }

        return res.status(200).json({
            message: "Notice retrieved successfully",
            notice: {
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
                department: notice.department_id ? {
                    id: notice.department_id._id,
                    name: notice.department_id.name,
                    email: notice.department_id.email,
                    mobile: notice.department_id.mobile,
                    address: notice.department_id.office_address
                } : null,
                startDate: notice.startDate,
                endDate: notice.endDate,
                createdBy: {
                    id: notice.createdBy._id,
                    name: notice.createdBy.name,
                    email: notice.createdBy.email,
                    role: notice.createdBy.role
                },
                publishedBy: notice.publishedBy ? {
                    id: notice.publishedBy._id,
                    name: notice.publishedBy.name,
                    email: notice.publishedBy.email,
                    role: notice.publishedBy.role
                } : null,
                publishedAt: notice.publishedAt,
                createdAt: notice.createdAt,
                updatedAt: notice.updatedAt
            }
        });

    } catch (error) {
        console.error("Error getting notice:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Get all notices (including drafts) - for department users only
// GET /api/notices/all
const getAllNotices = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Only DEPARTMENT users can view all notices
        if (userRole !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only department users can view all notices"
            });
        }

        // Get user's department
        const user = await User.findById(userId);
        if (!user || !user.department_id) {
            return res.status(400).json({
                message: "User is not associated with a department"
            });
        }

        // Find all notices from user's department, sorted by createdAt descending
        const notices = await PublicNotice.find({ department_id: user.department_id })
            .populate("createdBy", "name email role")
            .populate("publishedBy", "name email role")
            .populate("department_id", "name email")
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: "All notices retrieved successfully",
            count: notices.length,
            notices: notices.map(notice => ({
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
                department: notice.department_id ? {
                    id: notice.department_id._id,
                    name: notice.department_id.name
                } : null,
                startDate: notice.startDate,
                endDate: notice.endDate,
                createdBy: {
                    id: notice.createdBy._id,
                    name: notice.createdBy.name,
                    email: notice.createdBy.email,
                    role: notice.createdBy.role
                },
                publishedBy: notice.publishedBy ? {
                    id: notice.publishedBy._id,
                    name: notice.publishedBy.name,
                    email: notice.publishedBy.email,
                    role: notice.publishedBy.role
                } : null,
                publishedAt: notice.publishedAt,
                createdAt: notice.createdAt,
                updatedAt: notice.updatedAt
            }))
        });

    } catch (error) {
        console.error("Error getting all notices:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    createNotice,
    publishNotice,
    getPublishedNotices,
    getSingleNotice,
    getAllNotices
};
