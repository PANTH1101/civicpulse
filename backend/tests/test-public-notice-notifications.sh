#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 2: PUBLIC NOTICE NOTIFICATIONS - COMPREHENSIVE TEST        ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

PASSED=0
FAILED=0

test_pass() {
    echo "✅ PASS: $1"
    ((PASSED++))
}

test_fail() {
    echo "❌ FAIL: $1"
    ((FAILED++))
}

# =========================================================================
# SETUP: Create test users
# =========================================================================
echo -e "\n[SETUP] Creating test users..."

# Register 3 citizens
CITIZEN1_EMAIL="citizen1.$(date +%s)@example.com"
CITIZEN2_EMAIL="citizen2.$(date +%s)@example.com"
CITIZEN3_EMAIL="citizen3.$(date +%s)@example.com"

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Citizen One\",\"email\":\"$CITIZEN1_EMAIL\",\"password\":\"password123\"}" > /dev/null

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Citizen Two\",\"email\":\"$CITIZEN2_EMAIL\",\"password\":\"password123\"}" > /dev/null

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Citizen Three\",\"email\":\"$CITIZEN3_EMAIL\",\"password\":\"password123\"}" > /dev/null

echo "✓ Created 3 citizen users"

# Login citizens
CITIZEN1_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN1_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

CITIZEN2_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN2_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

CITIZEN3_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN3_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

echo "✓ Citizens logged in"

# Login as department user
DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}' | jq -r '.token')

echo "✓ Department user logged in"

# =========================================================================
# TEST A: Create and publish a public notice
# =========================================================================
echo -e "\n[TEST A] Create and publish public notice"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create draft notice
CREATE_NOTICE=$(curl -s -X POST "$BASE_URL/notices" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Water Supply Interruption","content":"Water supply will be interrupted on Friday for maintenance.","category":"MAINTENANCE"}')

NOTICE_ID=$(echo "$CREATE_NOTICE" | jq -r '.notice.id')
echo "✓ Created draft notice: $NOTICE_ID"

# Get initial notification count for citizen 1
INITIAL_COUNT=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" | jq '.count')

echo "✓ Citizen 1 initial notification count: $INITIAL_COUNT"

# Publish the notice
echo -e "\nPublishing notice..."
PUBLISH_RESPONSE=$(curl -s -X PATCH "$BASE_URL/notices/$NOTICE_ID/publish" \
    -H "Authorization: Bearer $DEPT_TOKEN")

echo "$PUBLISH_RESPONSE" | jq '.'

if echo "$PUBLISH_RESPONSE" | jq '.notice.status' | grep -q "PUBLISHED"; then
    test_pass "Notice status changed to PUBLISHED"
else
    test_fail "Notice status not PUBLISHED"
fi

if echo "$PUBLISH_RESPONSE" | jq '.notice.publishedBy' | grep -q "id"; then
    test_pass "publishedBy field populated"
else
    test_fail "publishedBy field not populated"
fi

if echo "$PUBLISH_RESPONSE" | jq '.notice.publishedAt' | grep -q "20"; then
    test_pass "publishedAt field populated"
else
    test_fail "publishedAt field not populated"
fi

# =========================================================================
# TEST B: Verify ALL citizens received notification
# =========================================================================
echo -e "\n[TEST B] Verify ALL citizens received notification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

sleep 1  # Brief pause to ensure notifications are created

# Check citizen 1
echo -e "\nChecking Citizen 1 notifications..."
CITIZEN1_NOTIF=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN")

echo "$CITIZEN1_NOTIF" | jq '.notifications[0]'

NEW_COUNT=$(echo "$CITIZEN1_NOTIF" | jq '.count')
echo "✓ Citizen 1 new notification count: $NEW_COUNT"

if [ "$NEW_COUNT" -gt "$INITIAL_COUNT" ]; then
    test_pass "Citizen 1 received new notification"
else
    test_fail "Citizen 1 did not receive notification"
fi

# Check notification type
if echo "$CITIZEN1_NOTIF" | jq '.notifications[0].type' | grep -q "PUBLIC_NOTICE_PUBLISHED"; then
    test_pass "Notification type is PUBLIC_NOTICE_PUBLISHED"
else
    test_fail "Notification type incorrect"
fi

# Check notification message
if echo "$CITIZEN1_NOTIF" | jq '.notifications[0].message' | grep -q "Water Supply Interruption"; then
    test_pass "Notification message contains notice title"
else
    test_fail "Notification message incorrect"
fi

# Check issue_id is null
if echo "$CITIZEN1_NOTIF" | jq '.notifications[0].issue' | grep -q "null"; then
    test_pass "issue_id is null"
else
    test_fail "issue_id should be null"
fi

# Check is_read is false
if echo "$CITIZEN1_NOTIF" | jq '.notifications[0].is_read' | grep -q "false"; then
    test_pass "is_read is false"
else
    test_fail "is_read should be false"
fi

# Check citizen 2
echo -e "\nChecking Citizen 2 notifications..."
CITIZEN2_NOTIF=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN2_TOKEN")

CITIZEN2_COUNT=$(echo "$CITIZEN2_NOTIF" | jq '.count')

if [ "$CITIZEN2_COUNT" -ge 1 ]; then
    test_pass "Citizen 2 received notification"
else
    test_fail "Citizen 2 did not receive notification"
fi

# Check citizen 3
echo -e "\nChecking Citizen 3 notifications..."
CITIZEN3_NOTIF=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN3_TOKEN")

CITIZEN3_COUNT=$(echo "$CITIZEN3_NOTIF" | jq '.count')

if [ "$CITIZEN3_COUNT" -ge 1 ]; then
    test_pass "Citizen 3 received notification"
else
    test_fail "Citizen 3 did not receive notification"
fi

# =========================================================================
# TEST C: Verify moderators/departments do NOT receive notification
# =========================================================================
echo -e "\n[TEST C] Verify moderators/departments do NOT receive notification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check department user's notifications
DEPT_NOTIF=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $DEPT_TOKEN")

# Count PUBLIC_NOTICE_PUBLISHED notifications for department user
DEPT_NOTICE_COUNT=$(echo "$DEPT_NOTIF" | jq '[.notifications[] | select(.type == "PUBLIC_NOTICE_PUBLISHED")] | length')

if [ "$DEPT_NOTICE_COUNT" -eq 0 ]; then
    test_pass "Department user did NOT receive PUBLIC_NOTICE_PUBLISHED notification"
else
    test_fail "Department user should NOT receive notice notifications (got $DEPT_NOTICE_COUNT)"
fi

# =========================================================================
# TEST D: Duplicate prevention
# =========================================================================
echo -e "\n[TEST D] Duplicate prevention - republish same notice"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get current count
BEFORE_REPUBLISH=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" | jq '.count')

echo "✓ Citizen 1 notification count before republish attempt: $BEFORE_REPUBLISH"

# Try to republish (should fail)
REPUBLISH=$(curl -s -X PATCH "$BASE_URL/notices/$NOTICE_ID/publish" \
    -H "Authorization: Bearer $DEPT_TOKEN")

echo "$REPUBLISH" | jq '.'

if echo "$REPUBLISH" | grep -q "already published"; then
    test_pass "Republish rejected (already published)"
else
    echo "⚠️  Republish not explicitly rejected, checking for duplicate notifications..."
fi

sleep 1

# Check if notification count increased
AFTER_REPUBLISH=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" | jq '.count')

echo "✓ Citizen 1 notification count after republish attempt: $AFTER_REPUBLISH"

if [ "$AFTER_REPUBLISH" -eq "$BEFORE_REPUBLISH" ]; then
    test_pass "No duplicate notifications created"
else
    test_fail "Duplicate notifications created (count increased from $BEFORE_REPUBLISH to $AFTER_REPUBLISH)"
fi

# =========================================================================
# TEST E: Create and publish another notice
# =========================================================================
echo -e "\n[TEST E] Create and publish another notice"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create second notice
CREATE_NOTICE2=$(curl -s -X POST "$BASE_URL/notices" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Road Closure Notice","content":"Main Street will be closed next Monday.","category":"GENERAL"}')

NOTICE_ID2=$(echo "$CREATE_NOTICE2" | jq -r '.notice.id')
echo "✓ Created second draft notice: $NOTICE_ID2"

COUNT_BEFORE_SECOND=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" | jq '.count')

# Publish second notice
curl -s -X PATCH "$BASE_URL/notices/$NOTICE_ID2/publish" \
    -H "Authorization: Bearer $DEPT_TOKEN" > /dev/null

sleep 1

COUNT_AFTER_SECOND=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" | jq '.count')

if [ "$COUNT_AFTER_SECOND" -gt "$COUNT_BEFORE_SECOND" ]; then
    test_pass "Second notice created new notifications"
else
    test_fail "Second notice did not create notifications"
fi

# =========================================================================
# TEST F: Existing notification types still work (Regression)
# =========================================================================
echo -e "\n[TEST F] Regression - Existing notification types"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test civic issue notification
echo -e "\nTesting CIVIC ISSUE notification..."
ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Pothole","description":"Big pothole on Main St","category":"ROADS","location":"123 Main St"}')

if echo "$ISSUE_RESPONSE" | jq '.issue.id' | grep -q "[a-z0-9]"; then
    test_pass "Civic issue creation still works"
else
    test_fail "Civic issue creation broken"
fi

# Test service request notification
echo -e "\nTesting SERVICE REQUEST notification..."
SERVICE_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"service_id":"6a91cee6229f62307b5f0903","department_id":"6a91cdd3229f62307b5f08f9","notes":"Need this service"}')

if echo "$SERVICE_RESPONSE" | jq '.serviceRequest.id' | grep -q "[a-z0-9]"; then
    test_pass "Service request creation still works"
else
    test_fail "Service request creation broken"
fi

# =========================================================================
# TEST G: Existing modules still work
# =========================================================================
echo -e "\n[TEST G] Regression - Existing modules"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Auth
AUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN")
[ "$AUTH_STATUS" = "200" ] && test_pass "Auth module works" || test_fail "Auth module broken"

# Issues
ISSUES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN")
[ "$ISSUES_STATUS" = "200" ] && test_pass "Issues module works" || test_fail "Issues module broken"

# Services
SERVICES_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/services" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN")
[ "$SERVICES_STATUS" = "200" ] && test_pass "Services module works" || test_fail "Services module broken"

# Feedback
FEEDBACK_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/feedback/my" \
    -H "Authorization: Bearer $CITIZEN1_TOKEN")
[ "$FEEDBACK_STATUS" = "200" ] && test_pass "Feedback module works" || test_fail "Feedback module broken"

# Departments
DEPT_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT_TOKEN")
[ "$DEPT_STATUS" = "200" ] && test_pass "Department module works" || test_fail "Department module broken"

# =========================================================================
# SUMMARY
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                           TEST RESULTS                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
if [ $FAILED -eq 0 ]; then
    echo "✅ Failed: $FAILED"
else
    echo "❌ Failed: $FAILED"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
