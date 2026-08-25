const PublicNotice = require("../models/PublicNotice");
const User = require("../models/User");
const mongoose = require("mongoose");

// Create a new public notice (DRAFT)
// POST /api/notices
const createNotice = async (req, res) => {
    try {
        const { title, content, category } = req.body;
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Only MODERATOR and DEPARTMENT users can create notices
        if (userRole !== "MODERATOR" && userRole !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only authorized staff (moderators and department users) can create public notices"
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

        // Create notice in DRAFT status
        const notice = await PublicNotice.create({
            title: title.trim(),
            content: content.trim(),
            category: category.toUpperCase(),
            status: "DRAFT",
            createdBy: userId
        });

        // Populate creator info
        await notice.populate("createdBy", "name email role");

        return res.status(201).json({
            message: "Public notice created successfully as draft",
            notice: {
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
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

        // Only MODERATOR and DEPARTMENT users can publish notices
        if (userRole !== "MODERATOR" && userRole !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only authorized staff (moderators and department users) can publish notices"
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

        // Populate creator and publisher info
        await notice.populate("createdBy", "name email role");
        await notice.populate("publishedBy", "name email role");

        return res.status(200).json({
            message: "Notice published successfully",
            notice: {
                id: notice._id,
                title: notice.title,
                content: notice.content,
                category: notice.category,
                status: notice.status,
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
            .populate("publishedBy", "name email role");

        if (!notice) {
            return res.status(404).json({
                message: "Notice not found"
            });
        }

        // If notice is DRAFT, only authorized staff can view it
        if (notice.status === "DRAFT") {
            if (userRole !== "MODERATOR" && userRole !== "DEPARTMENT") {
                return res.status(403).json({
                    message: "Draft notices are not accessible to citizens"
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

// Get all notices (including drafts) - for authorized staff only
// GET /api/notices/all
const getAllNotices = async (req, res) => {
    try {
        const userRole = req.user.role;

        // Only MODERATOR and DEPARTMENT users can view all notices including drafts
        if (userRole !== "MODERATOR" && userRole !== "DEPARTMENT") {
            return res.status(403).json({
                message: "Only authorized staff can view all notices including drafts"
            });
        }

        // Find all notices, sorted by createdAt descending
        const notices = await PublicNotice.find()
            .populate("createdBy", "name email role")
            .populate("publishedBy", "name email role")
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
