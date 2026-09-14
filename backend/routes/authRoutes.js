const express = require("express");
const {
    registerUser,
    loginUser,
    getProtectedData,
    getProfile,
    updateProfile
} = require("../controllers/authController");
const protect = require("../middleware/authMiddleware");

const router = express.Router();

router.post("/register", registerUser);
router.post("/login", loginUser);
router.get("/protected", protect, getProtectedData);
router.get("/profile", protect, getProfile);
router.patch("/profile", protect, updateProfile);

module.exports = router;