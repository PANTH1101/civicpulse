#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "========================================="
echo "PROFILE MANAGEMENT - ALL ROLES TEST"
echo "========================================="

# =========================================
# TEST MODERATOR
# =========================================
echo -e "\n[MODERATOR TESTS]"
echo "Login as moderator..."
MOD_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"mod1@civicpulse.gov","password":"password123"}')
MOD_TOKEN=$(echo "$MOD_LOGIN" | jq -r '.token')

if [ "$MOD_TOKEN" = "null" ] || [ -z "$MOD_TOKEN" ]; then
    echo "❌ Moderator login failed"
    echo "$MOD_LOGIN" | jq '.'
else
    echo "✅ Moderator logged in"
    
    echo -e "\nGET /api/auth/profile (MODERATOR)..."
    MOD_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $MOD_TOKEN")
    echo "$MOD_PROFILE" | jq '.'
    
    if echo "$MOD_PROFILE" | jq '.user.role' | grep -q "MODERATOR"; then
        echo "✅ PASS: MODERATOR role retrieved"
    else
        echo "❌ FAIL: MODERATOR role not correct"
    fi
    
    if echo "$MOD_PROFILE" | jq '.user.department_id' | grep -q "null"; then
        echo "✅ PASS: MODERATOR has null department_id"
    else
        echo "❌ FAIL: MODERATOR department_id should be null"
    fi
    
    echo -e "\nPATCH /api/auth/profile (MODERATOR - update name)..."
    MOD_UPDATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Moderator One Updated"}')
    echo "$MOD_UPDATE" | jq '.'
    
    if echo "$MOD_UPDATE" | jq '.user.role' | grep -q "MODERATOR"; then
        echo "✅ PASS: MODERATOR role preserved after update"
    else
        echo "❌ FAIL: MODERATOR role changed"
    fi
fi

# =========================================
# TEST DEPARTMENT
# =========================================
echo -e "\n[DEPARTMENT TESTS]"
echo "Login as department user..."
DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water.dept@example.com","password":"password123"}')
DEPT_TOKEN=$(echo "$DEPT_LOGIN" | jq -r '.token')

if [ "$DEPT_TOKEN" = "null" ] || [ -z "$DEPT_TOKEN" ]; then
    echo "❌ Department login failed"
    echo "$DEPT_LOGIN" | jq '.'
else
    echo "✅ Department user logged in"
    
    echo -e "\nGET /api/auth/profile (DEPARTMENT)..."
    DEPT_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $DEPT_TOKEN")
    echo "$DEPT_PROFILE" | jq '.'
    
    if echo "$DEPT_PROFILE" | jq '.user.role' | grep -q "DEPARTMENT"; then
        echo "✅ PASS: DEPARTMENT role retrieved"
    else
        echo "❌ FAIL: DEPARTMENT role not correct"
    fi
    
    ORIG_DEPT_ID=$(echo "$DEPT_PROFILE" | jq -r '.user.department_id')
    if [ "$ORIG_DEPT_ID" != "null" ] && [ -n "$ORIG_DEPT_ID" ]; then
        echo "✅ PASS: DEPARTMENT has department_id: $ORIG_DEPT_ID"
    else
        echo "❌ FAIL: DEPARTMENT should have department_id"
    fi
    
    echo -e "\nPATCH /api/auth/profile (DEPARTMENT - update name)..."
    DEPT_UPDATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $DEPT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Water Department User Updated"}')
    echo "$DEPT_UPDATE" | jq '.'
    
    NEW_DEPT_ID=$(echo "$DEPT_UPDATE" | jq -r '.user.department_id')
    
    if [ "$ORIG_DEPT_ID" = "$NEW_DEPT_ID" ]; then
        echo "✅ PASS: DEPARTMENT department_id preserved: $NEW_DEPT_ID"
    else
        echo "❌ FAIL: DEPARTMENT department_id changed from $ORIG_DEPT_ID to $NEW_DEPT_ID"
    fi
    
    if echo "$DEPT_UPDATE" | jq '.user.role' | grep -q "DEPARTMENT"; then
        echo "✅ PASS: DEPARTMENT role preserved after update"
    else
        echo "❌ FAIL: DEPARTMENT role changed"
    fi
fi

# =========================================
# TEST ERROR CASES
# =========================================
echo -e "\n[ERROR CASE TESTS]"

# Register another test user for duplicate email test
echo "Register test user for duplicate email test..."
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User 2","email":"testuser2@example.com","password":"password123"}' > /dev/null

USER2_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"testuser2@example.com","password":"password123"}')
USER2_TOKEN=$(echo "$USER2_LOGIN" | jq -r '.token')

# Try duplicate email
echo -e "\nTest duplicate email (should return 409)..."
DUP_EMAIL=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$(echo $MOD_LOGIN | jq -r '.user.email')\"}")
DUP_STATUS=$(echo "$DUP_EMAIL" | tail -n 1)
DUP_BODY=$(echo "$DUP_EMAIL" | head -n 1)

if [ "$DUP_STATUS" = "409" ]; then
    echo "✅ PASS: Duplicate email rejected with 409"
else
    echo "❌ FAIL: Expected 409, got $DUP_STATUS"
fi

# Try invalid email
echo -e "\nTest invalid email format (should return 400)..."
INVALID_EMAIL=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"email":"notanemail"}')

if [ "$INVALID_EMAIL" = "400" ]; then
    echo "✅ PASS: Invalid email rejected with 400"
else
    echo "❌ FAIL: Expected 400, got $INVALID_EMAIL"
fi

# Try empty name
echo -e "\nTest empty name (should return 400)..."
EMPTY_NAME=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"   "}')

if [ "$EMPTY_NAME" = "400" ]; then
    echo "✅ PASS: Empty name rejected with 400"
else
    echo "❌ FAIL: Expected 400, got $EMPTY_NAME"
fi

# Try empty email
echo -e "\nTest empty email (should return 400)..."
EMPTY_EMAIL=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"email":"   "}')

if [ "$EMPTY_EMAIL" = "400" ]; then
    echo "✅ PASS: Empty email rejected with 400"
else
    echo "❌ FAIL: Expected 400, got $EMPTY_EMAIL"
fi

# Try no fields
echo -e "\nTest no fields provided (should return 400)..."
NO_FIELDS=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $USER2_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}')

if [ "$NO_FIELDS" = "400" ]; then
    echo "✅ PASS: No fields rejected with 400"
else
    echo "❌ FAIL: Expected 400, got $NO_FIELDS"
fi

# Try missing JWT
echo -e "\nTest missing JWT (should return 401)..."
NO_JWT=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/auth/profile")

if [ "$NO_JWT" = "401" ]; then
    echo "✅ PASS: Missing JWT rejected with 401"
else
    echo "❌ FAIL: Expected 401, got $NO_JWT"
fi

# Try invalid JWT
echo -e "\nTest invalid JWT (should return 401)..."
BAD_JWT=$(curl -s -o /dev/null -w "%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer invalidtoken123")

if [ "$BAD_JWT" = "401" ]; then
    echo "✅ PASS: Invalid JWT rejected with 401"
else
    echo "❌ FAIL: Expected 401, got $BAD_JWT"
fi

echo -e "\n========================================="
echo "ALL ROLES TEST COMPLETE"
echo "========================================="
