const express = require("express");
const router = express.Router();
const protect = require("../middleware/authMiddleware");
const {
    createNotice,
    publishNotice,
    getPublishedNotices,
    getSingleNotice,
    getAllNotices
} = require("../controllers/publicNoticeController");

// GET /api/notices - Get all published notices (public access for authenticated users)
router.get("/", protect, getPublishedNotices);

// GET /api/notices/all - Get all notices including drafts (authorized staff only)
router.get("/all", protect, getAllNotices);

// GET /api/notices/:noticeId - Get single notice
router.get("/:noticeId", protect, getSingleNotice);

// POST /api/notices - Create a new notice (authorized staff only)
router.post("/", protect, createNotice);

// PATCH /api/notices/:noticeId/publish - Publish a notice (authorized staff only)
router.patch("/:noticeId/publish", protect, publishNotice);

module.exports = router;
