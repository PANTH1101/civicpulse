#!/bin/bash

BASE_URL="http://localhost:4000/api"
PASSED=0
FAILED=0

echo "========================================================================"
echo "PROFILE MANAGEMENT TESTS"
echo "========================================================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASS${NC}: $2"
        ((PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: $2"
        ((FAILED++))
    fi
}

# ========================================================================
# SETUP: Get tokens
# ========================================================================
echo -e "${BLUE}[SETUP] Logging in as test users...${NC}"

# Login as CITIZEN
CITIZEN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"alice@example.com","password":"password123"}')
CITIZEN_TOKEN=$(echo $CITIZEN_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Login as MODERATOR
MODERATOR_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"mod1@civicpulse.gov","password":"password123"}')
MODERATOR_TOKEN=$(echo $MODERATOR_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

# Login as DEPARTMENT
DEPARTMENT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water.dept@example.com","password":"password123"}')
DEPARTMENT_TOKEN=$(echo $DEPARTMENT_RESPONSE | grep -o '"token":"[^"]*' | cut -d'"' -f4)

echo -e "${GREEN}✓${NC} Tokens acquired"
echo ""

# ========================================================================
# TEST 1: GET /api/auth/profile - CITIZEN
# ========================================================================
echo "[TEST 1] GET /api/auth/profile - CITIZEN role"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
BODY=$(echo "$RESPONSE" | head -n -1)
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ] && echo "$BODY" | grep -q '"role":"CITIZEN"' && ! echo "$BODY" | grep -q '"password"'; then
    test_result 0 "GET profile as CITIZEN"
else
    test_result 1 "GET profile as CITIZEN (status: $STATUS)"
fi

# ========================================================================
# TEST 2: GET /api/auth/profile - MODERATOR
# ========================================================================
echo "[TEST 2] GET /api/auth/profile - MODERATOR role"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $MODERATOR_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "200" ] && echo "$BODY" | grep -q '"role":"MODERATOR"' && ! echo "$BODY" | grep -q '"password"'; then
    test_result 0 "GET profile as MODERATOR"
else
    test_result 1 "GET profile as MODERATOR (status: $STATUS)"
fi

# ========================================================================
# TEST 3: GET /api/auth/profile - DEPARTMENT
# ========================================================================
echo "[TEST 3] GET /api/auth/profile - DEPARTMENT role"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "200" ] && echo "$BODY" | grep -q '"role":"DEPARTMENT"' && echo "$BODY" | grep -q '"department_id"' && ! echo "$BODY" | grep -q '"password"'; then
    test_result 0 "GET profile as DEPARTMENT (with department_id)"
else
    test_result 1 "GET profile as DEPARTMENT (status: $STATUS)"
fi

# ========================================================================
# TEST 4: GET /api/auth/profile - No JWT (401)
# ========================================================================
echo "[TEST 4] GET /api/auth/profile - Missing JWT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/auth/profile")

if [ "$STATUS" = "401" ]; then
    test_result 0 "Missing JWT returns 401"
else
    test_result 1 "Missing JWT (expected 401, got $STATUS)"
fi

# ========================================================================
# TEST 5: GET /api/auth/profile - Invalid JWT (401)
# ========================================================================
echo "[TEST 5] GET /api/auth/profile - Invalid JWT"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer invalidtoken123")

if [ "$STATUS" = "401" ]; then
    test_result 0 "Invalid JWT returns 401"
else
    test_result 1 "Invalid JWT (expected 401, got $STATUS)"
fi

# ========================================================================
# TEST 6: PATCH /api/auth/profile - Update name
# ========================================================================
echo "[TEST 6] PATCH /api/auth/profile - Update name"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice Updated"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "200" ] && echo "$BODY" | grep -q '"name":"Alice Updated"' && echo "$BODY" | grep -q '"role":"CITIZEN"'; then
    test_result 0 "Update name (role preserved)"
else
    test_result 1 "Update name (status: $STATUS)"
fi

# ========================================================================
# TEST 7: PATCH /api/auth/profile - Update email
# ========================================================================
echo "[TEST 7] PATCH /api/auth/profile - Update email"
NEW_EMAIL="alice.test.$(date +%s)@example.com"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$NEW_EMAIL\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "200" ] && echo "$BODY" | grep -q "$(echo $NEW_EMAIL | tr '[:upper:]' '[:lower:]')"; then
    test_result 0 "Update email"
else
    test_result 1 "Update email (status: $STATUS)"
fi

# ========================================================================
# TEST 8: PATCH /api/auth/profile - Duplicate email (409)
# ========================================================================
echo "[TEST 8] PATCH /api/auth/profile - Duplicate email"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"email":"bob@example.com"}')

if [ "$STATUS" = "409" ]; then
    test_result 0 "Duplicate email rejected (409)"
else
    test_result 1 "Duplicate email (expected 409, got $STATUS)"
fi

# ========================================================================
# TEST 9: PATCH /api/auth/profile - Invalid email format (400)
# ========================================================================
echo "[TEST 9] PATCH /api/auth/profile - Invalid email format"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"email":"not-an-email"}')

if [ "$STATUS" = "400" ]; then
    test_result 0 "Invalid email rejected (400)"
else
    test_result 1 "Invalid email (expected 400, got $STATUS)"
fi

# ========================================================================
# TEST 10: PATCH /api/auth/profile - Empty name (400)
# ========================================================================
echo "[TEST 10] PATCH /api/auth/profile - Empty name"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"   "}')

if [ "$STATUS" = "400" ]; then
    test_result 0 "Empty name rejected (400)"
else
    test_result 1 "Empty name (expected 400, got $STATUS)"
fi

# ========================================================================
# TEST 11: PATCH /api/auth/profile - Attempt to change role (400)
# ========================================================================
echo "[TEST 11] PATCH /api/auth/profile - Attempt to change role"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice","role":"MODERATOR"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "400" ] && echo "$BODY" | grep -q "role"; then
    test_result 0 "Role modification blocked (400)"
else
    test_result 1 "Role modification (expected 400, got $STATUS)"
fi

# ========================================================================
# TEST 12: PATCH /api/auth/profile - Attempt to change department_id (400)
# ========================================================================
echo "[TEST 12] PATCH /api/auth/profile - Attempt to change department_id"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Water Dept","department_id":"507f1f77bcf86cd799439011"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "400" ] && echo "$BODY" | grep -q "department_id"; then
    test_result 0 "department_id modification blocked (400)"
else
    test_result 1 "department_id modification (expected 400, got $STATUS)"
fi

# ========================================================================
# TEST 13: PATCH /api/auth/profile - Attempt to change password (400)
# ========================================================================
echo "[TEST 13] PATCH /api/auth/profile - Attempt to change password"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice","password":"newpassword"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "400" ] && echo "$BODY" | grep -q "password"; then
    test_result 0 "Password modification blocked (400)"
else
    test_result 1 "Password modification (expected 400, got $STATUS)"
fi

# ========================================================================
# TEST 14: PATCH /api/auth/profile - No fields provided (400)
# ========================================================================
echo "[TEST 14] PATCH /api/auth/profile - No fields provided"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}')

if [ "$STATUS" = "400" ]; then
    test_result 0 "No fields rejected (400)"
else
    test_result 1 "No fields (expected 400, got $STATUS)"
fi

# ========================================================================
# TEST 15: PATCH /api/auth/profile - MODERATOR update preserves role
# ========================================================================
echo "[TEST 15] PATCH /api/auth/profile - MODERATOR preserves role"
NEW_MOD_EMAIL="mod.test.$(date +%s)@example.com"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Moderator Updated\",\"email\":\"$NEW_MOD_EMAIL\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$STATUS" = "200" ] && echo "$BODY" | grep -q '"role":"MODERATOR"' && echo "$BODY" | grep -q '"department_id":null'; then
    test_result 0 "MODERATOR update preserves role and null department_id"
else
    test_result 1 "MODERATOR update (status: $STATUS)"
fi

# ========================================================================
# TEST 16: PATCH /api/auth/profile - DEPARTMENT preserves department_id
# ========================================================================
echo "[TEST 16] PATCH /api/auth/profile - DEPARTMENT preserves department_id"

# Get original department_id
ORIG_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN")
ORIG_DEPT_ID=$(echo $ORIG_PROFILE | grep -o '"department_id":"[^"]*' | cut -d'"' -f4)

# Update name
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Water Department Updated"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)
NEW_DEPT_ID=$(echo $BODY | grep -o '"department_id":"[^"]*' | cut -d'"' -f4)

if [ "$STATUS" = "200" ] && [ "$ORIG_DEPT_ID" = "$NEW_DEPT_ID" ] && echo "$BODY" | grep -q '"role":"DEPARTMENT"'; then
    test_result 0 "DEPARTMENT update preserves department_id"
else
    test_result 1 "DEPARTMENT update (status: $STATUS, dept_id changed: $ORIG_DEPT_ID -> $NEW_DEPT_ID)"
fi

# ========================================================================
# RESULTS
# ========================================================================
echo ""
echo "========================================================================"
echo "PROFILE MANAGEMENT TEST RESULTS"
echo "========================================================================"
echo -e "Total Tests: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}Failed: $FAILED${NC}"
else
    echo -e "${RED}Failed: $FAILED${NC}"
fi
echo "========================================================================"

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
