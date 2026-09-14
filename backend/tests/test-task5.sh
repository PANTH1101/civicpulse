#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 5: MODERATOR ISSUE LISTING & MANAGEMENT TEST                ║"
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

echo -e "\n[SETUP] Creating test users..."

# Create citizen
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Citizen\",\"email\":\"citizen${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"citizen${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create moderator
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Moderator\",\"email\":\"mod${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 'mod${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"mod${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create department
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Dept\",\"email\":\"dept${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

DEPT_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'dept${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: u._id}});
print(u._id.toString());
" | grep -o '[0-9a-f]\{24\}')

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"dept${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ] || [ -z "$CITIZEN_TOKEN" ] || [ "$MOD_TOKEN" = "null" ] || [ -z "$MOD_TOKEN" ]; then
    echo "❌ Setup failed"
    exit 1
fi

echo "✓ Users created successfully"
echo "  Moderator token: ${MOD_TOKEN:0:20}..."
echo "  Department ID: $DEPT_ID"

echo -e "\n[SETUP] Creating test issues..."

# Create several test issues with different states
# Issue 1: REPORTED (pending moderation)
IR1=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Issue 1 - Pending" -F "description=Test" -F "category=ROADS" -F "location=Test")
IID1=$(echo "$IR1" | jq -r '.issue.id')

# Issue 2: REPORTED (pending moderation)
IR2=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Issue 2 - Pending" -F "description=Test" -F "category=WATER" -F "location=Test")
IID2=$(echo "$IR2" | jq -r '.issue.id')

# Issue 3: VERIFIED
IR3=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Issue 3 - Verified" -F "description=Test" -F "category=ELECTRICITY" -F "location=Test")
IID3=$(echo "$IR3" | jq -r '.issue.id')
curl -s -X PATCH "$BASE_URL/issues/$IID3/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

# Issue 4: ASSIGNED
IR4=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Issue 4 - Assigned" -F "description=Test" -F "category=SANITATION" -F "location=Test")
IID4=$(echo "$IR4" | jq -r '.issue.id')
curl -s -X PATCH "$BASE_URL/issues/$IID4/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
curl -s -X PATCH "$BASE_URL/issues/$IID4/assign" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null

# Issue 5: IN_PROGRESS
IR5=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Issue 5 - In Progress" -F "description=Test" -F "category=PUBLIC_SAFETY" -F "location=Test")
IID5=$(echo "$IR5" | jq -r '.issue.id')
curl -s -X PATCH "$BASE_URL/issues/$IID5/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
curl -s -X PATCH "$BASE_URL/issues/$IID5/assign" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null
curl -s -X PATCH "$BASE_URL/issues/$IID5/start" -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json" > /dev/null

# Issue 6: REJECTED
IR6=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Issue 6 - Rejected" -F "description=Test" -F "category=ENVIRONMENT" -F "location=Test")
IID6=$(echo "$IR6" | jq -r '.issue.id')
curl -s -X PATCH "$BASE_URL/issues/$IID6/reject" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d '{"rejection_reason":"Duplicate"}' > /dev/null

echo "✓ Test issues created"

# TEST 1: Moderator can access /api/issues/moderator
echo -e "\n[TEST 1] GET /api/issues/moderator (moderator access)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $MOD_TOKEN")
MSG=$(echo "$RESP" | jq -r '.message')
COUNT=$(echo "$RESP" | jq -r '.count')

if [ "$MSG" = "Moderator issues retrieved successfully" ]; then
    test_pass "Moderator can access issue listing"
else
    test_fail "Moderator access failed"
fi

if [ "$COUNT" -ge 6 ]; then
    test_pass "Returns multiple issues (count: $COUNT)"
else
    test_fail "Issue count incorrect: $COUNT"
fi

# TEST 2: Moderator can access /api/issues/moderator/pending
echo -e "\n[TEST 2] GET /api/issues/moderator/pending"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN")
MSG=$(echo "$RESP" | jq -r '.message')
COUNT=$(echo "$RESP" | jq -r '.count')

if [ "$MSG" = "Pending moderation issues retrieved successfully" ]; then
    test_pass "Pending moderation endpoint accessible"
else
    test_fail "Pending moderation access failed"
fi

if [ "$COUNT" -eq 2 ]; then
    test_pass "Pending queue shows correct count (2 unverified REPORTED issues)"
else
    test_fail "Pending queue count incorrect: $COUNT (expected 2)"
fi

# TEST 3: Verify an issue and check it disappears from pending
echo -e "\n[TEST 3] Verify issue removes it from pending queue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Before verification - should have 2
RESP=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN")
BEFORE=$(echo "$RESP" | jq -r '.count')

# Verify one of the pending issues
curl -s -X PATCH "$BASE_URL/issues/$IID1/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

# After verification - should have 1
RESP=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN")
AFTER=$(echo "$RESP" | jq -r '.count')

if [ "$AFTER" -lt "$BEFORE" ]; then
    test_pass "Verified issue removed from pending queue (before: $BEFORE, after: $AFTER)"
else
    test_fail "Verified issue still in pending queue"
fi

# TEST 4: Rejected issue not in pending queue
echo -e "\n[TEST 4] Rejected issue not in pending queue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
HAS_REJECTED=$(echo "$ISSUES" | jq "any(.status == \"REJECTED\")")

if [ "$HAS_REJECTED" = "false" ]; then
    test_pass "Rejected issues not in pending queue"
else
    test_fail "Rejected issue found in pending queue"
fi

# TEST 5: Filter by status
echo -e "\n[TEST 5] Filter by status=REPORTED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?status=REPORTED" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_REPORTED=$(echo "$ISSUES" | jq 'all(.status == "REPORTED")')

if [ "$ALL_REPORTED" = "true" ]; then
    test_pass "Status filter works (all REPORTED)"
else
    test_fail "Status filter failed"
fi

# TEST 6: Filter by category
echo -e "\n[TEST 6] Filter by category=WATER"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?category=WATER" -H "Authorization: Bearer $MOD_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_WATER=$(echo "$ISSUES" | jq 'all(.category == "WATER")')

if [ "$ALL_WATER" = "true" ]; then
    test_pass "Category filter works (all WATER)"
else
    test_fail "Category filter failed"
fi

# TEST 7: Pagination page 1
echo -e "\n[TEST 7] Pagination - page 1, limit 2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?page=1&limit=2" -H "Authorization: Bearer $MOD_TOKEN")
PAGE=$(echo "$RESP" | jq -r '.page')
LIMIT=$(echo "$RESP" | jq -r '.limit')
COUNT=$(echo "$RESP" | jq -r '.count')

if [ "$PAGE" -eq 1 ] && [ "$LIMIT" -eq 2 ] && [ "$COUNT" -le 2 ]; then
    test_pass "Pagination page 1 works (count: $COUNT)"
else
    test_fail "Pagination failed (page: $PAGE, limit: $LIMIT, count: $COUNT)"
fi

# TEST 8: Pagination page 2
echo -e "\n[TEST 8] Pagination - page 2, limit 2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?page=2&limit=2" -H "Authorization: Bearer $MOD_TOKEN")
PAGE=$(echo "$RESP" | jq -r '.page')

if [ "$PAGE" -eq 2 ]; then
    test_pass "Pagination page 2 works"
else
    test_fail "Pagination page 2 failed"
fi

# TEST 9: Limit > 50 capped at 50
echo -e "\n[TEST 9] Limit >50 capped at maximum"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?limit=100" -H "Authorization: Bearer $MOD_TOKEN")
LIMIT=$(echo "$RESP" | jq -r '.limit')

if [ "$LIMIT" -eq 50 ]; then
    test_pass "Limit capped at 50"
else
    test_fail "Limit not capped (got: $LIMIT)"
fi

# TEST 10: Invalid status → 400
echo -e "\n[TEST 10] Invalid status rejected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator?status=INVALID" -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid status rejected (400)"
else
    test_fail "Invalid status not rejected (got: $HTTP_CODE)"
fi

# TEST 11: Invalid category → 400
echo -e "\n[TEST 11] Invalid category rejected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator?category=INVALID" -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid category rejected (400)"
else
    test_fail "Invalid category not rejected (got: $HTTP_CODE)"
fi

# TEST 12: Citizen → 403
echo -e "\n[TEST 12] Citizen access denied (403)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $CITIZEN_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Citizen denied access (403)"
else
    test_fail "Citizen not denied (got: $HTTP_CODE)"
fi

# TEST 13: Department → 403
echo -e "\n[TEST 13] Department access denied (403)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" -H "Authorization: Bearer $DEPT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Department denied access (403)"
else
    test_fail "Department not denied (got: $HTTP_CODE)"
fi

# TEST 14: No token → 401
echo -e "\n[TEST 14] Unauthenticated access denied (401)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "401" ]; then
    test_pass "Unauthenticated denied (401)"
else
    test_fail "Unauthenticated not denied (got: $HTTP_CODE)"
fi

# TEST 15: Assigned issues appear in moderator listing
echo -e "\n[TEST 15] Assigned issues appear in moderator listing"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESP=$(curl -s -X GET "$BASE_URL/issues/moderator?status=ASSIGNED" -H "Authorization: Bearer $MOD_TOKEN")
COUNT=$(echo "$RESP" | jq -r '.count')

if [ "$COUNT" -ge 1 ]; then
    test_pass "Assigned issues visible in moderator listing"
else
    test_fail "Assigned issues not found"
fi

# RESULTS
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     TASK 5 TEST RESULTS                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
[ $FAILED -eq 0 ] && echo "✅ Failed: $FAILED" || echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
