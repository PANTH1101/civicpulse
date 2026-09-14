const User = require("../models/User");
const mongoose = require("mongoose");

// ---------------------------------------------------------------------------
// GET /api/v1/users/:id
// Specification-compliant: User can only access their own profile
// ---------------------------------------------------------------------------
const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const authenticatedUserId = req.user.userId;

        // Validate ID format
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid user ID format"
            });
        }

        // CRITICAL: Self-only access validation
        // User can ONLY access their own profile
        if (id !== authenticatedUserId.toString()) {
            return res.status(403).json({
                message: "Forbidden. You can only access your own profile."
            });
        }

        // Fetch user from database (exclude password)
        const user = await User.findById(id).select("-password");

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        res.status(200).json({
            id: user._id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role
        });

    } catch (error) {
        console.error("Get user by ID error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

// ---------------------------------------------------------------------------
// PUT /api/v1/users/:id
// Specification-compliant: User can only update their own profile
// ---------------------------------------------------------------------------
const updateUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const authenticatedUserId = req.user.userId;

        // Validate ID format
        if (!mongoose.Types.ObjectId.isValid(id)) {
            return res.status(400).json({
                message: "Invalid user ID format"
            });
        }

        // CRITICAL: Self-only access validation
        // User can ONLY update their own profile
        if (id !== authenticatedUserId.toString()) {
            return res.status(403).json({
                message: "Forbidden. You can only update your own profile."
            });
        }

        // Fetch user from database
        const user = await User.findById(id);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        // Extract fields from request body
        const { name, email, phone, role, department_id, password } = req.body;

        // CRITICAL SECURITY: Reject attempts to modify restricted fields
        if (role !== undefined) {
            return res.status(400).json({
                message: "Cannot modify role"
            });
        }

        if (department_id !== undefined) {
            return res.status(400).json({
                message: "Cannot modify department_id"
            });
        }

        if (password !== undefined) {
            return res.status(400).json({
                message: "Cannot modify password through this endpoint"
            });
        }

        // Check if at least one allowed field is provided
        if (name === undefined && email === undefined && phone === undefined) {
            return res.status(400).json({
                message: "Please provide at least one field to update (name, email, or phone)"
            });
        }

        // Update name if provided
        if (name !== undefined) {
            const trimmedName = name.trim();

            if (!trimmedName) {
                return res.status(400).json({
                    message: "Name cannot be empty"
                });
            }

            user.name = trimmedName;
        }

        // Update phone if provided
        if (phone !== undefined) {
            if (phone === null || phone === "") {
                // Allow clearing phone
                user.phone = null;
            } else {
                const trimmedPhone = phone.trim();
                user.phone = trimmedPhone;
            }
        }

        // Update email if provided
        if (email !== undefined) {
            const trimmedEmail = email.trim().toLowerCase();

            if (!trimmedEmail) {
                return res.status(400).json({
                    message: "Email cannot be empty"
                });
            }

            // Validate email format
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            if (!emailRegex.test(trimmedEmail)) {
                return res.status(400).json({
                    message: "Invalid email format"
                });
            }

            // Check if email is different from current email
            if (trimmedEmail !== user.email) {
                // Check if email is already used by another user
                const existingUser = await User.findOne({ email: trimmedEmail });

                if (existingUser) {
                    return res.status(400).json({
                        message: "Email is already in use"
                    });
                }

                user.email = trimmedEmail;
            }
        }

        // Save updated user
        await user.save();

        res.status(200).json({
            message: "Profile updated successfully",
            id: user._id,
            name: user.name,
            email: user.email,
            phone: user.phone,
            role: user.role
        });

    } catch (error) {
        console.error("Update user by ID error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    getUserById,
    updateUserById
};
