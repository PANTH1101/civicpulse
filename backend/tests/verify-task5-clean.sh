#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 5: MODERATOR LISTING - CLEAN VERIFICATION                   ║"
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
TEST_MARKER="TASK5VERIFY${TIMESTAMP}"

echo -e "\n[SETUP] Creating fresh isolated test users..."

# Create citizen
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Clean Citizen\",\"email\":\"clean_cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"clean_cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create moderator
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Clean Moderator\",\"email\":\"clean_mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 'clean_mod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"clean_mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Get a real department ID from the database
DEPT_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const dept = db.departments.findOne({name: 'Roads and Transportation Department'});
print(dept._id.toString());
" | grep -o '[0-9a-f]\{24\}')

# Create a department user linked to this department
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Clean Dept User\",\"email\":\"clean_dept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'clean_dept_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT_ID')}});
" > /dev/null

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"clean_dept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ] || [ -z "$CITIZEN_TOKEN" ] || [ "$MOD_TOKEN" = "null" ] || [ -z "$MOD_TOKEN" ]; then
    echo "❌ Setup failed"
    exit 1
fi

echo "✓ Users created successfully"

echo -e "\n[SETUP] Creating fresh isolated test issues..."

# Issue 1: Unverified REPORTED (will stay pending)
IR1=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=${TEST_MARKER} - Unverified 1" -F "description=Pending test" -F "category=ROADS" -F "location=Test")
IID1=$(echo "$IR1" | jq -r '.issue.id')

# Issue 2: Unverified REPORTED (will stay pending)
IR2=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=${TEST_MARKER} - Unverified 2" -F "description=Pending test" -F "category=WATER" -F "location=Test")
IID2=$(echo "$IR2" | jq -r '.issue.id')

# Issue 3: Will be verified (should leave pending queue)
IR3=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=${TEST_MARKER} - To Verify" -F "description=Will verify" -F "category=ELECTRICITY" -F "location=Test")
IID3=$(echo "$IR3" | jq -r '.issue.id')

# Issue 4: Will be rejected (should leave pending queue)
IR4=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=${TEST_MARKER} - To Reject" -F "description=Will reject" -F "category=SANITATION" -F "location=Test")
IID4=$(echo "$IR4" | jq -r '.issue.id')

# Issue 5: Will be assigned (for filter tests)
IR5=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=${TEST_MARKER} - To Assign" -F "description=Will assign" -F "category=PUBLIC_SAFETY" -F "location=Test")
IID5=$(echo "$IR5" | jq -r '.issue.id')

echo "✓ Created 5 fresh test issues with marker: $TEST_MARKER"
echo "  IID1 (pending): $IID1"
echo "  IID2 (pending): $IID2"
echo "  IID3 (to verify): $IID3"
echo "  IID4 (to reject): $IID4"
echo "  IID5 (to assign): $IID5"

# =========================================================================
# TEST 1: Pending queue contains unverified REPORTED issues
# =========================================================================
echo -e "\n[TEST 1] Pending queue shows unverified REPORTED issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')

HAS_IID1=$(echo "$ISSUES" | jq "any(.id == \"$IID1\")")
HAS_IID2=$(echo "$ISSUES" | jq "any(.id == \"$IID2\")")

if [ "$HAS_IID1" = "true" ] && [ "$HAS_IID2" = "true" ]; then
    test_pass "Unverified issues appear in pending queue"
else
    test_fail "Unverified issues missing from pending queue"
    echo "  IID1 present: $HAS_IID1, IID2 present: $HAS_IID2"
fi

# =========================================================================
# TEST 2: Verify an issue - it should leave pending queue
# =========================================================================
echo -e "\n[TEST 2] Verifying issue removes it from pending queue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check IID3 is in pending before verify
BEFORE=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN" | jq -r ".issues[] | select(.id == \"$IID3\") | .id")

# Verify IID3
curl -s -X PATCH "$BASE_URL/issues/$IID3/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

# Check IID3 is NOT in pending after verify
AFTER=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN" | jq -r ".issues[] | select(.id == \"$IID3\") | .id")

if [ -n "$BEFORE" ] && [ -z "$AFTER" ]; then
    test_pass "Verified issue removed from pending queue"
else
    test_fail "Verified issue still in pending queue (before: ${BEFORE:-empty}, after: ${AFTER:-empty})"
fi

# =========================================================================
# TEST 3: Reject an issue - it should leave pending queue
# =========================================================================
echo -e "\n[TEST 3] Rejecting issue removes it from pending queue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Reject IID4
curl -s -X PATCH "$BASE_URL/issues/$IID4/reject" -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" -d '{"rejection_reason":"Test rejection"}' > /dev/null

# Check IID4 is NOT in pending after reject
REJECTED_IN_PENDING=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN" | jq -r ".issues[] | select(.id == \"$IID4\") | .id")

if [ -z "$REJECTED_IN_PENDING" ]; then
    test_pass "Rejected issue not in pending queue"
else
    test_fail "Rejected issue still in pending queue"
fi

# =========================================================================
# TEST 4: Assign an issue - it should leave pending queue
# =========================================================================
echo -e "\n[TEST 4] Assigning issue removes it from pending queue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Verify IID5 first
curl -s -X PATCH "$BASE_URL/issues/$IID5/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

# Assign IID5
curl -s -X PATCH "$BASE_URL/issues/$IID5/assign" -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null

# Check IID5 is NOT in pending after assign
ASSIGNED_IN_PENDING=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN" | jq -r ".issues[] | select(.id == \"$IID5\") | .id")

if [ -z "$ASSIGNED_IN_PENDING" ]; then
    test_pass "Assigned issue not in pending queue"
else
    test_fail "Assigned issue still in pending queue"
fi

# =========================================================================
# TEST 5: Moderator can access full issue list
# =========================================================================
echo -e "\n[TEST 5] Moderator can access full issue list"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)
BODY=$(echo "$RESP" | sed '$d')

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Moderator can access issue list (200)"
else
    test_fail "Moderator access failed (got $HTTP_CODE)"
fi

MSG=$(echo "$BODY" | jq -r '.message')
if [ "$MSG" = "Moderator issues retrieved successfully" ]; then
    test_pass "Correct response message"
else
    test_fail "Wrong message: $MSG"
fi

# =========================================================================
# TEST 6: Test records appear in moderator list with correct data
# =========================================================================
echo -e "\n[TEST 6] Test records appear with populated fields"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')

# Check if our verified issue has verifiedBy populated
VERIFIED_ISSUE=$(echo "$ISSUES" | jq ".[] | select(.id == \"$IID3\")")
HAS_VERIFIED_BY=$(echo "$VERIFIED_ISSUE" | jq '.verifiedBy != null')

if [ "$HAS_VERIFIED_BY" = "true" ]; then
    test_pass "Verified issue has verifiedBy populated"
else
    test_fail "Verified issue missing verifiedBy"
fi

# Check if assigned issue has department populated
ASSIGNED_ISSUE=$(echo "$ISSUES" | jq ".[] | select(.id == \"$IID5\")")
HAS_DEPT=$(echo "$ASSIGNED_ISSUE" | jq '.department != null')

if [ "$HAS_DEPT" = "true" ]; then
    test_pass "Assigned issue has department populated"
else
    test_fail "Assigned issue missing department"
fi

# =========================================================================
# TEST 7: Status filter works
# =========================================================================
echo -e "\n[TEST 7] Status filter - filter by REPORTED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?status=REPORTED" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_REPORTED=$(echo "$ISSUES" | jq 'all(.status == "REPORTED")')

if [ "$ALL_REPORTED" = "true" ]; then
    test_pass "Status filter returns only REPORTED issues"
else
    test_fail "Status filter failed"
fi

# =========================================================================
# TEST 8: Status filter - ASSIGNED
# =========================================================================
echo -e "\n[TEST 8] Status filter - filter by ASSIGNED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?status=ASSIGNED" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')

# Check if our IID5 (which we assigned) appears
HAS_IID5=$(echo "$ISSUES" | jq "any(.id == \"$IID5\")")

if [ "$HAS_IID5" = "true" ]; then
    test_pass "ASSIGNED filter returns assigned issue"
else
    test_fail "ASSIGNED filter did not return our assigned issue"
fi

# =========================================================================
# TEST 9: Category filter works
# =========================================================================
echo -e "\n[TEST 9] Category filter - filter by ELECTRICITY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?category=ELECTRICITY" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')

# Check if our IID3 (ELECTRICITY) appears
HAS_IID3=$(echo "$ISSUES" | jq "any(.id == \"$IID3\")")

if [ "$HAS_IID3" = "true" ]; then
    test_pass "Category filter returns correct category"
else
    test_fail "Category filter failed"
fi

# =========================================================================
# TEST 10: Invalid category rejected
# =========================================================================
echo -e "\n[TEST 10] Invalid category rejected (400)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator?category=INVALID" -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid category rejected (400)"
else
    test_fail "Invalid category not rejected (got $HTTP_CODE)"
fi

# =========================================================================
# TEST 11: Pagination works
# =========================================================================
echo -e "\n[TEST 11] Pagination - page 1, limit 2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?page=1&limit=2" -H "Authorization: Bearer $MOD_TOKEN")
PAGE=$(echo "$RESP" | jq -r '.page')
LIMIT=$(echo "$RESP" | jq -r '.limit')
COUNT=$(echo "$RESP" | jq -r '.count')

if [ "$PAGE" -eq 1 ] && [ "$LIMIT" -eq 2 ] && [ "$COUNT" -le 2 ]; then
    test_pass "Pagination works (page: $PAGE, limit: $LIMIT, count: $COUNT)"
else
    test_fail "Pagination failed"
fi

# =========================================================================
# TEST 12: Limit capped at 50
# =========================================================================
echo -e "\n[TEST 12] Limit >50 capped at maximum"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?limit=100" -H "Authorization: Bearer $MOD_TOKEN")
LIMIT=$(echo "$RESP" | jq -r '.limit')

if [ "$LIMIT" -eq 50 ]; then
    test_pass "Limit capped at 50"
else
    test_fail "Limit not capped (got: $LIMIT)"
fi

# =========================================================================
# TEST 13: Security - No token (401)
# =========================================================================
echo -e "\n[TEST 13] Security - No token rejected (401)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "401" ]; then
    test_pass "No token rejected (401)"
else
    test_fail "No token not rejected (got $HTTP_CODE)"
fi

# =========================================================================
# TEST 14: Security - Citizen (403)
# =========================================================================
echo -e "\n[TEST 14] Security - Citizen access denied (403)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $CITIZEN_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Citizen denied (403)"
else
    test_fail "Citizen not denied (got $HTTP_CODE)"
fi

# =========================================================================
# TEST 15: Security - Department (403)
# =========================================================================
echo -e "\n[TEST 15] Security - Department access denied (403)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $DEPT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Department denied (403)"
else
    test_fail "Department not denied (got $HTTP_CODE)"
fi

# =========================================================================
# REGRESSION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      REGRESSION TESTS                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[REGRESSION 1] POST /api/issues still works"
RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Regression Test" -F "description=Test" -F "category=ROADS" -F "location=Test")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "201" ]; then
    test_pass "POST /api/issues works"
else
    test_fail "POST /api/issues broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 2] PATCH /api/issues/:id/verify still works"
NEW_ISSUE=$(echo "$RESP" | sed '$d' | jq -r '.issue.id')
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$NEW_ISSUE/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "PATCH /api/issues/:id/verify works"
else
    test_fail "PATCH /api/issues/:id/verify broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 3] GET /api/issues/my-issues still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /api/issues/my-issues works"
else
    test_fail "GET /api/issues/my-issues broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 4] GET /api/auth/profile still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /api/auth/profile works"
else
    test_fail "GET /api/auth/profile broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 5] GET /api/notifications still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /api/notifications works"
else
    test_fail "GET /api/notifications broken (got $HTTP_CODE)"
fi

# =========================================================================
# RESULTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                   TASK 5 CLEAN VERIFICATION RESULTS                     ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Task 5 Tests: $PASSED passed"
echo "Total Tests: $((PASSED + FAILED))"
[ $FAILED -eq 0 ] && echo "✅ Status: ALL PASSED" || echo "❌ Status: $FAILED FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 TASK 5 VERIFICATION COMPLETE!"
    echo ""
    echo "✅ Moderator endpoints functional"
    echo "✅ Pending queue logic correct"
    echo "✅ Filtering works (status, category)"
    echo "✅ Pagination works"
    echo "✅ Security enforced (401, 403)"
    echo "✅ All regressions passing"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
