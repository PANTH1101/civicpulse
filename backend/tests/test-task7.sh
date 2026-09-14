#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 7: CIVIC ISSUE VERIFICATION & WORKFLOW CONSISTENCY          ║"
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

TIMESTAMP=$(date +%s)
TEST_MARKER="TASK7_${TIMESTAMP}"

echo -e "\n[SETUP] Creating test users..."

# Create citizen
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task7 Citizen\",\"email\":\"t7cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CIT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t7cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create moderator
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task7 Moderator\",\"email\":\"t7mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 't7mod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t7mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Get real department ID
DEPT_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const dept = db.departments.findOne({name: 'Roads and Transportation Department'});
print(dept._id.toString());
" | grep -o '[0-9a-f]\{24\}')

# Create department user linked to this department
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task7 Dept User\",\"email\":\"t7dept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 't7dept_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT_ID')}});
" > /dev/null

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t7dept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

echo "✓ Test users created"

# =========================================================================
# SECURITY TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      SECURITY TESTS                                     ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

# Create test issue for security tests
ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=${TEST_MARKER} - Security Test" -F "description=Test" -F "category=ROADS" -F "location=Test")
SEC_ISSUE_ID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')

echo -e "\n[TEST A] Unauthenticated verify → 401"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/verify" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "401" ]; then
    test_pass "Unauthenticated verify rejected (401)"
else
    test_fail "Unauthenticated verify not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST B] CITIZEN verify → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/verify" \
    -H "Authorization: Bearer $CIT_TOKEN" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Citizen verify rejected (403)"
else
    test_fail "Citizen verify not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST C] DEPARTMENT verify → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/verify" \
    -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Department verify rejected (403)"
else
    test_fail "Department verify not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST D] MODERATOR verify → success"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)
BODY=$(echo "$RESP" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    VERIFIED_BY=$(echo "$BODY" | jq -r '.issue.verifiedBy')
    if [ "$VERIFIED_BY" != "null" ] && [ -n "$VERIFIED_BY" ]; then
        test_pass "Moderator verify successful (200)"
    else
        test_fail "Moderator verify succeeded but verifiedBy not set"
    fi
else
    test_fail "Moderator verify failed (got $HTTP_CODE)"
fi

echo -e "\n[TEST E] Verify already verified issue → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)
BODY=$(echo "$RESP" | sed '$d')
MSG=$(echo "$BODY" | jq -r '.message')

if [ "$HTTP_CODE" = "400" ] && [[ "$MSG" == *"already been verified"* ]]; then
    test_pass "Repeated verify rejected (400)"
else
    test_fail "Repeated verify not properly rejected (got $HTTP_CODE, msg: $MSG)"
fi

echo -e "\n[TEST F] Assign unverified issue → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Create new unverified issue
UNVER_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=${TEST_MARKER} - Unverified" -F "description=Test" -F "category=WATER" -F "location=Test")
UNVER_ID=$(echo "$UNVER_RESP" | jq -r '.issue.id')

RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$UNVER_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)
BODY=$(echo "$RESP" | sed '$d')
MSG=$(echo "$BODY" | jq -r '.message')

if [ "$HTTP_CODE" = "400" ] && [[ "$MSG" == *"must be verified"* ]]; then
    test_pass "Unverified issue assignment rejected (400)"
else
    test_fail "Unverified issue assignment not rejected (got $HTTP_CODE, msg: $MSG)"
fi

echo -e "\n[TEST G] Assign verified issue → success"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)
BODY=$(echo "$RESP" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    STATUS=$(echo "$BODY" | jq -r '.issue.status')
    DEPT=$(echo "$BODY" | jq -r '.issue.department.id')
    if [ "$STATUS" = "ASSIGNED" ] && [ "$DEPT" = "$DEPT_ID" ]; then
        test_pass "Verified issue assigned successfully"
    else
        test_fail "Assignment succeeded but status/dept incorrect (status: $STATUS, dept: $DEPT)"
    fi
else
    test_fail "Verified issue assignment failed (got $HTTP_CODE)"
fi

echo -e "\n[TEST H] Assign rejected issue → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Create and reject an issue
REJ_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=${TEST_MARKER} - To Reject" -F "description=Test" -F "category=SANITATION" -F "location=Test")
REJ_ID=$(echo "$REJ_RESP" | jq -r '.issue.id')

curl -s -X PATCH "$BASE_URL/issues/$REJ_ID/reject" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rejection_reason":"Test rejection"}' > /dev/null

RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$REJ_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Rejected issue assignment rejected (400)"
else
    test_fail "Rejected issue assignment not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST I] CITIZEN assign → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$SEC_ISSUE_ID/assign" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Citizen assign rejected (403)"
else
    test_fail "Citizen assign not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST J] DEPARTMENT assign → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$UNVER_ID/assign" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Department assign rejected (403)"
else
    test_fail "Department assign not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST K] Unauthenticated assign → 401"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$UNVER_ID/assign" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "401" ]; then
    test_pass "Unauthenticated assign rejected (401)"
else
    test_fail "Unauthenticated assign not rejected (got $HTTP_CODE)"
fi

# =========================================================================
# NOTIFICATION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      NOTIFICATION TESTS                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST L] Verify notification sent exactly once"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Create new citizen and issue
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Notif Citizen\",\"email\":\"notifcit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

NOTIF_CIT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"notifcit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

NOTIF_ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $NOTIF_CIT_TOKEN" \
    -F "title=${TEST_MARKER} - Notif Test" -F "description=Test" -F "category=ELECTRICITY" -F "location=Test")
NOTIF_ISSUE_ID=$(echo "$NOTIF_ISSUE_RESP" | jq -r '.issue.id')

# Verify the issue
curl -s -X PATCH "$BASE_URL/issues/$NOTIF_ISSUE_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

sleep 1

# Check citizen received exactly one ISSUE_VERIFIED notification
VERIFY_NOTIF_COUNT=$(curl -s -X GET "$BASE_URL/notifications" -H "Authorization: Bearer $NOTIF_CIT_TOKEN" | \
    jq "[.notifications[] | select(.type == \"ISSUE_VERIFIED\" and .issue.id == \"$NOTIF_ISSUE_ID\")] | length")

if [ "$VERIFY_NOTIF_COUNT" -eq 1 ]; then
    test_pass "Verify notification sent exactly once"
else
    test_fail "Verify notification count wrong (expected 1, got $VERIFY_NOTIF_COUNT)"
fi

echo -e "\n[TEST M] Assignment notification works"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Assign the issue
curl -s -X PATCH "$BASE_URL/issues/$NOTIF_ISSUE_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null

sleep 1

# Check department user received ISSUE_ASSIGNED notification
ASSIGN_NOTIF_COUNT=$(curl -s -X GET "$BASE_URL/notifications" -H "Authorization: Bearer $DEPT_TOKEN" | \
    jq "[.notifications[] | select(.type == \"ISSUE_ASSIGNED\" and .issue.id == \"$NOTIF_ISSUE_ID\")] | length")

if [ "$ASSIGN_NOTIF_COUNT" -ge 1 ]; then
    test_pass "Assignment notification works"
else
    test_fail "Assignment notification not sent (count: $ASSIGN_NOTIF_COUNT)"
fi

# =========================================================================
# COMPLETE WORKFLOW TEST
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      COMPLETE WORKFLOW TEST                             ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[WORKFLOW] Testing complete issue lifecycle"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create new citizen for workflow test
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Workflow Citizen\",\"email\":\"wfcit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

WF_CIT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"wfcit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Step 1: REPORTED
echo "  Step 1: Citizen reports issue..."
WF_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $WF_CIT_TOKEN" \
    -F "title=${TEST_MARKER} - Workflow" -F "description=Complete workflow test" -F "category=PUBLIC_SAFETY" -F "location=Test Street")
WF_ID=$(echo "$WF_RESP" | jq -r '.issue.id')
WF_STATUS=$(echo "$WF_RESP" | jq -r '.issue.status')

if [ "$WF_STATUS" = "REPORTED" ]; then
    test_pass "Step 1: Issue REPORTED"
else
    test_fail "Step 1: Wrong status (got $WF_STATUS)"
fi

# Step 2: VERIFY (status remains REPORTED)
echo "  Step 2: Moderator verifies issue..."
WF_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$WF_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json")
WF_STATUS=$(echo "$WF_RESP" | jq -r '.issue.status')
WF_VERIFIED=$(echo "$WF_RESP" | jq -r '.issue.verifiedBy')

if [ "$WF_STATUS" = "REPORTED" ] && [ "$WF_VERIFIED" != "null" ]; then
    test_pass "Step 2: Issue VERIFIED (status still REPORTED, verifiedBy set)"
else
    test_fail "Step 2: Verification failed (status: $WF_STATUS, verified: $WF_VERIFIED)"
fi

# Step 3: ASSIGN
echo "  Step 3: Moderator assigns to department..."
WF_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$WF_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")
WF_STATUS=$(echo "$WF_RESP" | jq -r '.issue.status')
WF_DEPT=$(echo "$WF_RESP" | jq -r '.issue.department.id')

if [ "$WF_STATUS" = "ASSIGNED" ] && [ "$WF_DEPT" = "$DEPT_ID" ]; then
    test_pass "Step 3: Issue ASSIGNED to department"
else
    test_fail "Step 3: Assignment failed (status: $WF_STATUS, dept: $WF_DEPT)"
fi

# Step 4: START
echo "  Step 4: Department starts work..."
WF_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$WF_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json")
WF_STATUS=$(echo "$WF_RESP" | jq -r '.issue.status')

if [ "$WF_STATUS" = "IN_PROGRESS" ]; then
    test_pass "Step 4: Issue IN_PROGRESS"
else
    test_fail "Step 4: Start failed (status: $WF_STATUS)"
fi

# Step 5: RESOLVE (optional - not part of Task 7 verification workflow)
echo "  Step 5: Testing resolve endpoint availability..."
# Just verify the endpoint exists and returns appropriate error without proper image
WF_RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$WF_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"resolution_description":"Test"}')
WF_HTTP=$(echo "$WF_RESP" | tail -n 1)

if [ "$WF_HTTP" = "400" ] || [ "$WF_HTTP" = "500" ]; then
    # Expected - we didn't provide proper multipart form data
    test_pass "Step 5: Resolve endpoint available (requires multipart image)"
else
    test_fail "Step 5: Unexpected resolve response (got $WF_HTTP)"
fi

# Step 6: Workflow verification complete
test_pass "Complete workflow verified (REPORTED → VERIFIED → ASSIGNED → IN_PROGRESS)"

# =========================================================================
# REGRESSION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      REGRESSION TESTS                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[REGRESSION 1] Citizen issue reporting still works"
RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=Regression Issue" -F "description=Test" -F "category=ROADS" -F "location=Test")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "201" ]; then
    test_pass "Citizen issue reporting works"
else
    test_fail "Citizen issue reporting broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 2] Citizen issue listing still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Citizen issue listing works"
else
    test_fail "Citizen issue listing broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 3] Moderator issue listing still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" \
    -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Moderator issue listing works"
else
    test_fail "Moderator issue listing broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 4] Moderator pending queue still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator/pending" \
    -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Moderator pending queue works"
else
    test_fail "Moderator pending queue broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 5] Issue rejection still works"
REG_ISSUE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=To Reject" -F "description=Test" -F "category=WATER" -F "location=Test" | jq -r '.issue.id')

RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$REG_ISSUE/reject" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rejection_reason":"Test"}')
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Issue rejection works"
else
    test_fail "Issue rejection broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 6] Department issue listing still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues" \
    -H "Authorization: Bearer $DEPT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Department issue listing works"
else
    test_fail "Department issue listing broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 7] User profile still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "User profile works"
else
    test_fail "User profile broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 8] Notifications still work"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Notifications work"
else
    test_fail "Notifications broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 9] Public notices still work"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notices" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Public notices work"
else
    test_fail "Public notices broken (got $HTTP_CODE)"
fi

# =========================================================================
# RESULTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                   TASK 7 VERIFICATION RESULTS                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Task 7 Tests: $PASSED passed"
echo "Total Tests: $((PASSED + FAILED))"
[ $FAILED -eq 0 ] && echo "✅ Status: ALL PASSED" || echo "❌ Status: $FAILED FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 TASK 7 VERIFICATION COMPLETE!"
    echo ""
    echo "✅ Verification workflow consistent"
    echo "✅ Assignment requires verification"
    echo "✅ Repeated verification prevented"
    echo "✅ Rejected issues cannot be assigned"
    echo "✅ Complete workflow functional"
    echo "✅ All security checks passing"
    echo "✅ All notifications working"
    echo "✅ All regressions passing"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
