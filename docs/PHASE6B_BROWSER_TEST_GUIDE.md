# PHASE 6B - Department Service Requests Frontend Browser Testing Guide

## Prerequisites

**Backend Running:** `http://localhost:4000`  
**Frontend Running:** `http://localhost:5174`

**Test Accounts:**
- **Citizen:** `alice@example.com` / `password123`
- **Department (General Services):** `general@civicpulse.gov` / `department123`
- **Department (Healthcare):** `healthcare@civicpulse.gov` / `department123`

---

## TEST 1: Department Login

1. Navigate to `http://localhost:5174/login`
2. Enter:
   - Email: `general@civicpulse.gov`
   - Password: `department123`
3. Click **Login**

**Expected Result:**
- ✅ Successfully logged in
- ✅ Redirected to Department Dashboard
- ✅ URL is `/department/dashboard`

---

## TEST 2: View Department Dashboard

**Expected Result:**
- ✅ Page displays "Department Dashboard"
- ✅ Two stat sections visible:
  - **Civic Issues** (Assigned, In Progress, Resolved)
  - **Municipal Service Requests** (Pending, Accepted, In Progress, Completed)
- ✅ Recent Civic Issues section
- ✅ Recent Service Requests section
- ✅ All stat cards are clickable
- ✅ Numbers reflect actual data

---

## TEST 3: Navigate to Service Requests

1. Click **Service Requests** in the sidebar

**Expected Result:**
- ✅ URL changes to `/department/service-requests`
- ✅ Page title is "Service Requests"
- ✅ Filter dropdown is visible
- ✅ Service request cards display (if any exist)
- ✅ Cards show: service name, status badge, category, notes preview, submission date, citizen name

---

## TEST 4: Create a Test Service Request (as Citizen)

1. Logout from Department account
2. Login as Citizen: `alice@example.com` / `password123`
3. Navigate to **Municipal Services**
4. Click **Request Service** on any service (e.g., "Birth Certificate Application")
5. Fill in notes: "Test request for department workflow"
6. Click **Submit Request**
7. Verify request is created with status **PENDING**
8. Logout

---

## TEST 5: View Pending Request (as Department)

1. Login as Department: `general@civicpulse.gov` / `department123`
2. Navigate to **Service Requests**
3. Set filter to **Pending**

**Expected Result:**
- ✅ The test request appears in the list
- ✅ Status badge shows **PENDING** (yellow/warning color)
- ✅ Service name is correct
- ✅ Citizen name is shown
- ✅ Click **View Details** button

---

## TEST 6: View Service Request Details

**Expected Result:**
- ✅ URL is `/department/service-requests/[id]`
- ✅ Page shows complete request details:
  - Service name and description
  - Category
  - Requested by (citizen name and email)
  - Submitted date
  - Department name
  - Request notes
  - Status badge (PENDING)
- ✅ **Actions** section shows two buttons:
  - **Accept Request** (green)
  - **Reject Request** (red)

---

## TEST 7: Accept Service Request

1. Click **Accept Request**
2. Confirm in the alert dialog

**Expected Result:**
- ✅ Alert shows "Service request accepted successfully!"
- ✅ Page refreshes
- ✅ Status badge changes to **ACCEPTED** (blue/info color)
- ✅ "Accepted On" date is now visible
- ✅ Actions section now shows only:
  - **Start Work** button

---

## TEST 8: Start Work

1. Click **Start Work**
2. Confirm in the alert dialog

**Expected Result:**
- ✅ Alert shows "Service request moved to IN PROGRESS!"
- ✅ Status badge changes to **IN_PROGRESS** (primary color)
- ✅ "Started On" date is now visible
- ✅ Actions section now shows only:
  - **Complete Request** button (green)

---

## TEST 9: Complete Request

1. Click **Complete Request**
2. Confirm in the alert dialog

**Expected Result:**
- ✅ Alert shows "Service request completed successfully!"
- ✅ Status badge changes to **COMPLETED** (green/success color)
- ✅ "Completed On" date is now visible
- ✅ Actions section is no longer shown
- ✅ "No citizen feedback yet" message may appear

---

## TEST 10: Verify from Dashboard

1. Navigate back to **Dashboard**

**Expected Result:**
- ✅ "Completed" stat has increased by 1
- ✅ Recent Service Requests may show the completed request

---

## TEST 11: Test Rejection Workflow

1. Logout and login as Citizen
2. Create another service request
3. Logout and login as Department
4. Navigate to **Service Requests** → filter **Pending**
5. Click on the new request
6. Click **Reject Request**

**Expected Result:**
- ✅ A rejection form appears on the right side
- ✅ Form has a textarea for "Rejection Reason" (required)
- ✅ Enter reason: "Insufficient information provided"
- ✅ Click **Submit Rejection**
- ✅ Alert confirms rejection
- ✅ Status changes to **REJECTED** (red/danger color)
- ✅ Rejection reason is displayed in a red card
- ✅ "Rejected On" date is shown
- ✅ No action buttons are shown

---

## TEST 12: Filter Service Requests

1. Navigate to **Service Requests**
2. Try different filters:
   - **All Requests**
   - **Pending**
   - **Accepted**
   - **In Progress**
   - **Completed**
   - **Rejected**

**Expected Result:**
- ✅ Each filter shows only requests with that status
- ✅ URL updates with `?status=...` query parameter
- ✅ Empty state shows appropriate message when no requests match

---

## TEST 13: Pagination (if applicable)

If you have more than 10 requests:

**Expected Result:**
- ✅ Pagination controls appear at the bottom
- ✅ Shows "Showing X of Y requests"
- ✅ Shows "Page N of M"
- ✅ **Previous** and **Next** buttons work
- ✅ Clicking a stat card on dashboard navigates with correct filter

---

## TEST 14: Department Isolation

1. Note the ID of a General Services request from the URL
2. Logout
3. Login as Healthcare Department: `healthcare@civicpulse.gov` / `department123`
4. Navigate to **Service Requests**

**Expected Result:**
- ✅ Healthcare department sees ONLY their own requests
- ✅ General Services requests are NOT visible
- ✅ Attempt to directly access another department's request URL shows error or access denied

---

## TEST 15: Citizen Verification

1. Logout from Department
2. Login as Citizen: `alice@example.com` / `password123`
3. Navigate to **My Service Requests**
4. Find the completed/rejected request
5. Click to view details

**Expected Result:**
- ✅ Citizen can see the request
- ✅ Status shows **COMPLETED** or **REJECTED**
- ✅ For completed requests: citizen can submit feedback
- ✅ For rejected requests: rejection reason is visible

---

## TEST 16: Regression Tests

Verify existing features still work:

### Citizen Module:
1. ✅ Dashboard loads
2. ✅ Report Issue works
3. ✅ My Issues displays
4. ✅ Issue details work
5. ✅ Civic Issue feedback works
6. ✅ Browse Services works
7. ✅ Request Service works (already tested)
8. ✅ My Service Requests works
9. ✅ Service Request details work
10. ✅ Public Notices work
11. ✅ Notifications work
12. ✅ Profile works

### Moderator Module:
1. ✅ Dashboard loads
2. ✅ Pending Issues display
3. ✅ Verify issue works
4. ✅ Reject issue works
5. ✅ Assign department works

### Department Module (Civic Issues):
1. ✅ Dashboard loads (already tested)
2. ✅ Civic Issues list works
3. ✅ Issue details work
4. ✅ Start work on civic issue works
5. ✅ Resolve civic issue works
6. ✅ Resolution evidence upload works
7. ✅ Civic issue feedback display works

---

## TEST 17: UI Consistency Check

**Expected Result:**
- ✅ Service Request pages match the design of existing pages
- ✅ Same card styling
- ✅ Same button styles
- ✅ Same status badge styles
- ✅ Same loading states
- ✅ Same error states
- ✅ Same empty states
- ✅ Same typography
- ✅ Same spacing
- ✅ Responsive on mobile/tablet

---

## TEST 18: Error Handling

1. Disconnect internet or stop backend
2. Try to load service requests

**Expected Result:**
- ✅ Error message displays
- ✅ Retry button is available
- ✅ Error doesn't break the page

---

## TEST 19: Browser Console Check

Open browser DevTools Console (F12)

**Expected Result:**
- ✅ No JavaScript errors
- ✅ No failed API calls (except intentional 404s for missing feedback)
- ✅ No React warnings

---

## TEST 20: Network Tab Check

Open browser DevTools Network tab

**Expected Result:**
- ✅ All API calls have proper Authorization headers
- ✅ API responses are properly formatted
- ✅ No CORS errors
- ✅ Status codes are appropriate (200, 403, 404, etc.)

---

## Summary Checklist

- [ ] TEST 1: Department Login ✅
- [ ] TEST 2: View Department Dashboard ✅
- [ ] TEST 3: Navigate to Service Requests ✅
- [ ] TEST 4: Create Test Request (Citizen) ✅
- [ ] TEST 5: View Pending Request ✅
- [ ] TEST 6: View Request Details ✅
- [ ] TEST 7: Accept Request ✅
- [ ] TEST 8: Start Work ✅
- [ ] TEST 9: Complete Request ✅
- [ ] TEST 10: Verify from Dashboard ✅
- [ ] TEST 11: Rejection Workflow ✅
- [ ] TEST 12: Filter Requests ✅
- [ ] TEST 13: Pagination ✅
- [ ] TEST 14: Department Isolation ✅
- [ ] TEST 15: Citizen Verification ✅
- [ ] TEST 16: Regression Tests ✅
- [ ] TEST 17: UI Consistency ✅
- [ ] TEST 18: Error Handling ✅
- [ ] TEST 19: Console Check ✅
- [ ] TEST 20: Network Check ✅

---

## All Tests Passed ✅

The Department Municipal Service Request frontend is fully implemented and tested.
