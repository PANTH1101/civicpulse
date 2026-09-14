const mongoose = require("mongoose");
const ServiceRequest = require("../models/ServiceRequest");
const ServiceRequestFeedback = require("../models/ServiceRequestFeedback");
const User = require("../models/User");
const Notification = require("../models/Notification");

// ---------------------------------------------------------------------------
// Helper: verify the caller is a DEPARTMENT user and return their department_id
// Returns { user, department_id } on success, or sends error response and
// returns null so the caller can early-return.
// ---------------------------------------------------------------------------
const resolveDepartmentUser = async (req, res) => {
    const userId = req.user.userId;

    const user = await User.findById(userId);
    if (!user) {
        res.status(404).json({ message: "User not found" });
        return null;
    }
    if (user.role !== "DEPARTMENT") {
        res.status(403).json({
            message: "Only department users can access this endpoint"
        });
        return null;
    }
    if (!user.department_id) {
        res.status(400).json({
            message: "Department user has no associated department"
        });
        return null;
    }

    return { user, department_id: user.department_id };
};

// ---------------------------------------------------------------------------
// Helper: build a formatted service request response object
// ---------------------------------------------------------------------------
const formatRequest = (sr) => ({
    id: sr._id,
    service: sr.service_id ? {
        id: sr.service_id._id,
        name: sr.service_id.name,
        category: sr.service_id.category,
        description: sr.service_id.description
    } : null,
    department: sr.department_id ? {
        id: sr.department_id._id,
        name: sr.department_id.name,
        email: sr.department_id.email,
        mobile: sr.department_id.mobile,
        office_address: sr.department_id.office_address
    } : null,
    citizen: sr.citizen_id ? {
        id: sr.citizen_id._id,
        name: sr.citizen_id.name,
        email: sr.citizen_id.email
    } : null,
    notes: sr.notes,
    status: sr.status,
    rejectionReason: sr.rejectionReason,
    acceptedAt: sr.acceptedAt,
    startedAt: sr.startedAt,
    completedAt: sr.completedAt,
    rejectedAt: sr.rejectedAt,
    cancelledAt: sr.cancelledAt,
    createdAt: sr.createdAt,
    updatedAt: sr.updatedAt
});

// ---------------------------------------------------------------------------
// GET /api/departments/service-requests
// Department views all service requests assigned to its department
// ---------------------------------------------------------------------------
const getDepartmentServiceRequests = async (req, res) => {
    try {
        const resolved = await resolveDepartmentUser(req, res);
        if (!resolved) return;
        const { department_id } = resolved;

        // Build query - ALWAYS filter by authenticated user's department_id
        // SECURITY: Never trust client-provided department_id
        const query = { department_id };

        // Optional filters
        const { status, page, limit } = req.query;

        // Validate and apply status filter
        if (status) {
            const validStatuses = [
                "PENDING", "ACCEPTED", "IN_PROGRESS",
                "COMPLETED", "REJECTED", "CANCELLED"
            ];
            const upperStatus = status.trim().toUpperCase();
            if (!validStatuses.includes(upperStatus)) {
                return res.status(400).json({
                    message: "Invalid status. Valid statuses are PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, REJECTED, CANCELLED"
                });
            }
            query.status = upperStatus;
        }

        // Pagination
        const pageNum = parseInt(page);
        const limitNum = parseInt(limit);
        const maxLimit = 50;

        // Validate page - handle page=0 explicitly
        if (page !== undefined) {
            if (isNaN(pageNum) || pageNum < 1) {
                return res.status(400).json({
                    message: "Page must be a positive integer"
                });
            }
        }
        
        // Use default page if not provided
        const finalPage = (page !== undefined && !isNaN(pageNum) && pageNum >= 1) ? pageNum : 1;

        // Check if limit was provided and is valid
        if (limit !== undefined) {
            if (isNaN(limitNum) || limitNum < 1) {
                return res.status(400).json({
                    message: "Limit must be a positive integer"
                });
            }
        }
        
        // Use default if not provided
        const finalLimit = (limit !== undefined && !isNaN(limitNum) && limitNum > 0) 
            ? (limitNum > maxLimit ? maxLimit : limitNum)
            : 10;

        // Calculate skip
        const skip = (finalPage - 1) * finalLimit;

        // Get total count for pagination
        const total = await ServiceRequest.countDocuments(query);

        // Get service requests with pagination
        const requests = await ServiceRequest.find(query)
            .populate("service_id", "name category description")
            .populate("department_id", "name email mobile office_address")
            .populate("citizen_id", "name email")
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(finalLimit);

        // Calculate total pages
        const totalPages = Math.ceil(total / finalLimit);

        return res.status(200).json({
            message: "Department service requests retrieved successfully",
            count: requests.length,
            total: total,
            page: finalPage,
            limit: finalLimit,
            totalPages: totalPages,
            requests: requests.map(formatRequest)
        });

    } catch (error) {
        console.error("Get department service requests error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// PATCH /api/service-requests/:requestId/accept
// Department accepts a PENDING service request
// ---------------------------------------------------------------------------
const acceptServiceRequest = async (req, res) => {
    try {
        const resolved = await resolveDepartmentUser(req, res);
        if (!resolved) return;
        const { department_id } = resolved;

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

        // Department isolation — department_id from authenticated user, never from client
        if (serviceRequest.department_id._id.toString() !== department_id.toString()) {
            return res.status(403).json({
                message: "Access denied: This request is not assigned to your department"
            });
        }

        // Valid transition: only PENDING → ACCEPTED
        if (serviceRequest.status !== "PENDING") {
            return res.status(400).json({
                message: `Cannot accept a service request with status ${serviceRequest.status}. Only PENDING requests can be accepted`
            });
        }

        serviceRequest.status = "ACCEPTED";
        serviceRequest.acceptedAt = new Date();
        await serviceRequest.save();

        // Notify the citizen
        await Notification.create({
            user_id: serviceRequest.citizen_id._id,
            service_request_id: serviceRequest._id,
            type: "SERVICE_REQUEST_ACCEPTED",
            message: `Your service request for '${serviceRequest.service_id.name}' has been accepted by the department`
        });

        return res.status(200).json({
            message: "Service request accepted successfully",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Accept service request error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// PATCH /api/service-requests/:requestId/reject
// Department rejects a PENDING service request
// ---------------------------------------------------------------------------
const rejectServiceRequest = async (req, res) => {
    try {
        const resolved = await resolveDepartmentUser(req, res);
        if (!resolved) return;
        const { department_id } = resolved;

        const { requestId } = req.params;
        if (!mongoose.Types.ObjectId.isValid(requestId)) {
            return res.status(400).json({ message: "Invalid request ID format" });
        }

        const { rejectionReason } = req.body;

        // rejectionReason is required for a reject action
        if (!rejectionReason || !rejectionReason.trim()) {
            return res.status(400).json({
                message: "rejectionReason is required when rejecting a service request"
            });
        }

        const serviceRequest = await ServiceRequest.findById(requestId)
            .populate("service_id", "name category description")
            .populate("department_id", "name email mobile office_address")
            .populate("citizen_id", "name email");

        if (!serviceRequest) {
            return res.status(404).json({ message: "Service request not found" });
        }

        // Department isolation
        if (serviceRequest.department_id._id.toString() !== department_id.toString()) {
            return res.status(403).json({
                message: "Access denied: This request is not assigned to your department"
            });
        }

        // Valid transition: only PENDING → REJECTED
        if (serviceRequest.status !== "PENDING") {
            return res.status(400).json({
                message: `Cannot reject a service request with status ${serviceRequest.status}. Only PENDING requests can be rejected`
            });
        }

        serviceRequest.status = "REJECTED";
        serviceRequest.rejectionReason = rejectionReason.trim();
        serviceRequest.rejectedAt = new Date();
        await serviceRequest.save();

        // Notify the citizen
        await Notification.create({
            user_id: serviceRequest.citizen_id._id,
            service_request_id: serviceRequest._id,
            type: "SERVICE_REQUEST_REJECTED",
            message: `Your service request for '${serviceRequest.service_id.name}' has been rejected`
        });

        return res.status(200).json({
            message: "Service request rejected successfully",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Reject service request error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// PATCH /api/service-requests/:requestId/start
// Department starts work on an ACCEPTED service request
// ---------------------------------------------------------------------------
const startServiceRequest = async (req, res) => {
    try {
        const resolved = await resolveDepartmentUser(req, res);
        if (!resolved) return;
        const { department_id } = resolved;

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

        // Department isolation
        if (serviceRequest.department_id._id.toString() !== department_id.toString()) {
            return res.status(403).json({
                message: "Access denied: This request is not assigned to your department"
            });
        }

        // Valid transition: only ACCEPTED → IN_PROGRESS
        if (serviceRequest.status !== "ACCEPTED") {
            return res.status(400).json({
                message: `Cannot start a service request with status ${serviceRequest.status}. Only ACCEPTED requests can be started`
            });
        }

        serviceRequest.status = "IN_PROGRESS";
        serviceRequest.startedAt = new Date();
        await serviceRequest.save();

        // Notify the citizen
        await Notification.create({
            user_id: serviceRequest.citizen_id._id,
            service_request_id: serviceRequest._id,
            type: "SERVICE_REQUEST_STARTED",
            message: `Your service request for '${serviceRequest.service_id.name}' is now in progress`
        });

        return res.status(200).json({
            message: "Service request moved to IN_PROGRESS",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Start service request error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

// ---------------------------------------------------------------------------
// PATCH /api/service-requests/:requestId/complete
// Department marks an IN_PROGRESS service request as COMPLETED
// ---------------------------------------------------------------------------
const completeServiceRequest = async (req, res) => {
    try {
        const resolved = await resolveDepartmentUser(req, res);
        if (!resolved) return;
        const { department_id } = resolved;

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

        // Department isolation
        if (serviceRequest.department_id._id.toString() !== department_id.toString()) {
            return res.status(403).json({
                message: "Access denied: This request is not assigned to your department"
            });
        }

        // Valid transition: only IN_PROGRESS → COMPLETED
        if (serviceRequest.status !== "IN_PROGRESS") {
            return res.status(400).json({
                message: `Cannot complete a service request with status ${serviceRequest.status}. Only IN_PROGRESS requests can be completed`
            });
        }

        serviceRequest.status = "COMPLETED";
        serviceRequest.completedAt = new Date();
        await serviceRequest.save();

        // Notify the citizen
        await Notification.create({
            user_id: serviceRequest.citizen_id._id,
            service_request_id: serviceRequest._id,
            type: "SERVICE_REQUEST_COMPLETED",
            message: `Your service request for '${serviceRequest.service_id.name}' has been completed`
        });

        return res.status(200).json({
            message: "Service request completed successfully",
            serviceRequest: formatRequest(serviceRequest)
        });

    } catch (error) {
        console.error("Complete service request error:", error.message);
        return res.status(500).json({ message: "Server error" });
    }
};

module.exports = {
    getDepartmentServiceRequests,
    acceptServiceRequest,
    rejectServiceRequest,
    startServiceRequest,
    completeServiceRequest
};
