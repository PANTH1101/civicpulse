const User = require("../models/User");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");

const registerUser = async (req, res) => {
    try {
        const { name, email, password } = req.body;

        // Check required fields
        if (!name || !email || !password) {
            return res.status(400).json({
                message: "Name, email and password are required"
            });
        }

        // Trim and validate fields
        const trimmedName = name.trim();
        const trimmedEmail = email.trim().toLowerCase();
        const trimmedPassword = password.trim();

        // Check for empty values after trimming
        if (!trimmedName || !trimmedEmail || !trimmedPassword) {
            return res.status(400).json({
                message: "Name, email and password cannot be empty"
            });
        }

        // Validate email format
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        if (!emailRegex.test(trimmedEmail)) {
            return res.status(400).json({
                message: "Invalid email format"
            });
        }

        // Validate password length (minimum 6 characters)
        if (trimmedPassword.length < 6) {
            return res.status(400).json({
                message: "Password must be at least 6 characters long"
            });
        }

        // Check if user already exists (case-insensitive)
        const existingUser = await User.findOne({ email: trimmedEmail });

        if (existingUser) {
            return res.status(409).json({
                message: "User with this email already exists"
            });
        }

        // Hash password
        const hashedPassword = await bcrypt.hash(trimmedPassword, 10);

        // Create citizen (force role to CITIZEN, ignore any role from request body)
        const user = await User.create({
            name: trimmedName,
            email: trimmedEmail,
            password: hashedPassword,
            role: "CITIZEN"
        });

        res.status(201).json({
            message: "User registered successfully",
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error("Registration error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;

        // Check required fields
        if (!email || !password) {
            return res.status(400).json({
                message: "Email and password are required"
            });
        }

        // Trim and normalize email
        const trimmedEmail = email.trim().toLowerCase();
        const trimmedPassword = password.trim();

        // Check for empty values after trimming
        if (!trimmedEmail || !trimmedPassword) {
            return res.status(400).json({
                message: "Email and password cannot be empty"
            });
        }

        // Find user (case-insensitive email)
        const user = await User.findOne({ email: trimmedEmail });

        if (!user) {
            return res.status(401).json({
                message: "Invalid email or password"
            });
        }

        // Compare password
        const isPasswordCorrect = await bcrypt.compare(
            trimmedPassword,
            user.password
        );

        if (!isPasswordCorrect) {
            return res.status(401).json({
                message: "Invalid email or password"
            });
        }

        // Generate JWT (do NOT include password)
        const token = jwt.sign(
            {
                userId: user._id,
                role: user.role
            },
            process.env.JWT_SECRET,
            {
                expiresIn: "1d"
            }
        );

        res.status(200).json({
            message: "Login successful",
            token,
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error("Login error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const getProtectedData = async (req, res) => {
    try {
        // Get user information from decoded JWT (set by middleware)
        const userId = req.user.userId;

        // Fetch user from database (exclude password)
        const user = await User.findById(userId).select("-password");

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        res.status(200).json({
            message: "Protected route accessed successfully",
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });

    } catch (error) {
        console.error("Protected route error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const getProfile = async (req, res) => {
    try {
        // Get user ID from authenticated JWT (set by middleware)
        const userId = req.user.userId;

        // Fetch user from database (exclude password)
        const user = await User.findById(userId).select("-password");

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        res.status(200).json({
            message: "Profile retrieved successfully",
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                department_id: user.department_id,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            }
        });

    } catch (error) {
        console.error("Get profile error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

const updateProfile = async (req, res) => {
    try {
        // Get user ID from authenticated JWT (set by middleware)
        const userId = req.user.userId;

        // Fetch user from database
        const user = await User.findById(userId);

        if (!user) {
            return res.status(404).json({
                message: "User not found"
            });
        }

        // Extract only allowed fields from request body
        const { name, email } = req.body;

        // Reject if client attempts to modify restricted fields
        if (req.body.role !== undefined) {
            return res.status(400).json({
                message: "Cannot modify role"
            });
        }

        if (req.body.department_id !== undefined) {
            return res.status(400).json({
                message: "Cannot modify department_id"
            });
        }

        if (req.body.password !== undefined) {
            return res.status(400).json({
                message: "Cannot modify password through this endpoint"
            });
        }

        // Check if at least one field is provided
        if (!name && !email) {
            return res.status(400).json({
                message: "Please provide name or email to update"
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
                    return res.status(409).json({
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
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                department_id: user.department_id,
                createdAt: user.createdAt,
                updatedAt: user.updatedAt
            }
        });

    } catch (error) {
        console.error("Update profile error:", error.message);

        res.status(500).json({
            message: "Server error"
        });
    }
};

module.exports = {
    registerUser,
    loginUser,
    getProtectedData,
    getProfile,
    updateProfile
};