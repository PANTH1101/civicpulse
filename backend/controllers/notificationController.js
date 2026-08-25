const Notification = require("../models/Notification");
const User = require("../models/User");

const getNotifications = async (req, res) => {
    try {
        // Get user ID from authenticated user
        const userId = req.user.userId;

        // Find all notifications for this user
        const notifications = await Notification.find({ user_id: userId })
            .populate("issue_id", "title description category location status")
            .sort({ createdAt: -1 });

        res.status(200).json({
            message: "Notifications retrieved successfully",
            count: notifications.length,
            notifications: notifications.map(notification => ({
                id: notification._id,
                type: notification.type,
                message: notification.message,
                is_read: notification.is_read,
                issue: notification.issue_id ? {
                    id: notification.issue_id._id,
                    title: notification.issue_id.title,
                    category: notification.issue_id.category,
                    status: notification.issue_id.status
                } : null,
                createdAt: notification.createdAt,
                updatedAt: notification.updatedAt
            }))
        });

    } catch (error) {
        console.error("Get notifications error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const getUnreadNotifications = async (req, res) => {
    try {
        // Get user ID from authenticated user
        const userId = req.user.userId;

        // Find only unread notifications for this user
        const notifications = await Notification.find({
            user_id: userId,
            is_read: false
        })
            .populate("issue_id", "title description category location status")
            .sort({ createdAt: -1 });

        res.status(200).json({
            message: "Unread notifications retrieved successfully",
            count: notifications.length,
            notifications: notifications.map(notification => ({
                id: notification._id,
                type: notification.type,
                message: notification.message,
                is_read: notification.is_read,
                issue: notification.issue_id ? {
                    id: notification.issue_id._id,
                    title: notification.issue_id.title,
                    category: notification.issue_id.category,
                    status: notification.issue_id.status
                } : null,
                createdAt: notification.createdAt,
                updatedAt: notification.updatedAt
            }))
        });

    } catch (error) {
        console.error("Get unread notifications error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const markNotificationAsRead = async (req, res) => {
    try {
        const { notificationId } = req.params;
        const userId = req.user.userId;

        // Find the notification
        const notification = await Notification.findById(notificationId);

        if (!notification) {
            return res.status(404).json({
                message: "Notification not found"
            });
        }

        // Verify notification belongs to authenticated user
        if (notification.user_id.toString() !== userId) {
            return res.status(403).json({
                message: "You can only mark your own notifications as read"
            });
        }

        // Mark as read
        notification.is_read = true;
        await notification.save();

        res.status(200).json({
            message: "Notification marked as read",
            notification: {
                id: notification._id,
                type: notification.type,
                message: notification.message,
                is_read: notification.is_read,
                createdAt: notification.createdAt,
                updatedAt: notification.updatedAt
            }
        });

    } catch (error) {
        console.error("Mark notification as read error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const markAllNotificationsAsRead = async (req, res) => {
    try {
        const userId = req.user.userId;

        // Update all unread notifications for this user
        const result = await Notification.updateMany(
            {
                user_id: userId,
                is_read: false
            },
            {
                is_read: true
            }
        );

        res.status(200).json({
            message: "All notifications marked as read",
            updated: result.modifiedCount
        });

    } catch (error) {
        console.error("Mark all notifications as read error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    getNotifications,
    getUnreadNotifications,
    markNotificationAsRead,
    markAllNotificationsAsRead
};
