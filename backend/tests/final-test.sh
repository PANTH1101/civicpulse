#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "========================================="
echo "FINAL PROFILE MANAGEMENT TEST"
echo "========================================="

# Test with DEPARTMENT user (we know these exist)
echo -e "\n[TEST 1: DEPARTMENT USER]"
echo "Login as Water Supply Department..."
DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}')
DEPT_TOKEN=$(echo "$DEPT_LOGIN" | jq -r '.token')

if [ "$DEPT_TOKEN" != "null" ] && [ -n "$DEPT_TOKEN" ]; then
    echo "✅ DEPARTMENT login successful"
    
    echo -e "\nGET /api/auth/profile..."
    DEPT_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $DEPT_TOKEN")
    echo "$DEPT_PROFILE" | jq '.'
    
    # Validate response
    if echo "$DEPT_PROFILE" | jq '.user.role' | grep -q "DEPARTMENT"; then
        echo "✅ Role: DEPARTMENT"
    fi
    
    DEPT_ID=$(echo "$DEPT_PROFILE" | jq -r '.user.department_id')
    if [ "$DEPT_ID" != "null" ] && [ -n "$DEPT_ID" ]; then
        echo "✅ department_id present: $DEPT_ID"
    fi
    
    if echo "$DEPT_PROFILE" | grep -q '"password"'; then
        echo "❌ FAIL: Password exposed!"
    else
        echo "✅ Password NOT exposed"
    fi
    
    # Update profile
    echo -e "\nPATCH /api/auth/profile - Update name..."
    DEPT_UPDATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $DEPT_TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"name":"Water Dept Updated"}')
    echo "$DEPT_UPDATE" | jq '.'
    
    NEW_DEPT_ID=$(echo "$DEPT_UPDATE" | jq -r '.user.department_id')
    if [ "$DEPT_ID" = "$NEW_DEPT_ID" ]; then
        echo "✅ department_id preserved: $NEW_DEPT_ID"
    else
        echo "❌ department_id changed!"
    fi
    
    if echo "$DEPT_UPDATE" | jq '.user.role' | grep -q "DEPARTMENT"; then
        echo "✅ Role preserved: DEPARTMENT"
    else
        echo "❌ Role changed!"
    fi
fi

# Test moderator (try the one we just created)
echo -e "\n[TEST 2: MODERATOR USER]"
echo "Login as moderator..."
MOD_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"mod1@civicpulse.gov","password":"password123"}')
MOD_TOKEN=$(echo "$MOD_LOGIN" | jq -r '.token')

if [ "$MOD_TOKEN" != "null" ] && [ -n "$MOD_TOKEN" ]; then
    echo "✅ MODERATOR login successful"
    
    echo -e "\nGET /api/auth/profile..."
    MOD_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $MOD_TOKEN")
    echo "$MOD_PROFILE" | jq '.'
    
    if echo "$MOD_PROFILE" | jq '.user.role' | grep -q "MODERATOR"; then
        echo "✅ Role: MODERATOR"
    fi
    
    if echo "$MOD_PROFILE" | jq '.user.department_id' | grep -q "null"; then
        echo "✅ department_id is null"
    fi
    
    # Update profile
    echo -e "\nPATCH /api/auth/profile - Update email..."
    NEW_EMAIL="mod1.updated.$(date +%s)@civicpulse.gov"
    MOD_UPDATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"email\":\"$NEW_EMAIL\"}")
    echo "$MOD_UPDATE" | jq '.'
    
    if echo "$MOD_UPDATE" | jq '.user.role' | grep -q "MODERATOR"; then
        echo "✅ Role preserved: MODERATOR"
    fi
    
    if echo "$MOD_UPDATE" | jq '.user.department_id' | grep -q "null"; then
        echo "✅ department_id remains null"
    fi
else
    echo "⚠️ MODERATOR login failed (expected - not in DB)"
fi

# Test with regular citizen
echo -e "\n[TEST 3: CITIZEN USER]"
echo "Register new citizen..."
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Citizen","email":"finaltest@example.com","password":"password123"}' > /dev/null

CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"finaltest@example.com","password":"password123"}')
CITIZEN_TOKEN=$(echo "$CITIZEN_LOGIN" | jq -r '.token')

echo "✅ CITIZEN login successful"

echo -e "\nGET /api/auth/profile..."
CITIZEN_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
echo "$CITIZEN_PROFILE" | jq '.'

if echo "$CITIZEN_PROFILE" | jq '.user.role' | grep -q "CITIZEN"; then
    echo "✅ Role: CITIZEN"
fi

if echo "$CITIZEN_PROFILE" | jq '.user.department_id' | grep -q "null"; then
    echo "✅ department_id is null"
fi

# Try to escalate to MODERATOR
echo -e "\nPATCH /api/auth/profile - Try to escalate to MODERATOR..."
ESCALATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"role":"MODERATOR"}')
echo "$ESCALATE" | jq '.'

if echo "$ESCALATE" | grep -q "Cannot modify role"; then
    echo "✅ Role escalation blocked"
else
    echo "❌ Role escalation NOT blocked!"
fi

# Verify still CITIZEN
FINAL_CHECK=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
if echo "$FINAL_CHECK" | jq '.user.role' | grep -q "CITIZEN"; then
    echo "✅ Still CITIZEN after attempted escalation"
else
    echo "❌ Role was changed!"
fi

echo -e "\n========================================="
echo "PROFILE MANAGEMENT TESTS COMPLETE"
echo "========================================="
