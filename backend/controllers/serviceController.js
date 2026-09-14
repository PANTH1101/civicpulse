const mongoose = require("mongoose");
const MunicipalService = require("../models/MunicipalService");
const ServiceRequest = require("../models/ServiceRequest");
const ServiceRequestFeedback = require("../models/ServiceRequestFeedback");
const Department = require("../models/Department");
const User = require("../models/User");
const Notification = require("../models/Notification");

// ---------------------------------------------------------------------------
// Helper: build a formatted service request response object
// ---------------------------------------------------------------------------
const formatRequest = (req) => ({
    id: req._id,
    service: req.service_id ? {
        id: req.service_id._id,
        name: req.service_id.name,
        category: req.service_id.category,
        description: req.service_id.description
    } : null,
    department: req.department_id ? {
        id: req.department_id._id,
        name: req.department_id.name,
        email: req.department_id.email,
        mobile: req.department_id.mobile,
        office_address: req.department_id.office_address
    } : null,
    citizen: req.citizen_id ? {
        id: req.citizen_id._id,
        name: req.citizen_id.name,
        email: req.citizen_id.email
    } : null,
    notes: req.notes,
    status: req.status,
    rejectionReason: req.rejectionReason,
    acceptedAt: req.acceptedAt,
    startedAt: req.startedAt,
    completedAt: req.completedAt,
    rejectedAt: req.rejectedAt,
    cancelledAt: req.cancelledAt,
    createdAt: req.createdAt,
    updatedAt: req.updatedAt
});

// ---------------------------------------------------------------------------
// GET /api/services
// Browse all active municipal services (any authenticated user)
// ---------------------------------------------------------------------------
const getServices = async (req, res) => {
    try {
        const { category } = req.query;

        const query = { isActive: true };

        // Optional category filter
        if (category) {
            const validCategories = [
                "ADMINISTRATIVE",
                "INFRASTRUCTURE",
                "HEALTH_SERVICES",
                "EDUCATION_SERVICES",
                "ENVIRONMENT_SERVICES",
                "SOCIAL_SERVICES",
                "LEGAL_SERVICES",
                "EMERGENCY_SERVICES",
                "OTHER"
            ];
            const upperCategory = category.trim().toUpperCase();
            if (!validCategories.includes(upperCategory)) {
                return res.status(400).json({
                    message: "Invalid category. Valid values: ADMINISTRATIVE, INFRASTRUCTURE, HEALTH_SERVICES, EDUCATION_SERVICES, ENVIRONMENT_SERVICES, SOCIAL_SERVICES, LEGAL_SERVICES, EMERGENCY_SERVICES, OTHER"
                });
            }
            query.category = upperCategory;
        }

        const services = await MunicipalService.find(query)
            .sort({ category: 1, name: 1 });

        return res.status(200).json({
            message: "Municipal services retrieved successfully",
            count: services.length,
            services: services.map(s => ({
                id: s._id,
                name: s.name,
                description: s.description,
                category: s.category,
                isActive: s.isActive
            }))
        });

    } catch (error) {
        console.error("Get services error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// GET /api/services/:serviceId
// Get a single service by ID (any authenticated user)
// ---------------------------------------------------------------------------
const getServiceById = async (req, res) => {
    try {
        const { serviceId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(serviceId)) {
            return res.status(400).json({ message: "Invalid service ID format" });
        }

        const service = await MunicipalService.findById(serviceId);

        if (!service) {
            return res.status(404).json({ message: "Service not found" });
        }

        if (!service.isActive) {
            return res.status(404).json({ message: "Service not found" });
        }

        return res.status(200).json({
            message: "Service retrieved successfully",
            service: {
                id: service._id,
                name: service.name,
                description: service.description,
                category: service.category,
                isActive: service.isActive
            }
        });

    } catch (error) {
        console.error("Get service by ID error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// POST /api/service-requests
// Citizen submits a service request
// ---------------------------------------------------------------------------
const submitServiceRequest = async (req, res) => {
    try {
        const citizenId = req.user.userId; // Always from JWT — never from body
        const { service_id, department_id, notes } = req.body;

        // Verify caller is a CITIZEN
        const citizen = await User.findById(citizenId);
        if (!citizen) {
            return res.status(404).json({ message: "User not found" });
        }
        if (citizen.role !== "CITIZEN") {
            return res.status(403).json({
                message: "Only citizens can submit service requests"
            });
        }

        // Validate required fields
        if (!service_id) {
            return res.status(400).json({ message: "service_id is required" });
        }
        if (!department_id) {
            return res.status(400).json({ message: "department_id is required" });
        }

        // Validate ObjectId formats
        if (!mongoose.Types.ObjectId.isValid(service_id)) {
            return res.status(400).json({ message: "Invalid service_id format" });
        }
        if (!mongoose.Types.ObjectId.isValid(department_id)) {
            return res.status(400).json({ message: "Invalid department_id format" });
        }

        // Validate service exists and is active
        const service = await MunicipalService.findById(service_id);
        if (!service) {
            return res.status(404).json({ message: "Service not found" });
        }
        if (!service.isActive) {
            return res.status(400).json({ message: "This service is not currently available" });
        }

        // Validate department exists
        const department = await Department.findById(department_id);
        if (!department) {
            return res.status(404).json({ message: "Department not found" });
        }

        // Sanitise optional notes
        let trimmedNotes = null;
        if (notes) {
            trimmedNotes = notes.trim();
            if (trimmedNotes.length === 0) trimmedNotes = null;
        }

        // Create the service request — citizen_id from JWT, not body
        const serviceRequest = await ServiceRequest.create({
            service_id,
            department_id,
            citizen_id: citizenId,
            notes: trimmedNotes,
            status: "PENDING"
        });

        // Populate for response
        await serviceRequest.populate("service_id", "name category description");
        await serviceRequest.populate("department_id", "name email mobile office_address");
        await serviceRequest.populate("citizen_id", "name email");

        // Notify all users belonging to the selected department
        const departmentUsers = await User.find({
            role: "DEPARTMENT",
            department_id: department_id
        });

        const notificationPromises = departmentUsers.map(u =>
            Notification.create({
                user_id: u._id,
                service_request_id: serviceRequest._id,
                type: "SERVICE_REQUEST_SUBMITTED",
                message: `New service request submitted: ${service.name}`
            })
        );
        await Promise.all(notificationPromises);

        return res.status(201).json({
            message: "Service request submitted successfully",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Submit service request error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// GET /api/service-requests/my
// Citizen views their own service requests (with optional filters + pagination)
// ---------------------------------------------------------------------------
const getMyServiceRequests = async (req, res) => {
    try {
        const citizenId = req.user.userId;

        // Verify caller is a CITIZEN
        const citizen = await User.findById(citizenId);
        if (!citizen) {
            return res.status(404).json({ message: "User not found" });
        }
        if (citizen.role !== "CITIZEN") {
            return res.status(403).json({
                message: "Only citizens can access this endpoint"
            });
        }

        const { status, page, limit } = req.query;

        const query = { citizen_id: citizenId };

        // Optional status filter
        if (status) {
            const validStatuses = ["PENDING", "ACCEPTED", "IN_PROGRESS", "COMPLETED", "REJECTED", "CANCELLED"];
            const upperStatus = status.trim().toUpperCase();
            if (!validStatuses.includes(upperStatus)) {
                return res.status(400).json({
                    message: "Invalid status. Valid values: PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, REJECTED, CANCELLED"
                });
            }
            query.status = upperStatus;
        }

        // Pagination
        const pageNum = parseInt(page) || 1;
        const limitNum = parseInt(limit) || 10;
        const maxLimit = 50;

        if (pageNum < 1) {
            return res.status(400).json({ message: "Page must be a positive integer" });
        }
        if (limitNum < 1) {
            return res.status(400).json({ message: "Limit must be a positive integer" });
        }

        const finalLimit = limitNum > maxLimit ? maxLimit : limitNum;
        const skip = (pageNum - 1) * finalLimit;

        const total = await ServiceRequest.countDocuments(query);
        const requests = await ServiceRequest.find(query)
            .populate("service_id", "name category description")
            .populate("department_id", "name email mobile office_address")
            .populate("citizen_id", "name email")
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(finalLimit);

        return res.status(200).json({
            message: "My service requests retrieved successfully",
            count: requests.length,
            total,
            page: pageNum,
            limit: finalLimit,
            totalPages: Math.ceil(total / finalLimit),
            serviceRequests: requests.map(formatRequest)
        });

    } catch (error) {
        console.error("Get my service requests error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// GET /api/service-requests/:requestId
// Citizen views a single service request (must own it)
// ---------------------------------------------------------------------------
const getServiceRequestById = async (req, res) => {
    try {
        const citizenId = req.user.userId;
        const { requestId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(requestId)) {
            return res.status(400).json({ message: "Invalid request ID format" });
        }

        const serviceRequest = await ServiceRequest.findById(requestId)
            .populate("service_id", "name category description")
            .populate("department_id", "name email mobile office_address")
            .populate("citizen_id", "name email");

        if (!serviceRequest) {
            return res.status(404).json({ message: "Service request not found" });
        }

        // Ownership check — citizen can only see their own requests
        if (serviceRequest.citizen_id._id.toString() !== citizenId) {
            return res.status(403).json({
                message: "Access denied: You can only view your own service requests"
            });
        }

        return res.status(200).json({
            message: "Service request retrieved successfully",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Get service request by ID error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// PATCH /api/service-requests/:requestId/cancel
// Citizen cancels a PENDING service request
// ---------------------------------------------------------------------------
const cancelServiceRequest = async (req, res) => {
    try {
        const citizenId = req.user.userId;
        const { requestId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(requestId)) {
            return res.status(400).json({ message: "Invalid request ID format" });
        }

        const serviceRequest = await ServiceRequest.findById(requestId)
            .populate("service_id", "name category description")
            .populate("department_id", "name email mobile office_address")
            .populate("citizen_id", "name email");

        if (!serviceRequest) {
            return res.status(404).json({ message: "Service request not found" });
        }

        // Ownership check
        if (serviceRequest.citizen_id._id.toString() !== citizenId) {
            return res.status(403).json({
                message: "Access denied: You can only cancel your own service requests"
            });
        }

        // Only PENDING requests can be cancelled by the citizen
        if (serviceRequest.status !== "PENDING") {
            return res.status(400).json({
                message: `Cannot cancel a service request with status ${serviceRequest.status}. Only PENDING requests can be cancelled`
            });
        }

        serviceRequest.status = "CANCELLED";
        serviceRequest.cancelledAt = new Date();
        await serviceRequest.save();

        // Notify the department users
        const departmentUsers = await User.find({
            role: "DEPARTMENT",
            department_id: serviceRequest.department_id._id
        });

        const notificationPromises = departmentUsers.map(u =>
            Notification.create({
                user_id: u._id,
                service_request_id: serviceRequest._id,
                type: "SERVICE_REQUEST_CANCELLED",
                message: `Service request for '${serviceRequest.service_id.name}' has been cancelled by the citizen`
            })
        );
        await Promise.all(notificationPromises);

        return res.status(200).json({
            message: "Service request cancelled successfully",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Cancel service request error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// POST /api/service-requests/:requestId/feedback
// Citizen submits feedback for a COMPLETED service request
// ---------------------------------------------------------------------------
const submitServiceRequestFeedback = async (req, res) => {
    try {
        const citizenId = req.user.userId;
        const { requestId } = req.params;
        const { rating, comment } = req.body;

        if (!mongoose.Types.ObjectId.isValid(requestId)) {
            return res.status(400).json({ message: "Invalid request ID format" });
        }

        // Validate rating
        if (!rating && rating !== 0) {
            return res.status(400).json({ message: "Rating is required" });
        }
        if (!Number.isInteger(rating)) {
            return res.status(400).json({ message: "Rating must be an integer" });
        }
        if (rating < 1 || rating > 5) {
            return res.status(400).json({ message: "Rating must be between 1 and 5" });
        }

        // Sanitise optional comment
        let trimmedComment = null;
        if (comment) {
            trimmedComment = comment.trim();
            if (trimmedComment.length === 0) trimmedComment = null;
        }

        const serviceRequest = await ServiceRequest.findById(requestId)
            .populate("service_id", "name category");

        if (!serviceRequest) {
            return res.status(404).json({ message: "Service request not found" });
        }

        // Ownership check
        if (serviceRequest.citizen_id.toString() !== citizenId) {
            return res.status(403).json({
                message: "Access denied: You can only submit feedback for your own service requests"
            });
        }

        // Only COMPLETED requests can receive feedback
        if (serviceRequest.status !== "COMPLETED") {
            return res.status(400).json({
                message: "Feedback can only be submitted for completed service requests"
            });
        }

        // Duplicate check
        const existing = await ServiceRequestFeedback.findOne({
            service_request_id: requestId
        });
        if (existing) {
            return res.status(409).json({
                message: "Feedback has already been submitted for this service request"
            });
        }

        const feedback = await ServiceRequestFeedback.create({
            service_request_id: requestId,
            citizen_id: citizenId,
            rating,
            comment: trimmedComment
        });

        return res.status(201).json({
            message: "Feedback submitted successfully",
            feedback: {
                id: feedback._id,
                service_request_id: feedback.service_request_id,
                rating: feedback.rating,
                comment: feedback.comment,
                createdAt: feedback.createdAt
            }
        });

    } catch (error) {
        if (error.code === 11000) {
            return res.status(409).json({
                message: "Feedback has already been submitted for this service request"
            });
        }
        console.error("Submit service request feedback error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// GET /api/service-requests/:requestId/feedback
// Citizen OR department user views feedback for a service request
// ---------------------------------------------------------------------------
const getServiceRequestFeedback = async (req, res) => {
    try {
        const userId = req.user.userId;
        const userRole = req.user.role;
        const { requestId } = req.params;

        if (!mongoose.Types.ObjectId.isValid(requestId)) {
            return res.status(400).json({ message: "Invalid request ID format" });
        }

        const serviceRequest = await ServiceRequest.findById(requestId)
            .populate("service_id", "name category");

        if (!serviceRequest) {
            return res.status(404).json({ message: "Service request not found" });
        }

        // Authorization: citizen (own request) or department user (own dept request)
        let isAuthorized = false;

        if (serviceRequest.citizen_id.toString() === userId) {
            isAuthorized = true;
        }

        if (userRole === "DEPARTMENT") {
            const user = await User.findById(userId);
            if (
                user &&
                user.department_id &&
                user.department_id.toString() === serviceRequest.department_id.toString()
            ) {
                isAuthorized = true;
            }
        }

        if (!isAuthorized) {
            return res.status(403).json({
                message: "Access denied: You are not authorized to view this feedback"
            });
        }

        const feedback = await ServiceRequestFeedback.findOne({
            service_request_id: requestId
        });

        if (!feedback) {
            return res.status(404).json({
                message: "No feedback found for this service request"
            });
        }

        return res.status(200).json({
            message: "Feedback retrieved successfully",
            feedback: {
                id: feedback._id,
                service_request_id: feedback.service_request_id,
                service: serviceRequest.service_id ? {
                    id: serviceRequest.service_id._id,
                    name: serviceRequest.service_id.name,
                    category: serviceRequest.service_id.category
                } : null,
                rating: feedback.rating,
                comment: feedback.comment,
                createdAt: feedback.createdAt,
                updatedAt: feedback.updatedAt
            }
        });

    } catch (error) {
        console.error("Get service request feedback error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

module.exports = {
    getServices,
    getServiceById,
    submitServiceRequest,
    getMyServiceRequests,
    getServiceRequestById,
    cancelServiceRequest,
    submitServiceRequestFeedback,
    getServiceRequestFeedback
};
