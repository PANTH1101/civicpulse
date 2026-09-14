#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "============================================="
echo "TASK 11.4 - DEPARTMENT MANAGEMENT TEST"
echo "============================================="

PASSED=0
FAILED=0

# Setup: Login users
echo -e "\n[SETUP] Logging in users..."

CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"john@example.com","password":"password123"}')
CITIZEN_TOKEN=$(echo "$CITIZEN_LOGIN" | jq -r '.token')

MODERATOR_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"moderator@test.com","password":"password123"}')
MODERATOR_TOKEN=$(echo "$MODERATOR_LOGIN" | jq -r '.token')

DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}')
DEPT_TOKEN=$(echo "$DEPT_LOGIN" | jq -r '.token')

OTHER_DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"roads@civicpulse.gov","password":"department123"}')
OTHER_DEPT_TOKEN=$(echo "$OTHER_DEPT_LOGIN" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ]; then echo "❌ Citizen login failed"; exit 1; fi
if [ "$MODERATOR_TOKEN" = "null" ]; then echo "❌ Moderator login failed"; exit 1; fi
if [ "$DEPT_TOKEN" = "null" ]; then echo "❌ Department login failed"; exit 1; fi
if [ "$OTHER_DEPT_TOKEN" = "null" ]; then echo "❌ Other department login failed"; exit 1; fi

echo "✅ Users logged in"

# Get department IDs
DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT_TOKEN")
DEPT_ID=$(echo "$DEPT_INFO" | jq -r '.department.id')

OTHER_DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
OTHER_DEPT_ID=$(echo "$OTHER_DEPT_INFO" | jq -r '.department.id')

if [ "$DEPT_ID" = "null" ]; then echo "❌ Failed to get department ID"; exit 1; fi
if [ "$OTHER_DEPT_ID" = "null" ]; then echo "❌ Failed to get other department ID"; exit 1; fi
echo "✅ Department ID: $DEPT_ID"
echo "✅ Other Department ID: $OTHER_DEPT_ID"

# Get service ID
SERVICES=$(curl -s -X GET "$BASE_URL/services" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
SERVICE_ID=$(echo "$SERVICES" | jq -r '.services[0].id')

if [ "$SERVICE_ID" = "null" ]; then echo "❌ Failed to get service ID"; exit 1; fi
echo "✅ Service ID: $SERVICE_ID"

echo -e "\n============================================="
echo "A. DEPARTMENT PROFILE TESTS"
echo "============================================="

# TEST 1: Department user can view their profile
echo -e "\n[TEST 1] Department user views their profile..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department user can view profile"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 2: No token returns 401
echo -e "\n[TEST 2] No token returns 401..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: No token returns 401"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

# TEST 3: Citizen cannot access department profile endpoint
echo -e "\n[TEST 3] Citizen cannot access department profile..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen blocked from department profile"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "B. CIVIC ISSUE MANAGEMENT TESTS"
echo "============================================="

# Create and assign issue to department
ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Water leak","description":"Pipe burst","category":"WATER","location":"Test St"}')
ISSUE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.issue.id')

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"decision\":\"Approved\",\"departmentId\":\"$DEPT_ID\"}" > /dev/null

echo "✅ Test issue created and assigned: $ISSUE_ID"

# TEST 4: Department views assigned issues
echo -e "\n[TEST 4] Department views assigned issues..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department can view assigned issues"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 5: Department filters by status
echo -e "\n[TEST 5] Department filters issues by status..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/my-issues?status=ASSIGNED" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Status filtering works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 6: Department starts issue
echo -e "\n[TEST 6] Department starts assigned issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department started issue (ASSIGNED → IN_PROGRESS)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 7: Department resolves issue with evidence
echo -e "\n[TEST 7] Department resolves issue with evidence..."
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
echo "$TEST_IMAGE" | base64 -d > /tmp/test_evidence.png

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed the leak" \
    -F "evidence=@/tmp/test_evidence.png")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Issue resolved (IN_PROGRESS → RESOLVED)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

rm -f /tmp/test_evidence.png

# TEST 8: Other department cannot access this issue
echo -e "\n[TEST 8] Department isolation for civic issues..."
ISSUE2_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Road issue","description":"Pothole","category":"ROADS","location":"Test"}')
ISSUE2_ID=$(echo "$ISSUE2_RESPONSE" | jq -r '.issue.id')

curl -s -X PATCH "$BASE_URL/issues/$ISSUE2_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"decision\":\"Approved\",\"departmentId\":\"$DEPT_ID\"}" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE2_ID/start" \
    -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ] || [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Department isolation enforced"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403/400, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "C. SERVICE REQUEST MANAGEMENT TESTS"
echo "============================================="

# TEST 9: Citizen submits service request
echo -e "\n[TEST 9] Citizen submits service request to department..."
SR_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Need help\"}")
STATUS=$(echo "$SR_RESPONSE" | tail -n 1)
BODY=$(echo "$SR_RESPONSE" | sed '$d')

if [ "$STATUS" = "201" ]; then
    SR_ID=$(echo "$BODY" | jq -r '.serviceRequest.id')
    echo "✅ PASS: Service request submitted (status=PENDING)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    echo "Response: $BODY"
    ((FAILED++))
    exit 1
fi

# TEST 10: Department views service requests
echo -e "\n[TEST 10] Department views service requests..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department can view service requests"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 11: Department accepts service request
echo -e "\n[TEST 11] Department accepts service request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/accept" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Service request accepted (PENDING → ACCEPTED)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 12: Department starts service request
echo -e "\n[TEST 12] Department starts service request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Service request started (ACCEPTED → IN_PROGRESS)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 13: Department completes service request
echo -e "\n[TEST 13] Department completes service request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/complete" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Service request completed (IN_PROGRESS → COMPLETED)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 14: Department rejects service request
echo -e "\n[TEST 14] Department rejects service request..."
SR2_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test\"}")
SR2_ID=$(echo "$SR2_RESPONSE" | jq -r '.serviceRequest.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR2_ID/reject" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rejectionReason":"Cannot fulfill"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Service request rejected (PENDING → REJECTED)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 15: Rejection reason required
echo -e "\n[TEST 15] Rejection requires reason..."
SR3_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test\"}")
SR3_ID=$(echo "$SR3_RESPONSE" | jq -r '.serviceRequest.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR3_ID/reject" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Rejection reason required"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 16: Department isolation for service requests
echo -e "\n[TEST 16] Department isolation for service requests..."
SR4_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test\"}")
SR4_ID=$(echo "$SR4_RESPONSE" | jq -r '.serviceRequest.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR4_ID/accept" \
    -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Department isolation enforced"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 17: Invalid status transitions
echo -e "\n[TEST 17] Invalid status transitions prevented..."
SR5_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test\"}")
SR5_ID=$(echo "$SR5_RESPONSE" | jq -r '.serviceRequest.id')

# Try to start without accepting
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR5_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Invalid transition prevented (cannot start PENDING)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "D. PUBLIC NOTICE MANAGEMENT TESTS"
echo "============================================="

# TEST 18: Department creates public notice
echo -e "\n[TEST 18] Department creates public notice..."
NOTICE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/notices" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Water Maintenance","content":"Scheduled maintenance","category":"MAINTENANCE"}')
STATUS=$(echo "$NOTICE_RESPONSE" | tail -n 1)
BODY=$(echo "$NOTICE_RESPONSE" | sed '$d')

if [ "$STATUS" = "201" ]; then
    NOTICE_ID=$(echo "$BODY" | jq -r '.notice.id')
    NOTICE_STATUS=$(echo "$BODY" | jq -r '.notice.status')
    
    if [ "$NOTICE_STATUS" = "DRAFT" ]; then
        echo "✅ PASS: Notice created (status=DRAFT)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status (got $NOTICE_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 19: Department publishes notice
echo -e "\n[TEST 19] Department publishes notice..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/notices/$NOTICE_ID/publish" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Notice published (DRAFT → PUBLISHED)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 20: Published notice visible to citizens
echo -e "\n[TEST 20] Published notices visible to citizens..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notices" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Citizens can view published notices"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 21: Citizen cannot create notice
echo -e "\n[TEST 21] Citizen cannot create notice..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/notices" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test","content":"Test","category":"GENERAL"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen blocked from creating notice"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "E. NOTIFICATIONS TESTS"
echo "============================================="

# TEST 22: Department user can view notifications
echo -e "\n[TEST 22] Department receives notifications..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department can view notifications"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "F. SECURITY/AUTHORIZATION TESTS"
echo "============================================="

# TEST 23: Citizen cannot access department service requests
echo -e "\n[TEST 23] Citizen blocked from department service requests..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen blocked"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 24: Moderator cannot access department-only endpoints
echo -e "\n[TEST 24] Moderator blocked from department-only endpoints..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $MODERATOR_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ] || [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Moderator blocked"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403/400, got $STATUS"
    ((FAILED++))
fi

# Summary
echo -e "\n============================================="
echo "TEST SUMMARY - TASK 11.4"
echo "============================================="
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"
echo "TOTAL: $((PASSED + FAILED))"
echo "============================================="

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    exit 1
fi
