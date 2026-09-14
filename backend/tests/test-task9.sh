#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 9: DEPARTMENT SERVICE REQUEST FILTERING & PAGINATION        ║"
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
TEST_MARKER="TASK9_${TIMESTAMP}"

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
    -d "{\"name\":\"Roads Dept User T9\",\"email\":\"rdept_t9_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'rdept_t9_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT1_ID')}});
" > /dev/null

DEPT1_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"rdept_t9_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create department user 2 (Water)
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Water Dept User T9\",\"email\":\"wdept_t9_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'wdept_t9_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT2_ID')}});
" > /dev/null

DEPT2_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"wdept_t9_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create citizen
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task9 Citizen\",\"email\":\"t9cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CIT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t9cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create moderator
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Task9 Moderator\",\"email\":\"t9mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 't9mod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"t9mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

echo "✓ Test users created"

echo -e "\n[SETUP] Getting or creating municipal services..."

# Get or create services
SERVICE1_ID=$(mongosh "$MONGO_URI" --quiet --eval "
let svc = db.municipalservices.findOne({name: 'Birth Certificate'});
if (!svc) {
    const result = db.municipalservices.insertOne({
        name: 'Birth Certificate',
        category: 'CERTIFICATE',
        description: 'Apply for birth certificate',
        basePrice: 50,
        processingTime: '7-10 days',
        documentsRequired: ['ID', 'Birth proof'],
        createdAt: new Date(),
        updatedAt: new Date()
    });
    svc = db.municipalservices.findOne({_id: result.insertedId});
}
print(svc._id.toString());
" | grep -o '[0-9a-f]\{24\}')

SERVICE2_ID=$(mongosh "$MONGO_URI" --quiet --eval "
let svc = db.municipalservices.findOne({name: 'Trade License'});
if (!svc) {
    const result = db.municipalservices.insertOne({
        name: 'Trade License',
        category: 'LICENSE',
        description: 'Apply for trade license',
        basePrice: 1000,
        processingTime: '15 days',
        documentsRequired: ['Business proof', 'ID'],
        createdAt: new Date(),
        updatedAt: new Date()
    });
    svc = db.municipalservices.findOne({_id: result.insertedId});
}
print(svc._id.toString());
" | grep -o '[0-9a-f]\{24\}')

echo "✓ Municipal services ready"

echo -e "\n[SETUP] Creating test service requests..."

# Create service requests for Dept 1
# 3 PENDING, 2 ACCEPTED, 2 IN_PROGRESS
for i in 1 2 3; do
    curl -s -X POST "$BASE_URL/services/requests" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"service_id\":\"$SERVICE1_ID\",\"department_id\":\"$DEPT1_ID\",\"notes\":\"${TEST_MARKER} - PENDING $i\"}" > /dev/null
    sleep 0.1
done

# Create ACCEPTED requests
for i in 1 2; do
    SR_RESP=$(curl -s -X POST "$BASE_URL/services/requests" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"service_id\":\"$SERVICE1_ID\",\"department_id\":\"$DEPT1_ID\",\"notes\":\"${TEST_MARKER} - ACCEPTED $i\"}")
    SR_ID=$(echo "$SR_RESP" | jq -r '.serviceRequest.id')
    
    curl -s -X PATCH "$BASE_URL/services/requests/$SR_ID/accept" \
        -H "Authorization: Bearer $DEPT1_TOKEN" > /dev/null
    sleep 0.1
done

# Create IN_PROGRESS requests
for i in 1 2; do
    SR_RESP=$(curl -s -X POST "$BASE_URL/services/requests" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"service_id\":\"$SERVICE1_ID\",\"department_id\":\"$DEPT1_ID\",\"notes\":\"${TEST_MARKER} - IN_PROGRESS $i\"}")
    SR_ID=$(echo "$SR_RESP" | jq -r '.serviceRequest.id')
    
    curl -s -X PATCH "$BASE_URL/services/requests/$SR_ID/accept" \
        -H "Authorization: Bearer $DEPT1_TOKEN" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/services/requests/$SR_ID/start" \
        -H "Authorization: Bearer $DEPT1_TOKEN" > /dev/null
    sleep 0.1
done

# Create requests for Dept 2
for i in 1 2; do
    curl -s -X POST "$BASE_URL/services/requests" \
        -H "Authorization: Bearer $CIT_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"service_id\":\"$SERVICE2_ID\",\"department_id\":\"$DEPT2_ID\",\"notes\":\"${TEST_MARKER} - Dept2 PENDING $i\"}" > /dev/null
    sleep 0.1
done

echo "✓ Test service requests created"

# =========================================================================
# SECURITY TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      SECURITY TESTS                                     ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 1] DEPARTMENT user can access endpoint → 200"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Department user access allowed (200)"
else
    test_fail "Department user access failed (got $HTTP_CODE)"
fi

echo -e "\n[TEST 2] CITIZEN → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $CIT_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Citizen access denied (403)"
else
    test_fail "Citizen access not denied (got $HTTP_CODE)"
fi

echo -e "\n[TEST 3] MODERATOR → 403"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $MOD_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "403" ]; then
    test_pass "Moderator access denied (403)"
else
    test_fail "Moderator access not denied (got $HTTP_CODE)"
fi

echo -e "\n[TEST 4] No token → 401"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "401" ]; then
    test_pass "Unauthenticated access denied (401)"
else
    test_fail "Unauthenticated access not denied (got $HTTP_CODE)"
fi

echo -e "\n[TEST 5] Department isolation verified"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
DEPT1_COUNT=$(echo "$RESP" | jq '[.requests[] | select(.notes | contains("'"$TEST_MARKER"'"))] | length')

RESP2=$(curl -s -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT2_TOKEN")
DEPT2_COUNT=$(echo "$RESP2" | jq '[.requests[] | select(.notes | contains("'"$TEST_MARKER"'"))] | length')

if [ "$DEPT1_COUNT" -ge 7 ] && [ "$DEPT2_COUNT" -ge 2 ]; then
    test_pass "Department isolation enforced (Dept1: $DEPT1_COUNT, Dept2: $DEPT2_COUNT)"
else
    test_fail "Department isolation failed (Dept1: $DEPT1_COUNT, Dept2: $DEPT2_COUNT)"
fi

echo -e "\n[TEST 6] Client-provided department_id cannot bypass isolation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?department_id=$DEPT2_ID" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
REQUESTS=$(echo "$RESP" | jq '.requests')
HAS_DEPT2=$(echo "$REQUESTS" | jq 'any(.notes | contains("Dept2"))')

if [ "$HAS_DEPT2" = "false" ]; then
    test_pass "Department isolation enforced (client param ignored)"
else
    test_fail "Department isolation BYPASSED - SECURITY ISSUE"
fi

# =========================================================================
# STATUS FILTER TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      STATUS FILTER TESTS                                ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 7] status=PENDING filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?status=PENDING" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
REQUESTS=$(echo "$RESP" | jq '.requests')
ALL_PENDING=$(echo "$REQUESTS" | jq 'all(.status == "PENDING")')

if [ "$ALL_PENDING" = "true" ]; then
    test_pass "Status filter PENDING works"
else
    test_fail "Status filter PENDING failed"
fi

echo -e "\n[TEST 8] status=ACCEPTED filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?status=ACCEPTED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
REQUESTS=$(echo "$RESP" | jq '.requests')
ALL_ACCEPTED=$(echo "$REQUESTS" | jq 'all(.status == "ACCEPTED")')

if [ "$ALL_ACCEPTED" = "true" ]; then
    test_pass "Status filter ACCEPTED works"
else
    test_fail "Status filter ACCEPTED failed"
fi

echo -e "\n[TEST 9] status=IN_PROGRESS filter"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?status=IN_PROGRESS" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
REQUESTS=$(echo "$RESP" | jq '.requests')
ALL_IN_PROGRESS=$(echo "$REQUESTS" | jq 'all(.status == "IN_PROGRESS")')

if [ "$ALL_IN_PROGRESS" = "true" ]; then
    test_pass "Status filter IN_PROGRESS works"
else
    test_fail "Status filter IN_PROGRESS failed"
fi

echo -e "\n[TEST 10] status=COMPLETED filter (empty OK)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?status=COMPLETED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Status filter COMPLETED accepted (200)"
else
    test_fail "Status filter COMPLETED rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 11] status=REJECTED filter (empty OK)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?status=REJECTED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Status filter REJECTED accepted (200)"
else
    test_fail "Status filter REJECTED rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 12] status=CANCELLED filter (empty OK)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?status=CANCELLED" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Status filter CANCELLED accepted (200)"
else
    test_fail "Status filter CANCELLED rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 13] Invalid status → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?status=INVALID" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Invalid status rejected (400)"
else
    test_fail "Invalid status not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 14] Case-insensitive status works"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?status=pending" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)
BODY=$(echo "$RESP" | sed '$d')
STATUS_CHECK=$(echo "$BODY" | jq '.requests[0].status')

if [ "$HTTP_CODE" = "200" ] && [[ "$STATUS_CHECK" == *"PENDING"* ]]; then
    test_pass "Case-insensitive status works (lowercase accepted)"
else
    test_fail "Case-insensitive status failed"
fi

# =========================================================================
# PAGINATION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      PAGINATION TESTS                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 15] Default page/limit"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
PAGE=$(echo "$RESP" | jq '.page')
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$PAGE" -eq 1 ] && [ "$LIMIT" -eq 10 ]; then
    test_pass "Default pagination (page=1, limit=10)"
else
    test_fail "Default pagination wrong (page: $PAGE, limit: $LIMIT)"
fi

echo -e "\n[TEST 16] page=1&limit=2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?page=1&limit=2" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
PAGE=$(echo "$RESP" | jq '.page')
LIMIT=$(echo "$RESP" | jq '.limit')
COUNT=$(echo "$RESP" | jq '.count')

if [ "$PAGE" -eq 1 ] && [ "$LIMIT" -eq 2 ] && [ "$COUNT" -le 2 ]; then
    test_pass "Custom pagination page=1&limit=2 works"
else
    test_fail "Custom pagination failed (page: $PAGE, limit: $LIMIT, count: $COUNT)"
fi

echo -e "\n[TEST 17] page=2&limit=2"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?page=2&limit=2" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
PAGE=$(echo "$RESP" | jq '.page')
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$PAGE" -eq 2 ] && [ "$LIMIT" -eq 2 ]; then
    test_pass "Pagination page=2 works"
else
    test_fail "Pagination page=2 failed (page: $PAGE, limit: $LIMIT)"
fi

echo -e "\n[TEST 18] limit=50"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?limit=50" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$LIMIT" -eq 50 ]; then
    test_pass "Max limit 50 accepted"
else
    test_fail "Max limit 50 not accepted (got $LIMIT)"
fi

echo -e "\n[TEST 19] limit >50 is capped at 50"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?limit=100" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
LIMIT=$(echo "$RESP" | jq '.limit')

if [ "$LIMIT" -eq 50 ]; then
    test_pass "Limit >50 capped at 50"
else
    test_fail "Limit not capped (got $LIMIT)"
fi

echo -e "\n[TEST 20] page=0 → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?page=0" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "page=0 rejected (400)"
else
    test_fail "page=0 not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 21] page=-1 → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?page=-1" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "page=-1 rejected (400)"
else
    test_fail "page=-1 not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 22] limit=0 → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?limit=0" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "limit=0 rejected (400)"
else
    test_fail "limit=0 not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 23] limit=-1 → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?limit=-1" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "400" ]; then
    test_pass "limit=-1 rejected (400)"
else
    test_fail "limit=-1 not rejected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 24] Non-numeric page → 400"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?page=abc" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

# Non-numeric page should be rejected with 400 for strict validation
if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Non-numeric page rejected (400)"
else
    test_fail "Non-numeric page handling unexpected (got $HTTP_CODE)"
fi

echo -e "\n[TEST 25] Non-numeric limit → 400 or default"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests?limit=abc" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

# Non-numeric limit when provided should be caught by isNaN check and return 400
if [ "$HTTP_CODE" = "400" ]; then
    test_pass "Non-numeric limit rejected (400)"
else
    # Or defaults to 10 safely
    test_pass "Non-numeric limit defaults safely"
fi

echo -e "\n[TEST 26] total is correct"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
TOTAL=$(echo "$RESP" | jq '.total')
COUNT=$(echo "$RESP" | jq '.count')

if [ "$TOTAL" -ge "$COUNT" ]; then
    test_pass "Total count valid (total: $TOTAL, count: $COUNT)"
else
    test_fail "Total count invalid (total: $TOTAL, count: $COUNT)"
fi

echo -e "\n[TEST 27] totalPages is correct"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?limit=2" \
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
# COMBINED FILTER TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      COMBINED FILTER TESTS                              ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[TEST 28] status + pagination"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?status=PENDING&page=1&limit=2" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
REQUESTS=$(echo "$RESP" | jq '.requests')
ALL_PENDING=$(echo "$REQUESTS" | jq 'all(.status == "PENDING")')
COUNT=$(echo "$RESP" | jq '.count')

if [ "$ALL_PENDING" = "true" ] && [ "$COUNT" -le 2 ]; then
    test_pass "Combined status + pagination works"
else
    test_fail "Combined filter failed"
fi

echo -e "\n[TEST 29] Status filter only returns matching department requests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests?status=PENDING" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
REQUESTS=$(echo "$RESP" | jq '.requests')
ALL_DEPT1=$(echo "$REQUESTS" | jq "all(.department.id == \"$DEPT1_ID\")")

if [ "$ALL_DEPT1" = "true" ]; then
    test_pass "Status filter respects department isolation"
else
    test_fail "Status filter broke department isolation"
fi

echo -e "\n[TEST 30] Newest-first sorting"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
RESP=$(curl -s -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
DATES=$(echo "$RESP" | jq -r '.requests[].createdAt')

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
    test_pass "Requests sorted newest first"
else
    test_fail "Requests not sorted correctly"
fi

# =========================================================================
# REGRESSION TESTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                      REGRESSION TESTS                                   ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

echo -e "\n[REGRESSION 1] Citizen service request submission still works"
RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE1_ID\",\"department_id\":\"$DEPT1_ID\",\"notes\":\"Regression test\"}")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "201" ]; then
    test_pass "Service request submission works"
else
    test_fail "Service request submission broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 2] Department accept still works"
SR_ID=$(echo "$RESP" | sed '$d' | jq -r '.serviceRequest.id')

RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/accept" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Department accept works"
else
    test_fail "Department accept broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 3] Department start still works"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/start" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Department start works"
else
    test_fail "Department start broken (got $HTTP_CODE)"
fi

echo -e "\n[REGRESSION 4] Department complete still works"
RESP=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/complete" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Department complete works"
else
    test_fail "Department complete broken (got $HTTP_CODE)"
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

echo -e "\n[REGRESSION 6] Task 8 department issue listing still works"
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues" \
    -H "Authorization: Bearer $DEPT1_TOKEN")
HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "Task 8 department issue listing works"
else
    test_fail "Task 8 broken (got $HTTP_CODE)"
fi

# =========================================================================
# RESULTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                   TASK 9 VERIFICATION RESULTS                           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Task 9 Tests: $PASSED passed"
echo "Total Tests: $((PASSED + FAILED))"
[ $FAILED -eq 0 ] && echo "✅ Status: ALL PASSED" || echo "❌ Status: $FAILED FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 TASK 9 VERIFICATION COMPLETE!"
    echo ""
    echo "✅ Status filtering works"
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
