const express = require("express");
const router = express.Router();
const protect = require("../middleware/authMiddleware");
const {
    getServices,
    getServiceById,
    submitServiceRequest,
    getMyServiceRequests,
    getServiceRequestById,
    cancelServiceRequest,
    submitServiceRequestFeedback,
    getServiceRequestFeedback
} = require("../controllers/serviceController");
const {
    acceptServiceRequest,
    rejectServiceRequest,
    startServiceRequest,
    completeServiceRequest
} = require("../controllers/departmentServiceController");

// ---------------------------------------------------------------------------
// IMPORTANT: All /requests/* routes are declared BEFORE /:serviceId so that
// Express does not match the literal string "requests" as a :serviceId param.
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Service Requests — citizen submit
// POST /api/services/requests
// ---------------------------------------------------------------------------
router.post("/requests", protect, submitServiceRequest);

// ---------------------------------------------------------------------------
// Service Requests — citizen read (static /my before dynamic /:requestId)
// GET /api/services/requests/my
// ---------------------------------------------------------------------------
router.get("/requests/my", protect, getMyServiceRequests);

// ---------------------------------------------------------------------------
// Service Requests — feedback (static /feedback suffix before bare /:requestId)
// POST /api/services/requests/:requestId/feedback
// GET  /api/services/requests/:requestId/feedback
// ---------------------------------------------------------------------------
router.post("/requests/:requestId/feedback", protect, submitServiceRequestFeedback);
router.get("/requests/:requestId/feedback", protect, getServiceRequestFeedback);

// ---------------------------------------------------------------------------
// Service Requests — citizen and department actions on a specific request
// GET    /api/services/requests/:requestId
// PATCH  /api/services/requests/:requestId/cancel
// PATCH  /api/services/requests/:requestId/accept
// PATCH  /api/services/requests/:requestId/reject
// PATCH  /api/services/requests/:requestId/start
// PATCH  /api/services/requests/:requestId/complete
// ---------------------------------------------------------------------------
router.get("/requests/:requestId", protect, getServiceRequestById);
router.patch("/requests/:requestId/cancel", protect, cancelServiceRequest);
router.patch("/requests/:requestId/accept", protect, acceptServiceRequest);
router.patch("/requests/:requestId/reject", protect, rejectServiceRequest);
router.patch("/requests/:requestId/start", protect, startServiceRequest);
router.patch("/requests/:requestId/complete", protect, completeServiceRequest);

// ---------------------------------------------------------------------------
// Municipal Services catalogue — AFTER all /requests/* routes
// GET /api/services          — browse all active services (any authenticated user)
// GET /api/services/:serviceId — single service detail
// ---------------------------------------------------------------------------
router.get("/", protect, getServices);
router.get("/:serviceId", protect, getServiceById);

module.exports = router;
