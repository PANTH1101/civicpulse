#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 8: DEPARTMENT ISSUE FILTERING & PAGINATION                  ║"
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
TEST_MARKER="TASK8_${TIMESTAMP}"

echo -e "\n[SETUP] Creating test users and departments..."

# Get two different departments
DEPT1_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const dept = db.departments.findOne({name: 'Roads and Transportation Department'});
print(dept._id.toString());
" | grep -o '[0-9a-f]\{24\}')

DEPT2_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const dept = db.departments.findOne({name: 'Water Supply Department'});
print(dept._id.toString());
" | grep -o '[0-9a-f]\{24\}')

# Create department user 1 (Roads)
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Roads Dept User\",\"email\":\"rdept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'rdept_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT1_ID')}});
" > /dev/null

DEPT1_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"rdept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create department user 2 (Water)
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Water Dept User\",\"email\":\"wdept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'wdept_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT2_ID')}});
" > /dev/null

DEPT2_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"wdept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create citizen
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task8 Citizen\",\"email\":\"t8cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CIT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t8cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create moderator
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task8 Moderator\",\"email\":\"t8mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 't8mod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t8mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

echo "✓ Test users created"

echo -e "\n[SETUP] Creating test issues for departments..."

# Create test issues for Dept 1 (Roads)
# 3 ASSIGNED, 2 IN_PROGRESS, 2 RESOLVED
for i in 1 2 3; do
    ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -F "title=${TEST_MARKER} - Roads ASSIGNED $i" -F "description=Test" -F "category=ROADS" -F "location=Test")
    IID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/verify" \
        -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/assign" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"department_id\":\"$DEPT1_ID\"}" > /dev/null
    
    sleep 0.1  # Ensure different timestamps
done

# Create IN_PROGRESS issues for Dept 1
for i in 1 2; do
    ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -F "title=${TEST_MARKER} - Roads IN_PROGRESS $i" -F "description=Test" -F "category=ELECTRICITY" -F "location=Test")
    IID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/verify" \
        -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/assign" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"department_id\":\"$DEPT1_ID\"}" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/start" \
        -H "Authorization: Bearer $DEPT1_TOKEN" -H "Content-Type: application/json" > /dev/null
    
    sleep 0.1
done

# Create test issues for Dept 2 (Water) - different category
for i in 1 2; do
    ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -F "title=${TEST_MARKER} - Water ASSIGNED $i" -F "description=Test" -F "category=WATER" -F "location=Test")
    IID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/verify" \
        -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/assign" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"department_id\":\"$DEPT2_ID\"}" > /dev/null
    
    sleep 0.1
done

echo "✓ Test issues created"

# =========================================================================
# SECURITY TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      SECURITY TESTS                                     ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 1] DEPARTMENT user can access endpoint → 200"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Department user access allowed (200)"
else
    test_fail "Department user access failed (got $HTTP_CODE)"
fi

echo -e "\n[TEST 2] CITIZEN → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Citizen access denied (403)"
else
    test_fail "Citizen access not denied (got $HTTP_CODE)"
fi

echo -e "\n[TEST 3] MODERATOR → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues" \
    -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Moderator access denied (403)"
else
    test_fail "Moderator access not denied (got $HTTP_CODE)"
fi

echo -e "\n[TEST 4] No token → 401"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "401" ]; then
    test_pass "Unauthenticated access denied (401)"
else
    test_fail "Unauthenticated access not denied (got $HTTP_CODE)"
fi

echo -e "\n[TEST 5] Roads user only sees Roads department issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues" -H "Authorization: Bearer $DEPT1_TOKEN")
DEPT1_COUNT=$(echo "$RESP" | jq '[.issues[] | select(.title | contains("'"$TEST_MARKER"'") and contains("Roads"))] | length')

if [ "$DEPT1_COUNT" -ge 5 ]; then
    test_pass "Roads user sees Roads issues (count: $DEPT1_COUNT)"
else
    test_fail "Roads user issue count wrong (got $DEPT1_COUNT, expected >=5)"
fi

echo -e "\n[TEST 6] Water user only sees Water department issues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues" -H "Authorization: Bearer $DEPT2_TOKEN")
DEPT2_COUNT=$(echo "$RESP" | jq '[.issues[] | select(.title | contains("'"$TEST_MARKER"'") and contains("Water"))] | length')

if [ "$DEPT2_COUNT" -ge 2 ]; then
    test_pass "Water user sees Water issues (count: $DEPT2_COUNT)"
else
    test_fail "Water user issue count wrong (got $DEPT2_COUNT, expected >=2)"
fi

echo -e "\n[TEST 7] Client-provided department_id cannot bypass isolation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
# Roads user tries to access Water department issues
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?department_id=$DEPT2_ID" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
HAS_WATER=$(echo "$ISSUES" | jq 'any(.title | contains("Water"))')

if [ "$HAS_WATER" = "false" ]; then
    test_pass "Department isolation enforced (client param ignored)"
else
    test_fail "Department isolation BYPASSED - SECURITY ISSUE"
fi

# =========================================================================
# FILTER TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      FILTER TESTS                                       ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 8] status=ASSIGNED filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?status=ASSIGNED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_ASSIGNED=$(echo "$ISSUES" | jq 'all(.status == "ASSIGNED")')

if [ "$ALL_ASSIGNED" = "true" ]; then
    test_pass "Status filter ASSIGNED works"
else
    test_fail "Status filter ASSIGNED failed"
fi

echo -e "\n[TEST 9] status=IN_PROGRESS filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?status=IN_PROGRESS" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_IN_PROGRESS=$(echo "$ISSUES" | jq 'all(.status == "IN_PROGRESS")')

if [ "$ALL_IN_PROGRESS" = "true" ]; then
    test_pass "Status filter IN_PROGRESS works"
else
    test_fail "Status filter IN_PROGRESS failed"
fi

echo -e "\n[TEST 10] status=RESOLVED filter (empty result OK)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?status=RESOLVED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Status filter RESOLVED accepted (200)"
else
    test_fail "Status filter RESOLVED rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 11] status=REJECTED filter (empty result OK)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?status=REJECTED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Status filter REJECTED accepted (200)"
else
    test_fail "Status filter REJECTED rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 12] category=ELECTRICITY filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?category=ELECTRICITY" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_ELECTRICITY=$(echo "$ISSUES" | jq 'all(.category == "ELECTRICITY")')

if [ "$ALL_ELECTRICITY" = "true" ]; then
    test_pass "Category filter ELECTRICITY works"
else
    test_fail "Category filter ELECTRICITY failed"
fi

echo -e "\n[TEST 13] category=WATER filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?category=WATER" \
    -H "Authorization: Bearer $DEPT2_TOKEN")
ISSUES=$(echo "$RESP" | jq '.issues')
ALL_WATER=$(echo "$ISSUES" | jq 'all(.category == "WATER")')

if [ "$ALL_WATER" = "true" ]; then
    test_pass "Category filter WATER works"
else
    test_fail "Category filter WATER failed"
fi

echo -e "\n[TEST 14] Invalid status → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?status=INVALID" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid status rejected (400)"
else
    test_fail "Invalid status not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 15] Invalid category → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?category=INVALID" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid category rejected (400)"
else
    test_fail "Invalid category not rejected (got $HTTP_CODE)"
fi

# =========================================================================
# PAGINATION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      PAGINATION TESTS                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 16] Default page/limit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues" -H "Authorization: Bearer $DEPT1_TOKEN")
PAGE=$(echo "$RESP" | jq '.page')
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$PAGE" -eq 1 ] && [ "$LIMIT" -eq 10 ]; then
    test_pass "Default pagination (page=1, limit=10)"
else
    test_fail "Default pagination wrong (page: $PAGE, limit: $LIMIT)"
fi

echo -e "\n[TEST 17] page=1&limit=2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?page=1&limit=2" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
PAGE=$(echo "$RESP" | jq '.page')
LIMIT=$(echo "$RESP" | jq '.limit')
COUNT=$(echo "$RESP" | jq '.count')

if [ "$PAGE" -eq 1 ] && [ "$LIMIT" -eq 2 ] && [ "$COUNT" -le 2 ]; then
    test_pass "Custom pagination page=1&limit=2 works"
else
    test_fail "Custom pagination failed (page: $PAGE, limit: $LIMIT, count: $COUNT)"
fi

echo -e "\n[TEST 18] page=2&limit=2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?page=2&limit=2" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
PAGE=$(echo "$RESP" | jq '.page')
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$PAGE" -eq 2 ] && [ "$LIMIT" -eq 2 ]; then
    test_pass "Pagination page=2 works"
else
    test_fail "Pagination page=2 failed (page: $PAGE, limit: $LIMIT)"
fi

echo -e "\n[TEST 19] limit=50"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?limit=50" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$LIMIT" -eq 50 ]; then
    test_pass "Max limit 50 accepted"
else
    test_fail "Max limit 50 not accepted (got $LIMIT)"
fi

echo -e "\n[TEST 20] limit >50 is capped at 50"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?limit=100" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$LIMIT" -eq 50 ]; then
    test_pass "Limit >50 capped at 50"
else
    test_fail "Limit not capped (got $LIMIT)"
fi

echo -e "\n[TEST 21] Invalid page rejected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?page=-1" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid page rejected (400)"
else
    test_fail "Invalid page not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 22] Invalid limit rejected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?limit=0" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid limit rejected (400)"
else
    test_fail "Invalid limit not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 23] total is correct"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues" -H "Authorization: Bearer $DEPT1_TOKEN")
TOTAL=$(echo "$RESP" | jq '.total')
COUNT=$(echo "$RESP" | jq '.count')

if [ "$TOTAL" -ge "$COUNT" ]; then
    test_pass "Total count valid (total: $TOTAL, count: $COUNT)"
else
    test_fail "Total count invalid (total: $TOTAL, count: $COUNT)"
fi

echo -e "\n[TEST 24] totalPages is correct"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues?limit=2" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
TOTAL=$(echo "$RESP" | jq '.total')
LIMIT=$(echo "$RESP" | jq '.limit')
TOTAL_PAGES=$(echo "$RESP" | jq '.totalPages')
EXPECTED_PAGES=$(( ($TOTAL + $LIMIT - 1) / $LIMIT ))

if [ "$TOTAL_PAGES" -eq "$EXPECTED_PAGES" ]; then
    test_pass "TotalPages correct (got $TOTAL_PAGES, expected $EXPECTED_PAGES)"
else
    test_fail "TotalPages wrong (got $TOTAL_PAGES, expected $EXPECTED_PAGES)"
fi

# =========================================================================
# SORTING TEST
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      SORTING TEST                                       ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 25] Issues sorted by createdAt DESC (newest first)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/my-issues" -H "Authorization: Bearer $DEPT1_TOKEN")
DATES=$(echo "$RESP" | jq -r '.issues[].createdAt')

PREV_DATE=""
IS_SORTED=true
while IFS= read -r DATE; do
    if [ -n "$PREV_DATE" ]; then
        if [[ "$DATE" > "$PREV_DATE" ]]; then
            IS_SORTED=false
            break
        fi
    fi
    PREV_DATE="$DATE"
done <<< "$DATES"

if [ "$IS_SORTED" = true ]; then
    test_pass "Issues sorted newest first"
else
    test_fail "Issues not sorted correctly"
fi

# =========================================================================
# REGRESSION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      REGRESSION TESTS                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[REGRESSION 1] Department /me endpoint still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /departments/me works"
else
    test_fail "GET /departments/me broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 2] Issue start still works"
# Create and assign an issue, then start it
ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=Start Test" -F "description=Test" -F "category=ROADS" -F "location=Test")
START_ID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')

curl -s -X PATCH "$BASE_URL/issues/$START_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

curl -s -X PATCH "$BASE_URL/issues/$START_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT1_ID\"}" > /dev/null

RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$START_ID/start" \
    -H "Authorization: Bearer $DEPT1_TOKEN" -H "Content-Type: application/json")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Issue start works"
else
    test_fail "Issue start broken (got $HTTP_CODE)"
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

echo -e "\n[REGRESSION 4] User profile still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "User profile works"
else
    test_fail "User profile broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 5] Notifications still work"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Notifications work"
else
    test_fail "Notifications broken (got $HTTP_CODE)"
fi

# =========================================================================
# RESULTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                   TASK 8 VERIFICATION RESULTS                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Task 8 Tests: $PASSED passed"
echo "Total Tests: $((PASSED + FAILED))"
[ $FAILED -eq 0 ] && echo "✅ Status: ALL PASSED" || echo "❌ Status: $FAILED FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 TASK 8 VERIFICATION COMPLETE!"
    echo ""
    echo "✅ Status filtering works"
    echo "✅ Category filtering works"
    echo "✅ Pagination works"
    echo "✅ Sorting works (newest first)"
    echo "✅ Department isolation enforced"
    echo "✅ All security checks passing"
    echo "✅ All regressions passing"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
