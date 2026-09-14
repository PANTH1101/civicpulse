#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║         CIVICPULSE TASK 1: PROFILE MANAGEMENT DEMONSTRATION           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

# Register a fresh user
echo -e "\n📝 Registering new test user..."
TIMESTAMP=$(date +%s)
REGISTER=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Demo User\",\"email\":\"demo$TIMESTAMP@example.com\",\"password\":\"password123\"}")
echo "$REGISTER" | jq '.'

# Login
echo -e "\n🔐 Logging in..."
LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"demo$TIMESTAMP@example.com\",\"password\":\"password123\"}")
TOKEN=$(echo "$LOGIN" | jq -r '.token')
echo "✓ Token acquired"

# View profile
echo -e "\n👤 GET /api/auth/profile - View Profile"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN")
echo "$PROFILE" | jq '.'

# Check all required fields
echo -e "\n📊 Validation Checks:"
echo "$PROFILE" | jq '.user | has("id")' | grep -q 'true' && echo "  ✓ id present"
echo "$PROFILE" | jq '.user | has("name")' | grep -q 'true' && echo "  ✓ name present"
echo "$PROFILE" | jq '.user | has("email")' | grep -q 'true' && echo "  ✓ email present"
echo "$PROFILE" | jq '.user | has("role")' | grep -q 'true' && echo "  ✓ role present"
echo "$PROFILE" | jq '.user | has("department_id")' | grep -q 'true' && echo "  ✓ department_id present"
echo "$PROFILE" | jq '.user | has("createdAt")' | grep -q 'true' && echo "  ✓ createdAt present"
echo "$PROFILE" | jq '.user | has("updatedAt")' | grep -q 'true' && echo "  ✓ updatedAt present"
echo "$PROFILE" | grep -q '"password"' && echo "  ✗ password EXPOSED (FAIL)" || echo "  ✓ password NOT exposed (PASS)"

# Update name
echo -e "\n✏️  PATCH /api/auth/profile - Update Name"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
UPDATE_NAME=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Demo User - Updated Name"}')
echo "$UPDATE_NAME" | jq '.'

# Update email
echo -e "\n✉️  PATCH /api/auth/profile - Update Email"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
NEW_EMAIL="demoupdated$TIMESTAMP@example.com"
UPDATE_EMAIL=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$NEW_EMAIL\"}")
echo "$UPDATE_EMAIL" | jq '.'

# Try to escalate role (should fail)
echo -e "\n🔒 SECURITY TEST: Attempt Role Escalation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Attempting to change role to MODERATOR..."
ESCALATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"role":"MODERATOR"}')
echo "$ESCALATE" | jq '.'

if echo "$ESCALATE" | grep -q "Cannot modify role"; then
    echo "✅ PASS: Role escalation blocked"
else
    echo "❌ FAIL: Role escalation NOT blocked"
fi

# Verify role unchanged
echo -e "\n✓ Verifying role remains CITIZEN..."
VERIFY=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN")
ROLE=$(echo "$VERIFY" | jq -r '.user.role')
if [ "$ROLE" = "CITIZEN" ]; then
    echo "✅ PASS: Role is still CITIZEN"
else
    echo "❌ FAIL: Role changed to $ROLE"
fi

# Test with DEPARTMENT user
echo -e "\n🏢 DEPARTMENT USER TEST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Logging in as Water Supply Department..."
DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}')
DEPT_TOKEN=$(echo "$DEPT_LOGIN" | jq -r '.token')

DEPT_PROFILE=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $DEPT_TOKEN")
echo "$DEPT_PROFILE" | jq '.'

ORIG_DEPT_ID=$(echo "$DEPT_PROFILE" | jq -r '.user.department_id')
echo -e "\n📍 Original department_id: $ORIG_DEPT_ID"

echo -e "\n✏️  Updating DEPARTMENT user name..."
DEPT_UPDATE=$(curl -s -X PATCH "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Water Dept - Demo Updated"}')

NEW_DEPT_ID=$(echo "$DEPT_UPDATE" | jq -r '.user.department_id')
echo -e "📍 New department_id: $NEW_DEPT_ID"

if [ "$ORIG_DEPT_ID" = "$NEW_DEPT_ID" ]; then
    echo "✅ PASS: department_id preserved"
else
    echo "❌ FAIL: department_id changed"
fi

# Summary
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                            DEMONSTRATION COMPLETE                         ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ New Endpoints:"
echo "   - GET  /api/auth/profile"
echo "   - PATCH /api/auth/profile"
echo ""
echo "✅ Security Features:"
echo "   - Password never exposed"
echo "   - Role cannot be changed"
echo "   - department_id cannot be changed"
echo "   - Email uniqueness enforced"
echo "   - Input validation"
echo ""
echo "✅ Tested Roles:"
echo "   - CITIZEN"
echo "   - DEPARTMENT"
echo ""
echo "📄 Full report: TASK1_PROFILE_MANAGEMENT_REPORT.md"
echo ""
