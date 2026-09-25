# CivicPulse - Complete Validation Documentation

## Overview

This document catalogs all validation rules implemented in CivicPulse across both frontend and backend.

**Validation Strategy:** Defense in Depth
- ✅ **Frontend:** Immediate user feedback, better UX
- ✅ **Backend:** Security enforcement, cannot be bypassed
- ✅ **Database:** Schema constraints as last line of defense

---

## Table of Contents

1. [User Authentication](#user-authentication)
2. [User Profile](#user-profile)
3. [Civic Issues](#civic-issues)
4. [Municipal Services](#municipal-services)
5. [Service Requests](#service-requests)
6. [Feedback](#feedback)
7. [Public Notices](#public-notices)
8. [File Uploads](#file-uploads)
9. [Common Validations](#common-validations)

---

## User Authentication

### Registration

#### Backend Validations
**Location:** `/backend/controllers/authController.js` → `register`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **name** | Required | "Name, email and password are required" |
| | Non-empty after trim | "Name, email and password are required" |
| | Trimmed | Automatic |
| **email** | Required | "Name, email and password are required" |
| | Non-empty after trim | "Name, email and password are required" |
| | Valid email format | "Invalid email format" |
| | Regex: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` | |
| | Unique (not in database) | "Email already registered" |
| | Lowercase + trimmed | Automatic |
| **password** | Required | "Name, email and password are required" |
| | Non-empty after trim | "Name, email and password are required" |
| | Minimum 6 characters | "Password must be at least 6 characters" |
| | Trimmed | Automatic |

#### Frontend Validations
**Location:** `/frontend/src/pages/Register.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **name** | Required (HTML5) | Browser default |
| **email** | Required (HTML5) | Browser default |
| | Type="email" (HTML5) | Browser default |
| **password** | Required (HTML5) | Browser default |
| | Type="password" | Visual only (masking) |
| **All fields** | Non-empty check | "Please fill in all fields" |

#### Database Schema
**Location:** `/backend/models/User.js`

```javascript
{
  name: { type: String, required: true, trim: true },
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  password: { type: String, required: true },
  role: { type: String, enum: ["CITIZEN", "MODERATOR", "DEPARTMENT"], default: "CITIZEN" }
}
```

---

### Login

#### Backend Validations
**Location:** `/backend/controllers/authController.js` → `login`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **email** | Required | "Email and password are required" |
| | Non-empty after trim | "Email and password are required" |
| | Lowercase + trimmed | Automatic |
| | Exists in database | "Invalid email or password" |
| **password** | Required | "Email and password are required" |
| | Non-empty after trim | "Email and password are required" |
| | Trimmed | Automatic |
| | Matches hashed password | "Invalid email or password" |

#### Frontend Validations
**Location:** `/frontend/src/pages/Login.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **email** | Required (HTML5) | Browser default |
| | Type="email" (HTML5) | Browser default |
| **password** | Required (HTML5) | Browser default |
| **All fields** | Non-empty check | "Please fill in all fields" |

---

## User Profile

### Update Profile

#### Backend Validations
**Location:** `/backend/controllers/authController.js` → `updateProfile`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **name** | Optional | - |
| | If provided, non-empty after trim | "Name cannot be empty" |
| | Trimmed | Automatic |
| **email** | Optional | - |
| | If provided, non-empty after trim | "Email cannot be empty" |
| | Valid email format | "Invalid email format" |
| | Regex: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/` | |
| | Unique (not used by another user) | "Email already in use" |
| | Lowercase + trimmed | Automatic |
| **password** | Optional | - |
| | If provided, non-empty after trim | "Password cannot be empty" |
| | Minimum 6 characters | "Password must be at least 6 characters" |
| | Trimmed | Automatic |

#### Frontend Validations
**Location:** `/frontend/src/pages/Profile.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **name** | Type="text" | - |
| **email** | Type="email" (HTML5) | Browser default |
| **All fields** | Optional update | - |

---

## Civic Issues

### Report Issue (Citizen)

#### Backend Validations
**Location:** `/backend/controllers/issueController.js` → `reportIssue`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **title** | Required | "Title, description, category, and location are required" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |
| **description** | Required | "Title, description, category, and location are required" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |
| **category** | Required | "Title, description, category, and location are required" |
| | Valid enum value | "Invalid category" |
| | Allowed: ROADS, WATER, ELECTRICITY, SANITATION, PUBLIC_SAFETY, HEALTHCARE, EDUCATION, ENVIRONMENT, OTHER | |
| | Uppercase conversion | Automatic |
| **location** | Required | "Title, description, category, and location are required" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |
| **image** | Optional | - |
| | Image file only | "Invalid file type. Only images are allowed." |
| | Max 5MB | "File too large. Maximum size is 5MB." |
| | MIME types: image/jpeg, image/jpg, image/png, image/webp | "Only JPEG, PNG, and WEBP images are allowed." |

#### Frontend Validations
**Location:** `/frontend/src/pages/ReportIssue.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **title** | Required (HTML5) | Browser default |
| **description** | Required (HTML5) | Browser default |
| **category** | Required (HTML5) | Browser default |
| **location** | Required (HTML5) | Browser default |
| **image** | Optional | - |
| | Max 5MB | "Image must be less than 5MB" |
| | Image file check | "Only image files are allowed" |

#### Database Schema
**Location:** `/backend/models/CivicIssue.js`

```javascript
{
  title: { type: String, required: true, trim: true },
  description: { type: String, required: true, trim: true },
  category: { 
    type: String, 
    required: true, 
    enum: ["ROADS", "WATER", "ELECTRICITY", "SANITATION", 
           "PUBLIC_SAFETY", "HEALTHCARE", "EDUCATION", "ENVIRONMENT", "OTHER"] 
  },
  location: { type: String, required: true, trim: true },
  image_url: { type: String, default: null, trim: true },
  status: { 
    type: String, 
    enum: ["REPORTED", "ASSIGNED", "IN_PROGRESS", "RESOLVED", "REJECTED"],
    default: "REPORTED" 
  }
}
```

---

### Resolve Issue (Department)

#### Backend Validations
**Location:** `/backend/controllers/issueController.js` → `resolveIssue`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **issueId** | Valid MongoDB ObjectId | "Invalid issue ID format" |
| | Issue exists | "Issue not found" |
| | Status is IN_PROGRESS | "Only IN_PROGRESS issues can be resolved" |
| **resolution_description** | Required | "Resolution description is required" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |
| **evidence** (file) | Required | "Resolution evidence image is required" |
| | Image file only | "Invalid file type. Only images are allowed." |
| | Max 5MB | "File too large. Maximum size is 5MB." |

#### Frontend Validations
**Location:** `/frontend/src/pages/DepartmentIssueDetails.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **resolution_description** | Required (HTML5) | Browser default |
| | Non-empty check | "Please enter a resolution description." |
| **evidence** | Required | "Please upload resolution evidence." |
| | Max 5MB | "File size must be less than 5MB" |
| | Image file check | "Only image files are allowed" |

---

## Municipal Services

### Browse Services

#### Backend Validations
**Location:** `/backend/controllers/serviceController.js` → `getServices`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **category** (query param) | Optional | - |
| | If provided, valid enum | "Invalid category" |
| | Allowed: ADMINISTRATIVE, INFRASTRUCTURE, HEALTH_SERVICES, EDUCATION_SERVICES, ENVIRONMENT_SERVICES, SOCIAL_SERVICES, LEGAL_SERVICES, EMERGENCY_SERVICES, OTHER | |
| | Uppercase conversion | Automatic |

#### Database Schema
**Location:** `/backend/models/MunicipalService.js`

```javascript
{
  name: { type: String, required: true, unique: true, trim: true },
  description: { type: String, required: true, trim: true },
  category: { 
    type: String, 
    required: true, 
    enum: ["ADMINISTRATIVE", "INFRASTRUCTURE", "HEALTH_SERVICES", 
           "EDUCATION_SERVICES", "ENVIRONMENT_SERVICES", "SOCIAL_SERVICES", 
           "LEGAL_SERVICES", "EMERGENCY_SERVICES", "OTHER"] 
  },
  isActive: { type: Boolean, default: true },
  department_id: { type: ObjectId, ref: "Department", required: true }
}
```

---

## Service Requests

### Create Service Request (Citizen)

#### Backend Validations
**Location:** `/backend/controllers/serviceController.js` → `submitServiceRequest`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **service_id** | Required | "service_id is required" |
| | Valid MongoDB ObjectId | "Invalid service_id format" |
| | Service exists | "Service not found" |
| | Service is active | "Service is not active" |
| | Service has department | "Service has no assigned department" |
| **notes** | Optional | - |
| | If provided, trimmed | Automatic |
| | Empty string → null | Automatic |
| | Max 1000 characters | Database enforces |

#### Frontend Validations
**Location:** `/frontend/src/pages/RequestService.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **service_id** | Required | "Please select a service" |
| **notes** | Optional | - |

#### Database Schema
**Location:** `/backend/models/ServiceRequest.js`

```javascript
{
  service_id: { type: ObjectId, ref: "MunicipalService", required: true },
  department_id: { type: ObjectId, ref: "Department", required: true },
  citizen_id: { type: ObjectId, ref: "User", required: true },
  notes: { type: String, default: null, trim: true, maxlength: 1000 },
  status: { 
    type: String,
    enum: ["PENDING", "ACCEPTED", "IN_PROGRESS", "COMPLETED", "REJECTED", "CANCELLED"],
    default: "PENDING"
  },
  rejectionReason: { type: String, default: null, trim: true, maxlength: 1000 }
}
```

---

### Reject Service Request (Department)

#### Backend Validations
**Location:** `/backend/controllers/departmentServiceController.js` → `rejectServiceRequest`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **requestId** | Valid MongoDB ObjectId | "Invalid request ID format" |
| | Request exists | "Service request not found" |
| | Belongs to authenticated department | "Access denied: This request is not assigned to your department" |
| | Status is PENDING | "Only PENDING requests can be rejected" |
| **rejectionReason** | Required | "rejectionReason is required when rejecting a service request" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |

#### Frontend Validations
**Location:** `/frontend/src/pages/DepartmentServiceRequestDetails.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **rejectionReason** | Required (HTML5) | Browser default |
| | Non-empty check | "Please provide a rejection reason." |

---

### Get Department Service Requests (List)

#### Backend Validations
**Location:** `/backend/controllers/departmentServiceController.js` → `getDepartmentServiceRequests`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **status** (query) | Optional | - |
| | Valid enum | "Invalid status. Valid statuses are PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, REJECTED, CANCELLED" |
| | Uppercase conversion | Automatic |
| **page** (query) | Optional, default: 1 | - |
| | Positive integer | "Page must be a positive integer" |
| **limit** (query) | Optional, default: 10 | - |
| | Positive integer | "Limit must be a positive integer" |
| | Max: 50 | Capped automatically |

#### Frontend Validations
**Location:** `/frontend/src/pages/DepartmentServiceRequests.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **status filter** | Valid option from dropdown | - |
| **pagination** | Enforced by backend | - |

---

## Feedback

### Submit Civic Issue Feedback (Citizen)

#### Backend Validations
**Location:** `/backend/controllers/feedbackController.js` → `submitIssueFeedback`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **issueId** | Valid MongoDB ObjectId | "Invalid issue ID format" |
| | Issue exists | "Issue not found" |
| | Issue status is RESOLVED | "Feedback can only be submitted for resolved issues" |
| | Citizen is the reporter | "Access denied: You can only provide feedback on your own issues" |
| | No duplicate feedback | "You have already submitted feedback for this issue" |
| **rating** | Required | "Rating is required" |
| | Integer 1-5 | "Rating must be between 1 and 5" |
| **comment** | Optional | - |
| | If provided, trimmed | Automatic |
| | Empty string → null | Automatic |

#### Frontend Validations
**Location:** `/frontend/src/pages/IssueDetails.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **rating** | Required (star selection) | "Please select a rating" |
| **comment** | Optional | - |

#### Database Schema
**Location:** `/backend/models/Feedback.js`

```javascript
{
  issue_id: { type: ObjectId, ref: "CivicIssue", required: true },
  user_id: { type: ObjectId, ref: "User", required: true },
  rating: { type: Number, required: true, min: 1, max: 5 },
  comment: { type: String, default: null, trim: true }
}
```

---

### Submit Service Request Feedback (Citizen)

#### Backend Validations
**Location:** `/backend/controllers/serviceController.js` → `submitServiceRequestFeedback`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **requestId** | Valid MongoDB ObjectId | "Invalid request ID format" |
| | Request exists | "Service request not found" |
| | Request status is COMPLETED | "Feedback can only be submitted for completed service requests" |
| | Citizen is the requester | "Access denied: You can only provide feedback on your own service requests" |
| | No duplicate feedback | "You have already submitted feedback for this service request" |
| **rating** | Required | "Rating is required" |
| | Integer | "Rating must be an integer" |
| | Between 1-5 | "Rating must be between 1 and 5" |
| **comment** | Optional | - |
| | If provided, trimmed | Automatic |
| | Empty string → null | Automatic |

#### Frontend Validations
**Location:** `/frontend/src/pages/ServiceRequestDetails.jsx`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **rating** | Required (star selection) | "Please select a rating" |
| **comment** | Optional | - |

---

## Public Notices

### Create Public Notice (Moderator)

#### Backend Validations
**Location:** `/backend/controllers/publicNoticeController.js` → `createPublicNotice`

| Field | Validation | Error Message |
|-------|------------|---------------|
| **title** | Required | "Title, content, and category are required" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |
| **content** | Required | "Title, content, and category are required" |
| | Non-empty after trim | Same as above |
| | Trimmed | Automatic |
| **category** | Required | "Title, content, and category are required" |
| | Valid enum | "Invalid category" |
| | Allowed: GENERAL, EMERGENCY, MAINTENANCE, EVENT, POLICY, ANNOUNCEMENT, OTHER | |
| | Uppercase conversion | Automatic |

#### Database Schema
**Location:** `/backend/models/PublicNotice.js`

```javascript
{
  title: { type: String, required: true, trim: true },
  content: { type: String, required: true, trim: true },
  category: { 
    type: String, 
    required: true, 
    enum: ["GENERAL", "EMERGENCY", "MAINTENANCE", "EVENT", 
           "POLICY", "ANNOUNCEMENT", "OTHER"] 
  },
  status: { 
    type: String, 
    enum: ["DRAFT", "PUBLISHED", "ARCHIVED"],
    default: "DRAFT" 
  }
}
```

---

## File Uploads

### Image Upload Constraints

#### Backend Validations
**Location:** `/backend/config/cloudinary.js`

| Constraint | Value | Enforcement |
|------------|-------|-------------|
| **File Size** | Max 5MB | Multer middleware |
| **File Type** | Images only | Multer file filter |
| **MIME Types** | image/jpeg, image/jpg, image/png, image/webp | Multer file filter |
| **Storage** | Memory buffer | No disk writes |

**Error Messages:**
- File too large: `"File too large. Maximum size is 5MB."`
- Wrong type: `"Invalid file type. Only images are allowed."`
- Wrong format: `"Only JPEG, PNG, and WEBP images are allowed."`

#### Frontend Validations

**Civic Issue Images:**
```javascript
// Location: ReportIssue.jsx
if (file.size > 5 * 1024 * 1024) {
  setError('Image must be less than 5MB');
}
if (!file.type.startsWith('image/')) {
  setError('Only image files are allowed');
}
```

**Resolution Evidence:**
```javascript
// Location: DepartmentIssueDetails.jsx
if (file.size > 5 * 1024 * 1024) {
  alert('File size must be less than 5MB');
}
if (!file.type.startsWith('image/')) {
  alert('Only image files are allowed');
}
```

---

## Common Validations

### MongoDB ObjectId Validation

**Pattern used throughout backend:**
```javascript
if (!mongoose.Types.ObjectId.isValid(id)) {
    return res.status(400).json({ message: "Invalid ID format" });
}
```

**Used for:**
- issueId
- serviceId
- requestId
- noticeId
- departmentId
- userId

---

### Pagination Validation

**Pattern used in list endpoints:**
```javascript
const pageNum = parseInt(page) || 1;
const limitNum = parseInt(limit) || 10;
const maxLimit = 50;

if (pageNum < 1) {
    return res.status(400).json({ message: "Page must be a positive integer" });
}

const finalLimit = limitNum > maxLimit ? maxLimit : limitNum;
const skip = (pageNum - 1) * finalLimit;
```

**Applied to:**
- My Issues
- My Service Requests
- Department Service Requests
- Department Civic Issues

---

### Role-Based Access Control

**Pattern used throughout:**
```javascript
// Check if user has required role
if (user.role !== "DEPARTMENT") {
    return res.status(403).json({
        message: "Only department users can access this endpoint"
    });
}
```

**Roles:**
- CITIZEN
- MODERATOR
- DEPARTMENT

---

## Validation Summary Tables

### String Fields

| Field Type | Trim | Required | Min Length | Max Length | Format |
|------------|------|----------|------------|------------|--------|
| name | ✅ | ✅ | - | - | - |
| email | ✅ | ✅ | - | - | Email regex |
| password | ✅ | ✅ | 6 | - | - |
| title | ✅ | ✅ | - | - | - |
| description | ✅ | ✅ | - | - | - |
| location | ✅ | ✅ | - | - | - |
| notes | ✅ | ❌ | - | 1000 | - |
| comment | ✅ | ❌ | - | - | - |
| resolution_description | ✅ | ✅ | - | - | - |
| rejectionReason | ✅ | ✅ | - | 1000 | - |

### Enum Fields

| Field | Values | Default | Case-Insensitive |
|-------|--------|---------|------------------|
| role | CITIZEN, MODERATOR, DEPARTMENT | CITIZEN | ❌ |
| issue_category | ROADS, WATER, ELECTRICITY, SANITATION, PUBLIC_SAFETY, HEALTHCARE, EDUCATION, ENVIRONMENT, OTHER | - | ✅ (uppercase) |
| issue_status | REPORTED, ASSIGNED, IN_PROGRESS, RESOLVED, REJECTED | REPORTED | ❌ |
| service_category | ADMINISTRATIVE, INFRASTRUCTURE, HEALTH_SERVICES, etc. | - | ✅ (uppercase) |
| request_status | PENDING, ACCEPTED, IN_PROGRESS, COMPLETED, REJECTED, CANCELLED | PENDING | ✅ (uppercase) |
| notice_category | GENERAL, EMERGENCY, MAINTENANCE, EVENT, POLICY, ANNOUNCEMENT, OTHER | - | ✅ (uppercase) |
| notice_status | DRAFT, PUBLISHED, ARCHIVED | DRAFT | ❌ |

### Numeric Fields

| Field | Type | Min | Max | Required |
|-------|------|-----|-----|----------|
| rating | Integer | 1 | 5 | ✅ |
| page | Integer | 1 | ∞ | ❌ (default: 1) |
| limit | Integer | 1 | 50 | ❌ (default: 10) |

---

## Frontend HTML5 Validations

### Input Types Used

```html
<input type="email" required />      <!-- Email validation + required -->
<input type="password" required />   <!-- Password masking + required -->
<input type="text" required />       <!-- Text required -->
<textarea required></textarea>       <!-- Textarea required -->
<select required></select>           <!-- Select required -->
```

### Custom JavaScript Validations

- File size checks
- File type checks
- Empty field checks (beyond HTML5)
- Rating selection checks
- Confirmation dialogs for destructive actions

---

## Error Handling Strategy

### Backend Error Responses

**Format:**
```json
{
  "message": "Error description"
}
```

**Status Codes:**
- `400` - Bad Request (validation failure)
- `401` - Unauthorized (not logged in)
- `403` - Forbidden (wrong role/permissions)
- `404` - Not Found
- `500` - Server Error

### Frontend Error Display

**Patterns:**
1. Inline field errors (below input)
2. Form-level error banners (above form)
3. Alert dialogs for critical errors
4. Toast notifications (not yet implemented)

---

## Testing Validations

### Backend Unit Tests
**Location:** `/backend/tests/*.sh`

- Test valid inputs (should succeed)
- Test invalid inputs (should fail with appropriate message)
- Test boundary conditions (min/max values)
- Test SQL injection attempts (should be blocked)
- Test XSS attempts (should be escaped)

### Frontend Manual Tests
**Location:** `/backend/tests/PHASE6B_BROWSER_TEST_GUIDE.md`

- Test form submission with empty fields
- Test form submission with invalid data
- Test file uploads exceeding size limit
- Test file uploads with wrong format
- Test special characters in text fields

---

## Security Considerations

✅ **SQL Injection:** Prevented by MongoDB + Mongoose parameterized queries  
✅ **XSS:** Prevented by React's automatic escaping  
✅ **CSRF:** Token-based authentication (stateless JWT)  
✅ **File Upload Attacks:** MIME type checking, size limits, no execution  
✅ **NoSQL Injection:** Mongoose schema validation  
✅ **Mass Assignment:** Explicit field selection in controllers  
✅ **Enumeration:** Generic error messages for authentication  

---

## Gaps & Improvements

### Current Limitations

1. **No Rate Limiting:** No protection against brute force attacks
2. **No CAPTCHA:** Registration/login vulnerable to bots
3. **Weak Password Policy:** Only 6-character minimum, no complexity rules
4. **No Email Verification:** Email addresses not verified
5. **No Phone Validation:** Mobile numbers accepted as-is (if added)
6. **No Address Validation:** Locations are free-text
7. **No Image Content Validation:** Only checks MIME type, not actual content
8. **No Profanity Filter:** User-generated content not screened
9. **No Duplicate Detection:** Multiple similar issues can be created
10. **No Input Sanitization:** HTML/script tags not explicitly stripped

### Recommended Additions

1. **Password Strength Meter:** Visual feedback on registration
2. **Email Verification:** Send confirmation email with token
3. **Rate Limiting:** Limit API requests per IP/user
4. **CAPTCHA:** On registration and login forms
5. **Content Moderation:** Flagging system for inappropriate content
6. **Input Sanitization:** Strip HTML tags from text fields
7. **Image Content Check:** Validate image is not corrupted/malicious
8. **Geolocation:** Validate addresses against map API
9. **Duplicate Detection:** Warn if similar issue already exists
10. **Audit Logging:** Track all validation failures

---

## Conclusion

CivicPulse implements a **defense-in-depth validation strategy** with:

✅ **Frontend validation** for immediate UX feedback  
✅ **Backend validation** for security enforcement  
✅ **Database constraints** as final safety net  
✅ **Consistent error messages** across the application  
✅ **Proper HTTP status codes** for different error types  

The validation coverage is comprehensive for core functionality, with room for enhancement in advanced security features and user experience improvements.

---

**END OF VALIDATION DOCUMENTATION**
