#!/bin/bash

BASE_URL="http://localhost:4000/api"
V1_BASE_URL="http://localhost:4000/api/v1"

echo "==========================================="
echo "TASK 11.1 - USER PROFILE API ALIGNMENT TEST"
echo "==========================================="

PASSED=0
FAILED=0

# Setup: Register two test users
echo -e "\n[SETUP] Registering test users..."
USER1_REG=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Alice Test\",\"email\":\"alice$(date +%s)@example.com\",\"password\":\"password123\"}")
USER1_ID=$(echo "$USER1_REG" | jq -r '.user.id')
USER1_EMAIL=$(echo "$USER1_REG" | jq -r '.user.email')

USER2_REG=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Bob Test\",\"email\":\"bob$(date +%s)@example.com\",\"password\":\"password123\"}")
USER2_ID=$(echo "$USER2_REG" | jq -r '.user.id')
USER2_EMAIL=$(echo "$USER2_REG" | jq -r '.user.email')

if [ "$USER1_ID" = "null" ] || [ -z "$USER1_ID" ]; then
    echo "❌ Failed to register user 1"
    exit 1
fi

if [ "$USER2_ID" = "null" ] || [ -z "$USER2_ID" ]; then
    echo "❌ Failed to register user 2"
    exit 1
fi

echo "✅ User 1 created: $USER1_ID"
echo "✅ User 2 created: $USER2_ID"

# Login users
echo -e "\n[SETUP] Logging in users..."
USER1_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$USER1_EMAIL\",\"password\":\"password123\"}")
USER1_TOKEN=$(echo "$USER1_LOGIN" | jq -r '.token')

USER2_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$USER2_EMAIL\",\"password\":\"password123\"}")
USER2_TOKEN=$(echo "$USER2_LOGIN" | jq -r '.token')

if [ "$USER1_TOKEN" = "null" ] || [ -z "$USER1_TOKEN" ]; then
    echo "❌ Failed to login user 1"
    exit 1
fi

if [ "$USER2_TOKEN" = "null" ] || [ -z "$USER2_TOKEN" ]; then
    echo "❌ Failed to login user 2"
    exit 1
fi

echo "✅ Users logged in"

# TEST 1: GET own profile → 200
echo -e "\n[TEST 1] GET /api/v1/users/:id (own profile) → 200"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    RETURNED_ID=$(echo "$BODY" | jq -r '.id')
    RETURNED_NAME=$(echo "$BODY" | jq -r '.name')
    if [ "$RETURNED_ID" = "$USER1_ID" ] && [ "$RETURNED_NAME" = "Alice Test" ]; then
        echo "✅ PASS: GET own profile returns 200 with correct data"
        ((PASSED++))
    else
        echo "❌ FAIL: GET own profile returned wrong data (id=$RETURNED_ID, name=$RETURNED_NAME)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 2: GET another user's profile → 403
echo -e "\n[TEST 2] GET /api/v1/users/:id (another user's profile) → 403"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$V1_BASE_URL/users/$USER2_ID" \
    -H "Authorization: Bearer $USER1_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: GET another user's profile blocked with 403"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 3: GET profile without JWT → 401
echo -e "\n[TEST 3] GET /api/v1/users/:id (no JWT) → 401"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$V1_BASE_URL/users/$USER1_ID")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: GET without JWT blocked with 401"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

# TEST 4: GET profile with invalid JWT → 401
echo -e "\n[TEST 4] GET /api/v1/users/:id (invalid JWT) → 401"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer invalid.jwt.token")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: GET with invalid JWT blocked with 401"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

# TEST 5: GET profile with invalid ID format → 400
echo -e "\n[TEST 5] GET /api/v1/users/:id (invalid ID format) → 400"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$V1_BASE_URL/users/invalid-id-format" \
    -H "Authorization: Bearer $USER1_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: GET with invalid ID format blocked with 400"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 6: PUT own profile → 200
echo -e "\n[TEST 6] PUT /api/v1/users/:id (update own profile) → 200"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice Updated"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    RETURNED_NAME=$(echo "$BODY" | jq -r '.name')
    if [ "$RETURNED_NAME" = "Alice Updated" ]; then
        echo "✅ PASS: PUT own profile returns 200 and updates name"
        ((PASSED++))
    else
        echo "❌ FAIL: PUT own profile didn't update name (got $RETURNED_NAME)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 7: PUT another user's profile → 403
echo -e "\n[TEST 7] PUT /api/v1/users/:id (update another user's profile) → 403"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER2_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Hacked Name"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: PUT another user's profile blocked with 403"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 8: PUT without JWT → 401
echo -e "\n[TEST 8] PUT /api/v1/users/:id (no JWT) → 401"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Content-Type: application/json" \
    -d '{"name":"Hacked Name"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: PUT without JWT blocked with 401"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

# TEST 9: PUT with invalid JWT → 401
echo -e "\n[TEST 9] PUT /api/v1/users/:id (invalid JWT) → 401"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer invalid.jwt.token" \
    -H "Content-Type: application/json" \
    -d '{"name":"Hacked Name"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: PUT with invalid JWT blocked with 401"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

# TEST 10: Attempt to change role → rejected
echo -e "\n[TEST 10] PUT /api/v1/users/:id (attempt to change role) → 400"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice","role":"MODERATOR"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "400" ]; then
    MESSAGE=$(echo "$BODY" | jq -r '.message')
    if [[ "$MESSAGE" == *"role"* ]]; then
        echo "✅ PASS: Attempt to change role rejected with 400"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong error message (got: $MESSAGE)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 11: Attempt to change department_id → rejected
echo -e "\n[TEST 11] PUT /api/v1/users/:id (attempt to change department_id) → 400"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice","department_id":"507f1f77bcf86cd799439011"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "400" ]; then
    MESSAGE=$(echo "$BODY" | jq -r '.message')
    if [[ "$MESSAGE" == *"department"* ]]; then
        echo "✅ PASS: Attempt to change department_id rejected with 400"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong error message (got: $MESSAGE)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 12: Attempt to change password → rejected
echo -e "\n[TEST 12] PUT /api/v1/users/:id (attempt to change password) → 400"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice","password":"newpassword"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "400" ]; then
    MESSAGE=$(echo "$BODY" | jq -r '.message')
    if [[ "$MESSAGE" == *"password"* ]]; then
        echo "✅ PASS: Attempt to change password rejected with 400"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong error message (got: $MESSAGE)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 13: Update email to duplicate → 400
echo -e "\n[TEST 13] PUT /api/v1/users/:id (duplicate email) → 400"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$USER2_EMAIL\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "400" ]; then
    MESSAGE=$(echo "$BODY" | jq -r '.message')
    if [[ "$MESSAGE" == *"already in use"* ]] || [[ "$MESSAGE" == *"Email"* ]]; then
        echo "✅ PASS: Duplicate email rejected with 400"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong error message (got: $MESSAGE)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 14: Update email with invalid format → 400
echo -e "\n[TEST 14] PUT /api/v1/users/:id (invalid email format) → 400"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$V1_BASE_URL/users/$USER1_ID" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"email":"not-an-email"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "400" ]; then
    MESSAGE=$(echo "$BODY" | jq -r '.message')
    if [[ "$MESSAGE" == *"email"* ]] || [[ "$MESSAGE" == *"Invalid"* ]]; then
        echo "✅ PASS: Invalid email format rejected with 400"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong error message (got: $MESSAGE)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 15: Backward compatibility - old /api/auth/profile still works (GET)
echo -e "\n[TEST 15] Backward compatibility: GET /api/auth/profile → 200"
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER1_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Old GET /api/auth/profile endpoint still works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 16: Backward compatibility - old /api/auth/profile still works (PATCH)
echo -e "\n[TEST 16] Backward compatibility: PATCH /api/auth/profile → 200"
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER1_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Alice Via Old Endpoint"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Old PATCH /api/auth/profile endpoint still works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# Summary
echo -e "\n==========================================="
echo "TEST SUMMARY - TASK 11.1"
echo "==========================================="
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"
echo "TOTAL: $((PASSED + FAILED))"
echo "==========================================="

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    exit 1
fi
