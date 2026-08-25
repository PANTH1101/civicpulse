const express = require("express");
const {
    getNotifications,
    getUnreadNotifications,
    markNotificationAsRead,
    markAllNotificationsAsRead
} = require("../controllers/notificationController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

router.get("/", protect, getNotifications);
router.get("/unread", protect, getUnreadNotifications);
router.patch("/:notificationId/read", protect, markNotificationAsRead);
router.patch("/read-all", protect, markAllNotificationsAsRead);

module.exports = router;
