const express = require("express");
const {
    getUserById,
    updateUserById
} = require("../controllers/userController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

// Specification-compliant user profile endpoints
// GET /api/v1/users/:id - Get own profile (self-only access)
// PUT /api/v1/users/:id - Update own profile (self-only access)
router.get("/:id", protect, getUserById);
router.put("/:id", protect, updateUserById);

module.exports = router;
