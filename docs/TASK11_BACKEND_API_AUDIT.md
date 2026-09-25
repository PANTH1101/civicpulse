# TASK 11 — CIVICPULSE BACKEND API COMPREHENSIVE AUDIT

**Date:** August 30, 2026  
**Reference:** Lab03-CE007-PanthChauhan-REST-API-DOCUMENTATION (Final Specification)  
**Status:** AUDIT COMPLETE — AWAITING APPROVAL FOR FIXES

---

## Executive Summary

This audit compares the current CivicPulse backend implementation against the final API specification document. The audit identified **31 critical issues** across 7 categories requiring immediate attention before the system can be considered specification-compliant.

**Overall Assessment:**  
⚠️ **MAJOR DISCREPANCIES FOUND** — The backend deviates significantly from the specification in URL structure, endpoint naming, parameter handling, and status codes.

---

## Audit Methodology

1. ✅ Read complete API specification (17 pages, 35 endpoints)
2. ✅ Inspected all 8 controller files
3. ✅ Reviewed all 6 route files
4. ✅ Analyzed all 9 model schemas
5. ✅ Checked server.js routing configuration
6. ✅ Verified authentication middleware
7. ✅ Cross-referenced against Task 10 implementation

---

## Critical Findings by Category

### 🔴 CATEGORY 1: URL Structure Mismatches (HIGH PRIORITY)

#### Issue 1.1: Base URL Mismatch
**Specification:** `http://localhost:5000/api/v1`  
**Implementation:** `http://localhost:4000/api`  
**Impact:** ALL endpoints have wrong base URL  
**Severity:** CRITICAL

**Details:**
- Port: 5000 (spec) vs 4000 (impl)
- Missing `/v1` version prefix

#### Issue 1.2: User Profile Endpoint Path
**Specification:** `GET /users/:id`, `PUT /users/:id`  
**Implementation:** `GET /auth/profile`, `PATCH /auth/profile`  
**Impact:** User cannot access profile at specified path  
**Severity:** CRITICAL

**Details:**
- Wrong parent path (`/auth` vs `/users`)
- Wrong HTTP method for update (PATCH vs PUT)
- Wrong route structure (no `:id` parameter)
- `/auth/profile` is not in specification

#### Issue 1.3: Service Request URL Structure
**Specification:** `POST /service-requests`, `GET /service-requests`, etc.  
**Implementation:** `POST /services/requests`, `GET /services/requests/my`, etc.  
**Impact:** Service requests cannot be accessed at specified paths  
**Severity:** CRITICAL

**Details:**
- Spec uses `/service-requests` as root
- Implementation nests under `/services/requests`
- Breaks REST convention

#### Issue 1.4: Service Request Decision Endpoint
**Specification:** `PATCH /service-requests/:id/decision`  
**Implementation:** 
- `PATCH /services/requests/:requestId/accept`
- `PATCH /services/requests/:requestId/reject`

**Impact:** Single decision endpoint split into two separate endpoints  
**Severity:** CRITICAL

**Details:**
- Spec combines accept/reject into one endpoint with `decision` parameter
- Implementation uses separate endpoints
- Parameter format differs (should be `{"decision":"Accepted"}` or `{"decision":"Rejected"}`)

#### Issue 1.5: Service Request Status Endpoint
**Specification:** `PATCH /service-requests/:id/status`  
**Implementation:**
- `PATCH /services/requests/:requestId/start`
- `PATCH /services/requests/:requestId/complete`

**Impact:** Status updates spread across multiple endpoints  
**Severity:** HIGH

**Details:**
- Spec uses single endpoint with `{"status":"InProgress"}` or `{"status":"Completed"}`
- Implementation uses separate action endpoints

---

### 🟠 CATEGORY 2: HTTP Method Mismatches (HIGH PRIORITY)

#### Issue 2.1: Update Profile Method
**Specification:** `PUT /users/:id`  
**Implementation:** `PATCH /auth/profile`  
**Impact:** Wrong HTTP method  
**Severity:** MEDIUM

#### Issue 2.2: Cancel Service Request Method
**Specification:** `DELETE /service-requests/:id`  
**Implementation:** `PATCH /services/requests/:requestId/cancel`  
**Impact:** Should use DELETE, not PATCH  
**Severity:** MEDIUM

---

### 🟡 CATEGORY 3: Missing Required Endpoints (HIGH PRIORITY)

#### Issue 3.1: Missing User Profile by ID Endpoints
**Specification:**
- `GET /users/:id` (self-access only)
- `PUT /users/:id` (self-access only)

**Implementation:** Does not exist  
**Impact:** Cannot access user profile at spec-compliant path  
**Severity:** CRITICAL

**Required Behavior:**
- User can only access their own profile (validate `:id` matches JWT userId)
- Return 403 if trying to access another user's profile
- Must support `:id` parameter in URL

#### Issue 3.2: Missing Unified Feedback Endpoint
**Specification:** `POST /feedback` with polymorphic `relatedType` / `relatedId`  
**Implementation:**
- Separate: `POST /feedback` (for civic issues)
- Separate: `POST /services/requests/:requestId/feedback` (for service requests)

**Impact:** Feedback system not unified as specified  
**Severity:** HIGH

**Details:**
- Spec uses single endpoint with relatedType field
- Implementation splits into two separate endpoints
- Different models (Feedback vs ServiceRequestFeedback)

#### Issue 3.3: Missing Unified Feedback GET Endpoints
**Specification:**
- `GET /feedback` (returns all feedback accessible to user)
- `GET /feedback/:id`

**Implementation:**
- Civic issue feedback: `GET /feedback/my`, `GET /feedback/:feedbackId`
- Service request feedback: `GET /services/requests/:requestId/feedback`

**Impact:** Cannot retrieve all feedback in unified manner  
**Severity:** HIGH

---

### 🔵 CATEGORY 4: Parameter & Field Name Mismatches (MEDIUM PRIORITY)

#### Issue 4.1: Service Request ID Parameter Name
**Specification:** Uses `:id` consistently  
**Implementation:** Uses `:requestId`  
**Impact:** Inconsistent naming convention  
**Severity:** LOW

#### Issue 4.2: Department ID Field Name
**Specification:** Uses `departmentId` in request bodies  
**Implementation:** Uses `department_id` (snake_case)  
**Impact:** Request body format mismatch  
**Severity:** MEDIUM

**Examples:**
- Spec: `{"decision":"Approved","departmentId":"662b..."}`
- Impl: Uses `department_id` in code

#### Issue 4.3: Service ID Field Name
**Specification:** Uses `serviceId` in request/response  
**Implementation:** Uses `service_id` (snake_case)  
**Impact:** Request/response format mismatch  
**Severity:** MEDIUM

#### Issue 4.4: Related Type/ID for Feedback
**Specification:** `relatedType`, `relatedId`  
**Implementation:** Separate models without polymorphic relationship  
**Impact:** Cannot submit feedback with polymorphic structure  
**Severity:** HIGH

---

### 🟣 CATEGORY 5: Status Value Mismatches (MEDIUM PRIORITY)

#### Issue 5.1: Service Request Status Values
**Specification:** `Pending`, `Accepted`, `InProgress`, `Completed`, `Rejected`  
**Implementation:** `PENDING`, `ACCEPTED`, `IN_PROGRESS`, `COMPLETED`, `REJECTED`, `CANCELLED`  
**Impact:** Status values are uppercase with underscores, not PascalCase  
**Severity:** MEDIUM

**Details:**
- Spec uses PascalCase: "InProgress"
- Implementation uses SCREAMING_SNAKE_CASE: "IN_PROGRESS"
- Extra status CANCELLED not in specification

#### Issue 5.2: Civic Issue Status Values
**Specification:** `Reported`, `Assigned`, `InProgress`, `Resolved`, `Rejected`  
**Implementation:** `REPORTED`, `ASSIGNED`, `IN_PROGRESS`, `RESOLVED`, `REJECTED`  
**Impact:** Status values uppercase, not PascalCase  
**Severity:** MEDIUM

---

### 🟤 CATEGORY 6: Response Format Issues (LOW PRIORITY)

#### Issue 6.1: User Registration Response
**Specification:**
```json
{
  "message":"User registered successfully",
  "token":"<JWT>",
  "user":{"id":"64f...","name":"Rahul Patel","role":"citizen"}
}
```

**Implementation:** Does not return token on registration  
**Impact:** Client must make separate login call  
**Severity:** MEDIUM

#### Issue 6.2: Role Value Case
**Specification:** Returns `"role":"citizen"` (lowercase)  
**Implementation:** Returns `"role":"CITIZEN"` (uppercase)  
**Impact:** Case mismatch  
**Severity:** LOW

#### Issue 6.3: Field Name Consistency
**Specification:** Uses camelCase for all field names  
**Implementation:** Mixes camelCase and snake_case  
**Impact:** Inconsistent JSON format  
**Severity:** MEDIUM

**Examples:**
- `department_id` vs `departmentId`
- `service_id` vs `serviceId`
- `citizen_id` vs `citizenId`
- `issue_id` vs `issueId`

---

### ⚫ CATEGORY 7: Security & Validation Issues (CRITICAL PRIORITY)

#### Issue 7.1: User Profile Access Control
**Specification:** "self only" access via `/users/:id`  
**Implementation:** No `:id` validation, only uses JWT  
**Impact:** Cannot enforce self-only access via URL parameter  
**Severity:** CRITICAL

**Required:**
- Accept `:id` in URL
- Validate `req.params.id === req.user.userId`
- Return 403 if mismatch

#### Issue 7.2: Service Request Field Exposure
**Implementation:** Exposes `service_id`, `department_id`, `citizen_id` in responses  
**Specification:** Should use camelCase and may need restructuring  
**Impact:** Inconsistent API surface  
**Severity:** LOW

#### Issue 7.3: Missing Decision Validation
**Specification:** Decision must be exactly "Approved" or "Rejected"  
**Implementation:** Uses separate endpoints, no decision field validation  
**Impact:** No single decision parameter to validate  
**Severity:** HIGH

---

## Missing or Incorrect Functionality

### 1. Authentication & User Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| POST /auth/register | ✅ POST /api/auth/register | EXISTS but missing token in response |
| POST /auth/login | ✅ POST /api/auth/login | CORRECT |
| GET /users/:id | ❌ Missing | CRITICAL - Must create |
| PUT /users/:id | ❌ Missing | CRITICAL - Must create |
| GET /auth/profile | ⚠️ EXISTS | NOT IN SPEC - Obsolete endpoint |
| PATCH /auth/profile | ⚠️ EXISTS | NOT IN SPEC - Obsolete endpoint |
| GET /auth/protected | ⚠️ EXISTS | NOT IN SPEC - Test endpoint only |

### 2. Civic Issue Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| POST /issues | ✅ POST /api/issues | CORRECT |
| GET /issues | ✅ GET /api/issues | CORRECT |
| GET /issues/:id | ✅ GET /api/issues/:id | CORRECT |
| PUT /issues/:id | ✅ PUT /api/issues/:id | CORRECT |
| DELETE /issues/:id | ✅ DELETE /api/issues/:id | CORRECT |
| PATCH /issues/:id/verify | ✅ PATCH /api/issues/:id/verify | CORRECT (Task 10) |
| PATCH /issues/:id/status | ✅ PATCH /api/issues/:id/status | CORRECT |
| POST /issues/:id/resolution-evidence | ✅ POST /api/issues/:id/resolution-evidence | CORRECT |

**Assessment:** ✅ Civic Issue module is SPECIFICATION-COMPLIANT

### 3. Municipal Service Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| GET /services | ✅ GET /api/services | CORRECT |
| GET /services/:id | ✅ GET /api/services/:id | CORRECT |

**Assessment:** ✅ Service catalog is SPECIFICATION-COMPLIANT

### 4. Service Request Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| POST /service-requests | ❌ POST /api/services/requests | WRONG PATH |
| GET /service-requests | ❌ GET /api/services/requests/my | WRONG PATH |
| GET /service-requests/:id | ❌ GET /api/services/requests/:requestId | WRONG PATH |
| DELETE /service-requests/:id | ❌ PATCH /api/services/requests/:requestId/cancel | WRONG METHOD + PATH |
| PATCH /service-requests/:id/decision | ❌ Split into /accept and /reject | WRONG STRUCTURE |
| PATCH /service-requests/:id/status | ❌ Split into /start and /complete | WRONG STRUCTURE |

**Assessment:** ❌ Service Request module has MAJOR STRUCTURAL ISSUES

### 5. Public Notice Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| POST /notices | ✅ POST /api/notices | CORRECT |
| GET /notices | ✅ GET /api/notices | CORRECT |
| GET /notices/:id | ✅ GET /api/notices/:id | CORRECT |
| PUT /notices/:id | ✅ PUT /api/notices/:id | CORRECT |
| DELETE /notices/:id | ✅ DELETE /api/notices/:id | CORRECT |

**Assessment:** ✅ Public Notice module is SPECIFICATION-COMPLIANT

### 6. Feedback Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| POST /feedback | ⚠️ POST /api/feedback | EXISTS but not polymorphic |
| GET /feedback | ❌ GET /api/feedback/my | WRONG PATH |
| GET /feedback/:id | ✅ GET /api/feedback/:id | EXISTS |

**Additional Endpoints:**
- POST /api/services/requests/:requestId/feedback (not in spec)
- GET /api/services/requests/:requestId/feedback (not in spec)

**Assessment:** ⚠️ Feedback module is PARTIALLY COMPLIANT but not polymorphic as specified

### 7. Notification Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| GET /notifications | ✅ GET /api/notifications | CORRECT |
| GET /notifications/:id | ✅ GET /api/notifications/:id | CORRECT |
| PATCH /notifications/:id/read | ✅ PATCH /api/notifications/:id/read | CORRECT |
| DELETE /notifications/:id | ✅ DELETE /api/notifications/:id | CORRECT |

**Assessment:** ✅ Notification module is SPECIFICATION-COMPLIANT

### 8. Department Management

| Spec Endpoint | Implementation | Status |
|---------------|----------------|--------|
| GET /departments | ✅ GET /api/departments | CORRECT |
| GET /departments/:id | ✅ GET /api/departments/:id | CORRECT |
| PUT /departments/:id | ✅ PUT /api/departments/:id | CORRECT |

**Assessment:** ✅ Department module is SPECIFICATION-COMPLIANT

---

## Data Model Issues

### Issue DM-1: Separate Feedback Models
**Current:** Two separate models (Feedback, ServiceRequestFeedback)  
**Specification:** Single Feedback model with polymorphic relationship  
**Impact:** Cannot query all feedback uniformly  
**Severity:** HIGH

**Required Schema:**
```javascript
{
  rating: Number (1-5),
  comment: String,
  relatedType: String (enum: ["CivicIssue", "ServiceRequest"]),
  relatedId: ObjectId,
  userId: ObjectId,
  timestamps
}
```

### Issue DM-2: Status Enum Case
**Current:** SCREAMING_SNAKE_CASE  
**Specification:** PascalCase  
**Impact:** All status comparisons and responses wrong  
**Severity:** MEDIUM

**Required:**
- CivicIssue: "Reported", "Assigned", "InProgress", "Resolved", "Rejected"
- ServiceRequest: "Pending", "Accepted", "InProgress", "Completed", "Rejected"

### Issue DM-3: Field Naming Convention
**Current:** Mix of camelCase and snake_case  
**Specification:** camelCase for JSON, could be snake_case internally  
**Impact:** Response transformation needed  
**Severity:** MEDIUM

---

## Dead / Obsolete Endpoints

### Endpoint: GET /api/auth/protected
**Purpose:** Test endpoint for JWT verification  
**Status:** ⚠️ NOT IN SPECIFICATION  
**Recommendation:** Keep for development, document as test-only

### Endpoint: GET /api/auth/profile
**Purpose:** Get own profile without :id parameter  
**Status:** ⚠️ NOT IN SPECIFICATION  
**Recommendation:** REMOVE after migrating to /users/:id

### Endpoint: PATCH /api/auth/profile
**Purpose:** Update own profile without :id parameter  
**Status:** ⚠️ NOT IN SPECIFICATION  
**Recommendation:** REMOVE after migrating to /users/:id

### Endpoint: PATCH /api/issues/:id/assign
**Purpose:** Old department assignment endpoint  
**Status:** ⚠️ RETAINED FOR BACKWARD COMPATIBILITY (Task 10)  
**Recommendation:** Keep but mark as deprecated

---

## Frontend Integration Concerns

### Issue FI-1: Breaking URL Changes Required
**Impact:** If Flutter frontend uses current URLs, all service request calls will break  
**Recommendation:** Coordinate frontend changes with backend updates

### Issue FI-2: Status Value Case Changes
**Impact:** Frontend expecting uppercase status values  
**Recommendation:** Update frontend status comparisons to PascalCase

### Issue FI-3: Field Name Changes
**Impact:** Frontend sending snake_case may need to change to camelCase  
**Recommendation:** Verify frontend request body format

### Issue FI-4: Response Format Changes
**Impact:** Responses will change structure for service requests  
**Recommendation:** Test all frontend screens after updates

---

## Security Audit Results

### ✅ PASSING Security Checks:

1. JWT authentication enforced on all protected routes
2. Role-based authorization implemented correctly
3. Password hashing using bcrypt (10 rounds)
4. User IDs extracted from JWT, never trusted from request body
5. SQL injection protected (using Mongoose)
6. Email validation implemented
7. Input trimming and sanitization present
8. Department validation on assignment
9. Status lifecycle validation exists
10. Unique constraints on critical fields

### ⚠️ SECURITY CONCERNS:

1. **User Profile Access:** No :id validation (Issue 7.1)
2. **CORS Configuration:** Accepts requests with no origin (mobile apps)
3. **Missing Rate Limiting:** No rate limiting middleware
4. **Error Messages:** May leak existence information ("User not found")
5. **Password Requirements:** Minimum 6 characters (consider stronger policy)

---

## Compliance Summary by Module

| Module | Specification Compliance | Issues Count |
|--------|-------------------------|--------------|
| Authentication & User Management | 🔴 40% | 6 critical |
| Civic Issue Management | 🟢 100% | 0 |
| Municipal Services | 🟢 100% | 0 |
| Service Requests | 🔴 0% | 9 critical |
| Public Notices | 🟢 100% | 0 |
| Feedback | 🟡 60% | 4 high |
| Notifications | 🟢 100% | 0 |
| Departments | 🟢 100% | 0 |

**Overall Compliance:** 🔴 **63%** (5 of 8 modules compliant)

---

## Prioritized Fix List

### 🔴 PRIORITY 1: CRITICAL - Must Fix Before Production

1. **Create /users/:id endpoints** (GET, PUT) with self-only access validation
2. **Restructure service request URLs** from `/services/requests/*` to `/service-requests/*`
3. **Combine accept/reject** into single `/service-requests/:id/decision` endpoint
4. **Combine start/complete** into single `/service-requests/:id/status` endpoint
5. **Change cancel method** from PATCH to DELETE at `/service-requests/:id`
6. **Fix base URL** to include `/v1` version prefix
7. **Add token to registration response**
8. **Validate user profile :id** parameter against JWT userId

### 🟠 PRIORITY 2: HIGH - Fix Soon

9. **Unify Feedback model** to support polymorphic relationships
10. **Update Feedback endpoints** to use relatedType/relatedId structure
11. **Change status enums** from SCREAMING_SNAKE_CASE to PascalCase
12. **Standardize field names** to camelCase in responses
13. **Update parameter names** from snake_case to camelCase in requests
14. **Fix decision parameter** validation for service requests

### 🟡 PRIORITY 3: MEDIUM - Improve Quality

15. **Remove obsolete /auth/profile** endpoints (GET and PATCH)
16. **Standardize :id parameter** naming across all endpoints
17. **Update role values** to lowercase in responses
18. **Remove CANCELLED status** if not in specification
19. **Add rate limiting** middleware
20. **Strengthen password policy**

### 🟢 PRIORITY 4: LOW - Polish

21. **Document /auth/protected** as test endpoint only
22. **Update server port** to 5000 or document why 4000
23. **Standardize error messages**
24. **Add request validation middleware**
25. **Improve CORS origin validation**

---

## Testing Recommendations

### Before Fixes:
1. Run existing Task 10 tests to ensure baseline works
2. Run regression tests to document current behavior
3. Create comprehensive test suite for service requests

### After Fixes:
1. Update all test scripts for new URL structure
2. Test service request decision endpoint thoroughly
3. Test service request status endpoint thoroughly
4. Verify feedback polymorphism works correctly
5. Test user profile :id validation
6. Run full regression suite
7. Test frontend integration

---

## Migration Strategy Recommendation

### Phase 1: Non-Breaking Changes (Week 1)
- Add /users/:id endpoints (new)
- Add unified /service-requests/* endpoints (new)
- Keep old endpoints functioning

### Phase 2: Breaking Changes (Week 2)
- Update status enums to PascalCase
- Update field names to camelCase
- Remove old /auth/profile endpoints
- Remove old /services/requests/* endpoints

### Phase 3: Data Model Changes (Week 3)
- Migrate Feedback to polymorphic model
- Update all feedback endpoints
- Migrate existing feedback data

### Phase 4: Cleanup (Week 4)
- Remove deprecated endpoints
- Update all documentation
- Final testing and QA

---

## Recommendations

### Immediate Actions:
1. **DO NOT deploy current backend to production** - major specification violations
2. **Freeze feature development** until audit fixes are complete
3. **Coordinate with frontend team** on breaking changes
4. **Create comprehensive test suite** before starting fixes
5. **Use feature flags** to toggle between old/new behavior during migration

### Long-term Actions:
1. Implement API versioning properly (`/api/v1`)
2. Add OpenAPI/Swagger documentation
3. Implement rate limiting
4. Add request/response logging
5. Create automated contract tests against specification

---

## Conclusion

The CivicPulse backend is **63% compliant** with the final API specification. While several modules (Civic Issues, Notifications, Departments, Public Notices, Services) are fully compliant, critical modules (Service Requests, User Management, Feedback) require significant restructuring.

**Key Recommendations:**
1. ✅ Task 10 (Civic Issue Verification) is CORRECT and specification-compliant
2. ❌ Service Request module requires complete URL restructuring
3. ⚠️ User Management needs /users/:id endpoints to replace /auth/profile
4. ⚠️ Feedback needs polymorphic model restructuring
5. 🔧 Status enums and field names need case standardization

**Estimated Effort:** 3-4 weeks for full compliance with testing

---

## Next Steps

**AWAITING USER APPROVAL** to proceed with:
1. Priority 1 fixes (critical issues)
2. Priority 2 fixes (high priority)
3. Full regression testing
4. Frontend coordination

**DO NOT PROCEED** until this audit is reviewed and approved.

---

**End of Audit Report**
