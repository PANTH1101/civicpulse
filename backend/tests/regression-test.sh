#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "========================================="
echo "REGRESSION TEST - EXISTING AUTH ENDPOINTS"
echo "========================================="

PASSED=0
FAILED=0

# Test 1: POST /api/auth/register still works
echo -e "\n[TEST] POST /api/auth/register..."
REG_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Regression Test\",\"email\":\"regression$(date +%s)@example.com\",\"password\":\"password123\"}")
REG_STATUS=$(echo "$REG_RESPONSE" | tail -n 1)

if [ "$REG_STATUS" = "201" ]; then
    echo "✅ PASS: Register works"
    ((PASSED++))
else
    echo "❌ FAIL: Register (expected 201, got $REG_STATUS)"
    ((FAILED++))
fi

# Test 2: POST /api/auth/login still works
echo -e "\n[TEST] POST /api/auth/login..."
LOGIN_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}')
LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | tail -n 1)

if [ "$LOGIN_STATUS" = "200" ]; then
    echo "✅ PASS: Login works"
    ((PASSED++))
    TOKEN=$(echo "$LOGIN_RESPONSE" | head -n 1 | jq -r '.token')
else
    echo "❌ FAIL: Login (expected 200, got $LOGIN_STATUS)"
    ((FAILED++))
    exit 1
fi

# Test 3: GET /api/auth/protected still works
echo -e "\n[TEST] GET /api/auth/protected..."
PROTECTED_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/protected" \
    -H "Authorization: Bearer $TOKEN")
PROTECTED_STATUS=$(echo "$PROTECTED_RESPONSE" | tail -n 1)

if [ "$PROTECTED_STATUS" = "200" ]; then
    echo "✅ PASS: Protected route works"
    ((PASSED++))
else
    echo "❌ FAIL: Protected route (expected 200, got $PROTECTED_STATUS)"
    ((FAILED++))
fi
    
# Test 4: Sample issue endpoint still works
echo -e "\n[TEST] GET /api/issues/my-issues..."
ISSUES_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $TOKEN")
ISSUES_STATUS=$(echo "$ISSUES_RESPONSE" | tail -n 1)

if [ "$ISSUES_STATUS" = "200" ]; then
    echo "✅ PASS: Issues endpoint works"
    ((PASSED++))
else
    echo "❌ FAIL: Issues endpoint (expected 200, got $ISSUES_STATUS)"
    ((FAILED++))
fi

# Test 5: Sample department endpoint still works
echo -e "\n[TEST] GET /api/departments/me..."
DEPT_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $TOKEN")
DEPT_STATUS=$(echo "$DEPT_RESPONSE" | tail -n 1)

if [ "$DEPT_STATUS" = "200" ]; then
    echo "✅ PASS: Department endpoint works"
    ((PASSED++))
else
    echo "❌ FAIL: Department endpoint (expected 200, got $DEPT_STATUS)"
    ((FAILED++))
fi

# Test 6: Sample notification endpoint still works
echo -e "\n[TEST] GET /api/notifications..."
NOTIF_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $TOKEN")
NOTIF_STATUS=$(echo "$NOTIF_RESPONSE" | tail -n 1)

if [ "$NOTIF_STATUS" = "200" ]; then
    echo "✅ PASS: Notifications endpoint works"
    ((PASSED++))
else
    echo "❌ FAIL: Notifications endpoint (expected 200, got $NOTIF_STATUS)"
    ((FAILED++))
fi

# Test 7: Sample services endpoint still works
echo -e "\n[TEST] GET /api/services..."
SERVICES_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/services" \
    -H "Authorization: Bearer $TOKEN")
SERVICES_STATUS=$(echo "$SERVICES_RESPONSE" | tail -n 1)

if [ "$SERVICES_STATUS" = "200" ]; then
    echo "✅ PASS: Services endpoint works"
    ((PASSED++))
else
    echo "❌ FAIL: Services endpoint (expected 200, got $SERVICES_STATUS)"
    ((FAILED++))
fi

# Test 8: Sample feedback endpoint still works
echo -e "\n[TEST] GET /api/feedback/my..."
FEEDBACK_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/feedback/my" \
    -H "Authorization: Bearer $TOKEN")
FEEDBACK_STATUS=$(echo "$FEEDBACK_RESPONSE" | tail -n 1)

if [ "$FEEDBACK_STATUS" = "200" ]; then
    echo "✅ PASS: Feedback endpoint works"
    ((PASSED++))
else
    echo "❌ FAIL: Feedback endpoint (expected 200, got $FEEDBACK_STATUS)"
    ((FAILED++))
fi

# Test 9: Sample public notices endpoint still works
echo -e "\n[TEST] GET /api/notices..."
NOTICES_RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notices" \
    -H "Authorization: Bearer $TOKEN")
NOTICES_STATUS=$(echo "$NOTICES_RESPONSE" | tail -n 1)

if [ "$NOTICES_STATUS" = "200" ]; then
    echo "✅ PASS: Public notices endpoint works"
    ((PASSED++))
else
    echo "❌ FAIL: Public notices endpoint (expected 200, got $NOTICES_STATUS)"
    ((FAILED++))
fi

echo -e "\n========================================="
echo "REGRESSION TEST RESULTS"
echo "========================================="
echo "Total: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
if [ $FAILED -eq 0 ]; then
    echo "✅ Failed: $FAILED"
else
    echo "❌ Failed: $FAILED"
fi
echo "========================================="

if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
