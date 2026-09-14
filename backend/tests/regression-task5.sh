#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║              TASK 5 REGRESSION TEST - EXISTING ENDPOINTS                ║"
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

# Register and login
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Reg Test\",\"email\":\"reg${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"reg${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

echo -e "\n[TEST] POST /api/issues still works..."
RESP=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Regression Test" \
    -F "description=Test" \
    -F "category=ROADS" \
    -F "location=Test")

HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "201" ]; then
    test_pass "POST /api/issues works"
else
    test_fail "POST /api/issues (got $HTTP_CODE)"
fi

echo -e "\n[TEST] GET /api/issues/my-issues still works..."
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")

HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /api/issues/my-issues works"
else
    test_fail "GET /api/issues/my-issues (got $HTTP_CODE)"
fi

echo -e "\n[TEST] GET /api/auth/profile still works..."
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")

HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /api/auth/profile works"
else
    test_fail "GET /api/auth/profile (got $HTTP_CODE)"
fi

echo -e "\n[TEST] GET /api/notifications still works..."
RESP=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")

HTTP_CODE=$(echo "$RESP" | tail -n 1)

if [ "$HTTP_CODE" = "200" ]; then
    test_pass "GET /api/notifications works"
else
    test_fail "GET /api/notifications (got $HTTP_CODE)"
fi

echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                    REGRESSION TEST RESULTS                              ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
[ $FAILED -eq 0 ] && echo "✅ Failed: $FAILED" || echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "✅ ALL REGRESSION TESTS PASSED!"
    exit 0
else
    echo "❌ SOME REGRESSION TESTS FAILED"
    exit 1
fi
