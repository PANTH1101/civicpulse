const Feedback = require("../models/Feedback");
const CivicIssue = require("../models/CivicIssue");
const User = require("../models/User");
const mongoose = require("mongoose");

// Submit feedback for a resolved issue
// POST /api/feedback
const submitFeedback = async (req, res) => {
    try {
        const { issue_id, rating, comment } = req.body;
        const userId = req.user.userId;

        // Validate required fields
        if (!issue_id) {
            return res.status(400).json({
                message: "Issue ID is required"
            });
        }

        if (!rating && rating !== 0) {
            return res.status(400).json({
                message: "Rating is required"
            });
        }

        // Validate issue_id format
        if (!mongoose.Types.ObjectId.isValid(issue_id)) {
            return res.status(400).json({
                message: "Invalid issue ID format"
            });
        }

        // Validate rating
        if (!Number.isInteger(rating)) {
            return res.status(400).json({
                message: "Rating must be an integer"
            });
        }

        if (rating < 1 || rating > 5) {
            return res.status(400).json({
                message: "Rating must be between 1 and 5"
            });
        }

        // Validate comment if provided
        let trimmedComment = null;
        if (comment) {
            trimmedComment = comment.trim();
            if (trimmedComment.length === 0) {
                trimmedComment = null;
            }
        }

        // Check if issue exists
        const issue = await CivicIssue.findById(issue_id);
        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check if issue is resolved
        if (issue.status !== "RESOLVED") {
            return res.status(400).json({
                message: "Feedback can only be submitted for resolved issues"
            });
        }

        // Check ownership - only the citizen who reported the issue can submit feedback
        if (issue.reportedBy.toString() !== userId) {
            return res.status(403).json({
                message: "Access denied: You can only submit feedback for issues you reported"
            });
        }

        // Check if feedback already exists for this issue
        const existingFeedback = await Feedback.findOne({ issue_id });
        if (existingFeedback) {
            return res.status(409).json({
                message: "Feedback has already been submitted for this issue"
            });
        }

        // Create feedback
        const feedback = await Feedback.create({
            issue_id,
            user_id: userId,
            rating,
            comment: trimmedComment
        });

        // Return success response
        return res.status(201).json({
            message: "Feedback submitted successfully",
            feedback: {
                id: feedback._id,
                issue_id: feedback.issue_id,
                rating: feedback.rating,
                comment: feedback.comment,
                createdAt: feedback.createdAt
            }
        });

    } catch (error) {
        // Handle duplicate key error from database
        if (error.code === 11000) {
            return res.status(409).json({
                message: "Feedback has already been submitted for this issue"
            });
        }

        console.error("Error submitting feedback:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Get all feedback submitted by authenticated user
// GET /api/feedback/my
const getMyFeedback = async (req, res) => {
    try {
        const userId = req.user.userId;

        // Find all feedback by this user
        const feedback = await Feedback.find({ user_id: userId })
            .populate({
                path: "issue_id",
                select: "title status category location createdAt"
            })
            .sort({ createdAt: -1 });

        return res.status(200).json({
            message: "My feedback retrieved successfully",
            count: feedback.length,
            feedback: feedback.map(f => ({
                id: f._id,
                issue: f.issue_id ? {
                    id: f.issue_id._id,
                    title: f.issue_id.title,
                    status: f.issue_id.status,
                    category: f.issue_id.category,
                    location: f.issue_id.location,
                    createdAt: f.issue_id.createdAt
                } : null,
                rating: f.rating,
                comment: f.comment,
                createdAt: f.createdAt,
                updatedAt: f.updatedAt
            }))
        });

    } catch (error) {
        console.error("Error getting my feedback:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Get feedback for a specific issue
// GET /api/issues/:issueId/feedback
const getIssueFeedback = async (req, res) => {
    try {
        const { issueId } = req.params;
        const userId = req.user.userId;
        const userRole = req.user.role;

        // Validate issue ID format
        if (!mongoose.Types.ObjectId.isValid(issueId)) {
            return res.status(400).json({
                message: "Invalid issue ID format"
            });
        }

        // Check if issue exists
        const issue = await CivicIssue.findById(issueId);
        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Get user to check department_id if needed
        const user = await User.findById(userId);
        if (!user) {
            return res.status(401).json({
                message: "User not found"
            });
        }

        // Authorization check
        let isAuthorized = false;

        // Citizen who reported the issue can view feedback
        if (issue.reportedBy.toString() === userId) {
            isAuthorized = true;
        }

        // Moderators can view feedback
        if (userRole === "MODERATOR") {
            isAuthorized = true;
        }

        // Department users can view feedback for issues assigned to their department
        if (userRole === "DEPARTMENT" && user.department_id && issue.department_id) {
            if (user.department_id.toString() === issue.department_id.toString()) {
                isAuthorized = true;
            }
        }

        if (!isAuthorized) {
            return res.status(403).json({
                message: "Access denied: You are not authorized to view this feedback"
            });
        }

        // Find feedback for this issue
        const feedback = await Feedback.findOne({ issue_id: issueId })
            .populate({
                path: "issue_id",
                select: "title status category location"
            });

        if (!feedback) {
            return res.status(404).json({
                message: "No feedback found for this issue"
            });
        }

        return res.status(200).json({
            message: "Issue feedback retrieved successfully",
            feedback: {
                id: feedback._id,
                issue: {
                    id: feedback.issue_id._id,
                    title: feedback.issue_id.title,
                    status: feedback.issue_id.status,
                    category: feedback.issue_id.category,
                    location: feedback.issue_id.location
                },
                rating: feedback.rating,
                comment: feedback.comment,
                createdAt: feedback.createdAt,
                updatedAt: feedback.updatedAt
            }
        });

    } catch (error) {
        console.error("Error getting issue feedback:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

// Get feedback summary for a specific issue
// GET /api/issues/:issueId/feedback/summary
const getIssueFeedbackSummary = async (req, res) => {
    try {
        const { issueId } = req.params;
        const userId = req.user.userId;

        // Validate issue ID format
        if (!mongoose.Types.ObjectId.isValid(issueId)) {
            return res.status(400).json({
                message: "Invalid issue ID format"
            });
        }

        // Check if issue exists
        const issue = await CivicIssue.findById(issueId);
        if (!issue) {
            return res.status(404).json({
                message: "Issue not found"
            });
        }

        // Check ownership - only the citizen who reported can view summary
        if (issue.reportedBy.toString() !== userId) {
            return res.status(403).json({
                message: "Access denied: You can only view summary for issues you reported"
            });
        }

        // Find feedback for this issue
        const feedback = await Feedback.findOne({ issue_id: issueId });

        if (!feedback) {
            return res.status(200).json({
                issue_id: issueId,
                submitted: false,
                rating: null,
                comment: null
            });
        }

        return res.status(200).json({
            issue_id: issueId,
            submitted: true,
            rating: feedback.rating,
            comment: feedback.comment,
            createdAt: feedback.createdAt
        });

    } catch (error) {
        console.error("Error getting feedback summary:", error);
        return res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    submitFeedback,
    getMyFeedback,
    getIssueFeedback,
    getIssueFeedbackSummary
};
