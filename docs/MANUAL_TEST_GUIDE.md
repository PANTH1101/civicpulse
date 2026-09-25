# Manual Testing Guide: Department Auto-Assignment

## Overview
This guide tests the new feature where Municipal Services have fixed department assignments. Citizens can no longer manually select departments - they are automatically assigned based on the selected service.

## Test Account
- **Email**: test-citizen-1789460414@civicpulse.test
- **Password**: Test123!

## Frontend URL
http://localhost:5174

---

## Test Scenario 1: Browse Services with Department Info

### Steps:
1. Login with test account
2. Navigate to "Browse Services" from dashboard
3. Observe each service card

### Expected Results:
- ✅ Each service card shows the service name, category, and description
- ✅ Each service card shows a department badge with icon (e.g., "General Services Department")
- ✅ Department badge appears below the description, above the "Request Service" button
- ✅ All 18 services are displayed with their respective departments:
  - Birth Certificate → General Services Department
  - Death Certificate → General Services Department  
  - Marriage Certificate → General Services Department
  - Residence Certificate → General Services Department
  - Property Tax → General Services Department
  - Street Light Installation → Electricity Department
  - Road Repair → Roads and Transportation Department
  - Water Connection → Water Supply Department
  - Drainage/Sewage → Sanitation Department
  - Public Health Inspection → Healthcare Department
  - Vector Control → Healthcare Department
  - Health Camp → Healthcare Department
  - School Enrollment → Education Department
  - Scholarship → Education Department
  - Tree Planting → Environment Department
  - Waste Collection → Sanitation Department
  - Social Welfare → General Services Department
  - Emergency Relief → Public Safety Department

---

## Test Scenario 2: Request Service with Auto-Assigned Department

### Steps:
1. From "Browse Services", click "Request Service" on "Birth Certificate Application"
2. Observe the form

### Expected Results:
- ✅ Service dropdown is pre-selected with "Birth Certificate Application"
- ✅ **NO department dropdown visible** (removed!)
- ✅ After service is selected, a blue info box appears showing:
  - "Responsible Department" label
  - "General Services Department" name
  - Department email and phone

### Steps (continue):
3. Add optional notes: "Test request for birth certificate"
4. Click "Submit Request"

### Expected Results:
- ✅ Request submits successfully
- ✅ Redirected to "My Service Requests" page
- ✅ New request appears in the list
- ✅ Request shows "General Services Department" (not Roads or any other department)
- ✅ Status is "PENDING"

---

## Test Scenario 3: Request Different Service Types

### Steps:
1. Navigate to "Browse Services"
2. Click "Request Service" on "Road Repair Request"
3. Observe the department info box

### Expected Results:
- ✅ Service dropdown shows "Road Repair Request"
- ✅ Department info box shows "Roads and Transportation Department"
- ✅ NO way to change the department

### Steps (continue):
4. Submit the request with notes: "Pothole on Main Street"
5. Navigate to "My Service Requests"

### Expected Results:
- ✅ New request shows "Roads and Transportation Department"
- ✅ NOT General Services or any other department

---

## Test Scenario 4: Change Service Selection

### Steps:
1. Navigate to "Request Service" page (without pre-selection)
2. Select "Water Connection Application"
3. Observe department info box

### Expected Results:
- ✅ Department info box shows "Water Supply Department"

### Steps (continue):
4. Change service to "Health Camp Registration"
5. Observe department info box update

### Expected Results:
- ✅ Department info box updates to show "Healthcare Department"
- ✅ Department info changes dynamically when service changes

---

## Test Scenario 5: Verify Civic Issues Still Work (Unchanged)

### Steps:
1. Navigate to "Report Issue" from dashboard
2. Observe the form

### Expected Results:
- ✅ Civic Issue form still has manual department selection dropdown
- ✅ Civic Issues are NOT affected by this change
- ✅ Only Municipal Service Requests have fixed departments

### Steps (continue):
3. Fill out form with:
   - Title: "Broken streetlight test"
   - Description: "Testing civic issues still work"
   - Category: INFRASTRUCTURE
   - Department: (select any department manually)
   - Location: "Test Street"
4. Submit

### Expected Results:
- ✅ Issue submits successfully
- ✅ Uses the department YOU selected (not auto-assigned)

---

## Test Scenario 6: All Previous Workflows Still Work

### Quick Smoke Test:
1. ✅ Dashboard loads
2. ✅ Notifications page works
3. ✅ Profile page works (view/edit)
4. ✅ My Service Requests page shows all requests
5. ✅ Cancel service request works
6. ✅ Public notices page works
7. ✅ Browse civic issues works
8. ✅ Report civic issue works (with manual department selection)

---

## Security Verification (Backend)

Run the automated test:
```bash
cd backend
./tests/test-department-auto-assignment.sh
```

### Expected Results:
- ✅ All 6 test steps pass
- ✅ Service request without department_id succeeds
- ✅ Backend auto-assigns correct department
- ✅ Malicious request with wrong department_id is IGNORED
- ✅ Backend enforces department from service, not from client

---

## What Changed

### Backend:
1. ✅ `MunicipalService` model now has `department_id` field (required)
2. ✅ Service request creation ignores client-provided `department_id`
3. ✅ Service request creation looks up service's department and uses it
4. ✅ `GET /api/services` returns department info for each service
5. ✅ All 18 services re-seeded with department assignments
6. ✅ Security comment added: "SECURITY: Ignore any department_id sent from client"

### Frontend:
1. ✅ `RequestService.jsx` - department dropdown **REMOVED**
2. ✅ `RequestService.jsx` - department shown as read-only info box
3. ✅ `RequestService.jsx` - only sends `service_id` and `notes` to backend
4. ✅ `MunicipalServices.jsx` - displays department on each service card
5. ✅ Department info updates dynamically when service selection changes

### Unchanged:
- ✅ Civic Issues still have manual department selection (moderator assigns)
- ✅ All other citizen workflows unchanged (notifications, profile, etc.)
- ✅ All authentication flows unchanged

---

## Summary

**Core Business Rule Enforced:**
Each Municipal Service has exactly one responsible Department, and citizens cannot override this assignment. The backend automatically assigns the correct department when a service request is created.

**Security:**
Client-provided department_id is completely ignored. Even if a malicious client tries to send a different department, the backend will use the service's assigned department.

**User Experience:**
Citizens see which department handles each service, but they don't need to (and can't) make the selection themselves.
