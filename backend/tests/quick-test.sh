#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "========================================="
echo "PROFILE MANAGEMENT QUICK TEST"
echo "========================================="

# Register a new citizen
echo -e "\n[1] Registering test citizen..."
REGISTER_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Citizen","email":"testcitizen@example.com","password":"password123"}')
echo "$REGISTER_RESPONSE" | jq '.'

# Login
echo -e "\n[2] Logging in..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"testcitizen@example.com","password":"password123"}')
TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
echo "Token: $TOKEN"

# Get profile
echo -e "\n[3] GET /api/auth/profile..."
GET_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN")
echo "$GET_PROFILE" | jq '.'

# Check if password is NOT in response
if echo "$GET_PROFILE" | grep -q '"password"'; then
    echo "❌ FAIL: Password found in response!"
else
    echo "✅ PASS: Password not exposed"
fi

# Check if all required fields are present
if echo "$GET_PROFILE" | jq '.user | has("id") and has("name") and has("email") and has("role") and has("department_id") and has("createdAt") and has("updatedAt")' | grep -q 'true'; then
    echo "✅ PASS: All required fields present"
else
    echo "❌ FAIL: Missing required fields"
fi

# Update name
echo -e "\n[4] PATCH /api/auth/profile - Update name..."
UPDATE_NAME=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Citizen Updated"}')
echo "$UPDATE_NAME" | jq '.'

# Update email
echo -e "\n[5] PATCH /api/auth/profile - Update email..."
NEW_EMAIL="testcitizen.updated.$(date +%s)@example.com"
UPDATE_EMAIL=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$NEW_EMAIL\"}")
echo "$UPDATE_EMAIL" | jq '.'

# Try to change role (should fail)
echo -e "\n[6] PATCH /api/auth/profile - Attempt to change role (should fail)..."
CHANGE_ROLE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test","role":"MODERATOR"}')
echo "$CHANGE_ROLE" | jq '.'

if echo "$CHANGE_ROLE" | grep -q "Cannot modify role"; then
    echo "✅ PASS: Role modification blocked"
else
    echo "❌ FAIL: Role modification not blocked"
fi

# Try to change department_id (should fail)
echo -e "\n[7] PATCH /api/auth/profile - Attempt to change department_id (should fail)..."
CHANGE_DEPT=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test","department_id":"507f1f77bcf86cd799439011"}')
echo "$CHANGE_DEPT" | jq '.'

if echo "$CHANGE_DEPT" | grep -q "Cannot modify department_id"; then
    echo "✅ PASS: department_id modification blocked"
else
    echo "❌ FAIL: department_id modification not blocked"
fi

# Try to change password (should fail)
echo -e "\n[8] PATCH /api/auth/profile - Attempt to change password (should fail)..."
CHANGE_PWD=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test","password":"newpassword"}')
echo "$CHANGE_PWD" | jq '.'

if echo "$CHANGE_PWD" | grep -q "Cannot modify password"; then
    echo "✅ PASS: Password modification blocked"
else
    echo "❌ FAIL: Password modification not blocked"
fi

# Verify final profile
echo -e "\n[9] Final profile check..."
FINAL_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN")
echo "$FINAL_PROFILE" | jq '.'

# Verify role is still CITIZEN
if echo "$FINAL_PROFILE" | jq '.user.role' | grep -q "CITIZEN"; then
    echo "✅ PASS: Role remained CITIZEN"
else
    echo "❌ FAIL: Role was changed"
fi

echo -e "\n========================================="
echo "PROFILE MANAGEMENT TEST COMPLETE"
echo "========================================="
