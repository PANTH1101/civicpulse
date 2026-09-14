#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "============================================="
echo "TASK 12 - FINAL CIVICPULSE BACKEND AUDIT"
echo "============================================="

PASSED=0
FAILED=0

# Setup: Create and login users
echo -e "\n[SETUP] Creating and logging in test users..."

# Register a new citizen for fresh testing
CITIZEN_REG=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Final Test Citizen\",\"email\":\"finaltest$(date +%s)@example.com\",\"password\":\"password123\"}")
CITIZEN_EMAIL=$(echo "$CITIZEN_REG" | jq -r '.user.email')

CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}")
CITIZEN_TOKEN=$(echo "$CITIZEN_LOGIN" | jq -r '.token')
CITIZEN_ID=$(echo "$CITIZEN_LOGIN" | jq -r '.user.id')

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

if [ "$CITIZEN_TOKEN" = "null" ]; then echo "❌ Citizen setup failed"; exit 1; fi
if [ "$MODERATOR_TOKEN" = "null" ]; then echo "❌ Moderator setup failed"; exit 1; fi
if [ "$DEPT_TOKEN" = "null" ]; then echo "❌ Department setup failed"; exit 1; fi

echo "✅ Users ready"

# Get IDs
DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" -H "Authorization: Bearer $DEPT_TOKEN")
DEPT_ID=$(echo "$DEPT_INFO" | jq -r '.department.id')

OTHER_DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
OTHER_DEPT_ID=$(echo "$OTHER_DEPT_INFO" | jq -r '.department.id')

SERVICES=$(curl -s -X GET "$BASE_URL/services" -H "Authorization: Bearer $CITIZEN_TOKEN")
SERVICE_ID=$(echo "$SERVICES" | jq -r '.services[0].id')

echo "✅ Test environment ready"

echo -e "\n============================================="
echo "R1 - USER MANAGEMENT AUDIT"
echo "============================================="

# TEST 1: Registration works
echo -e "\n[TEST 1] User registration..."
TEST_USER=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test User\",\"email\":\"test$(date +%s)@example.com\",\"password\":\"password123\"}")
STATUS=$(echo "$TEST_USER" | tail -n 1)

if [ "$STATUS" = "201" ]; then
    echo "✅ PASS: Registration works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 2: Login works
echo -e "\n[TEST 2] User login..."
if [ "$CITIZEN_TOKEN" != "null" ]; then
    echo "✅ PASS: Login works"
    ((PASSED++))
else
    echo "❌ FAIL: Login failed"
    ((FAILED++))
fi

# TEST 3: JWT authentication
echo -e "\n[TEST 3] JWT authentication..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/auth/protected" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: JWT authentication works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 4: Profile viewing
echo -e "\n[TEST 4] Profile viewing (GET /api/v1/users/:id)..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/users/$CITIZEN_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    PASSWORD=$(echo "$BODY" | jq -r '.user.password')
    if [ "$PASSWORD" = "null" ]; then
        echo "✅ PASS: Profile viewing works, password not returned"
        ((PASSED++))
    else
        echo "❌ FAIL: Password exposed in response"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 5: Profile updating
echo -e "\n[TEST 5] Profile updating..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/v1/users/$CITIZEN_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"name":"Updated Name"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Profile updating works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 6: Role cannot be changed
echo -e "\n[TEST 6] Role cannot be changed by user..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PUT "$BASE_URL/v1/users/$CITIZEN_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"role":"MODERATOR"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Role change blocked"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 7: No token returns 401
echo -e "\n[TEST 7] No token returns 401..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/users/$CITIZEN_ID")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: Unauthorized access rejected"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "R2 - CIVIC ISSUE MANAGEMENT AUDIT"
echo "============================================="

# TEST 8: Citizen reports issue
echo -e "\n[TEST 8] Citizen reports civic issue..."
ISSUE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Issue","description":"Test description","category":"WATER","location":"Test Location"}')
STATUS=$(echo "$ISSUE_RESPONSE" | tail -n 1)
BODY=$(echo "$ISSUE_RESPONSE" | sed '$d')

if [ "$STATUS" = "201" ]; then
    ISSUE_ID=$(echo "$BODY" | jq -r '.issue.id')
    ISSUE_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    
    if [ "$ISSUE_STATUS" = "REPORTED" ]; then
        echo "✅ PASS: Issue reported (status=REPORTED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status (got $ISSUE_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 9: Moderator views pending queue
echo -e "\n[TEST 9] Moderator views pending queue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator/pending" \
    -H "Authorization: Bearer $MODERATOR_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Moderator can view pending queue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 10: Moderator approves and assigns department
echo -e "\n[TEST 10] Moderator approves + assigns department..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"decision\":\"Approved\",\"departmentId\":\"$DEPT_ID\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    if [ "$NEW_STATUS" = "ASSIGNED" ]; then
        echo "✅ PASS: Issue approved and assigned (REPORTED → ASSIGNED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 11: Department starts issue
echo -e "\n[TEST 11] Department starts issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    if [ "$NEW_STATUS" = "IN_PROGRESS" ]; then
        echo "✅ PASS: Issue started (ASSIGNED → IN_PROGRESS)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 12: Department resolves with evidence
echo -e "\n[TEST 12] Department resolves issue with evidence..."
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
echo "$TEST_IMAGE" | base64 -d > /tmp/test_evidence.png

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed the issue" \
    -F "evidence=@/tmp/test_evidence.png")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    EVIDENCE=$(echo "$BODY" | jq -r '.issue.resolution_evidence')
    
    if [ "$NEW_STATUS" = "RESOLVED" ] && [ "$EVIDENCE" != "null" ]; then
        echo "✅ PASS: Issue resolved with evidence (IN_PROGRESS → RESOLVED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status=$NEW_STATUS, Evidence=$EVIDENCE"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

rm -f /tmp/test_evidence.png

# TEST 13: Citizen submits feedback for resolved issue
echo -e "\n[TEST 13] Citizen submits feedback for resolved issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"issue_id\":\"$ISSUE_ID\",\"rating\":5,\"comment\":\"Great work\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "201" ]; then
    echo "✅ PASS: Feedback submitted for resolved issue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 14: Department isolation for civic issues
echo -e "\n[TEST 14] Department isolation for civic issues..."
ISSUE2_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test 2","description":"Test","category":"ROADS","location":"Test"}')
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
echo "R3 - MUNICIPAL SERVICE MANAGEMENT AUDIT"
echo "============================================="

# TEST 15: Citizen submits service request (explicit dept selection)
echo -e "\n[TEST 15] Citizen submits service request..."
SR_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test request\"}")
STATUS=$(echo "$SR_RESPONSE" | tail -n 1)
BODY=$(echo "$SR_RESPONSE" | sed '$d')

if [ "$STATUS" = "201" ]; then
    SR_ID=$(echo "$BODY" | jq -r '.serviceRequest.id')
    SR_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    
    if [ "$SR_STATUS" = "PENDING" ]; then
        echo "✅ PASS: Service request submitted (status=PENDING)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status (got $SR_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 16: Department accepts service request
echo -e "\n[TEST 16] Department accepts service request..."
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

# TEST 17: Department starts service request
echo -e "\n[TEST 17] Department starts service request..."
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

# TEST 18: Department completes service request
echo -e "\n[TEST 18] Department completes service request..."
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

# TEST 19: Citizen submits feedback for completed service request
echo -e "\n[TEST 19] Citizen submits feedback for completed service..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests/$SR_ID/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rating":5,"comment":"Excellent"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "201" ]; then
    echo "✅ PASS: Service feedback submitted"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 20: Department isolation for service requests
echo -e "\n[TEST 20] Department isolation for service requests..."
SR2_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test\"}")
SR2_ID=$(echo "$SR2_RESPONSE" | jq -r '.serviceRequest.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR2_ID/accept" \
    -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Department isolation enforced"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "R4 - PUBLIC NOTICES AUDIT"
echo "============================================="

# TEST 21: Department creates notice
echo -e "\n[TEST 21] Department creates public notice..."
NOTICE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/notices" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test Notice","content":"Notice content","category":"GENERAL"}')
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

# TEST 22: Department publishes notice
echo -e "\n[TEST 22] Department publishes notice..."
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

# TEST 23: Citizens see published notices
echo -e "\n[TEST 23] Citizens can view published notices..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notices" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Published notices visible to citizens"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 24: Citizen cannot create notice
echo -e "\n[TEST 24] Citizen cannot create notice..."
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
echo "R5 - FEEDBACK AUDIT"
echo "============================================="

# TEST 25: Duplicate feedback prevented
echo -e "\n[TEST 25] Duplicate feedback prevented..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"issue_id\":\"$ISSUE_ID\",\"rating\":4}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "409" ]; then
    echo "✅ PASS: Duplicate feedback prevented"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 409, got $STATUS"
    ((FAILED++))
fi

# TEST 26: Rating validation
echo -e "\n[TEST 26] Rating validation (1-5)..."
ISSUE3_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test 3","description":"Test","category":"WATER","location":"Test"}')
ISSUE3_ID=$(echo "$ISSUE3_RESPONSE" | jq -r '.issue.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"issue_id\":\"$ISSUE3_ID\",\"rating\":6}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Rating validation works"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

echo -e "\n============================================="
echo "R6 - NOTIFICATIONS AUDIT"
echo "============================================="

# TEST 27: Notifications viewable
echo -e "\n[TEST 27] User can view notifications..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Notifications viewable"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 28: Mark notification as read
echo -e "\n[TEST 28] Mark notification as read..."
NOTIFS=$(curl -s -X GET "$BASE_URL/notifications" -H "Authorization: Bearer $CITIZEN_TOKEN")
NOTIF_ID=$(echo "$NOTIFS" | jq -r '.notifications[0].id')

if [ "$NOTIF_ID" != "null" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/notifications/$NOTIF_ID/read" \
        -H "Authorization: Bearer $CITIZEN_TOKEN")
    STATUS=$(echo "$RESPONSE" | tail -n 1)
    
    if [ "$STATUS" = "200" ]; then
        echo "✅ PASS: Mark notification as read works"
        ((PASSED++))
    else
        echo "❌ FAIL: Expected 200, got $STATUS"
        ((FAILED++))
    fi
else
    echo "⚠️  SKIP: No notifications available"
fi

echo -e "\n============================================="
echo "R7 - DEPARTMENT MANAGEMENT AUDIT"
echo "============================================="

# TEST 29: Department views profile
echo -e "\n[TEST 29] Department views profile..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department can view profile"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 30: Department views assigned issues
echo -e "\n[TEST 30] Department views assigned civic issues..."
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

# TEST 31: Department views service requests
echo -e "\n[TEST 31] Department views service requests..."
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

echo -e "\n============================================="
echo "SECURITY AUDIT"
echo "============================================="

# TEST 32: Citizen blocked from moderator action
echo -e "\n[TEST 32] Citizen blocked from moderator action..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator/pending" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen blocked from moderator action"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 33: Citizen blocked from department action
echo -e "\n[TEST 33] Citizen blocked from department action..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen blocked from department action"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 34: User A cannot access User B's resource
echo -e "\n[TEST 34] User A cannot access User B's resource..."
OTHER_CITIZEN_REG=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Other User\",\"email\":\"other$(date +%s)@example.com\",\"password\":\"password123\"}")
OTHER_CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$(echo $OTHER_CITIZEN_REG | jq -r '.user.email')\",\"password\":\"password123\"}")
OTHER_CITIZEN_TOKEN=$(echo "$OTHER_CITIZEN_LOGIN" | jq -r '.token')
OTHER_CITIZEN_ID=$(echo "$OTHER_CITIZEN_LOGIN" | jq -r '.user.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/v1/users/$OTHER_CITIZEN_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: User A blocked from User B's profile"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 35: Password never returned
echo -e "\n[TEST 35] Password never returned in profile..."
RESPONSE=$(curl -s -X GET "$BASE_URL/v1/users/$CITIZEN_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
PASSWORD=$(echo "$RESPONSE" | jq -r '.user.password')

if [ "$PASSWORD" = "null" ]; then
    echo "✅ PASS: Password never returned"
    ((PASSED++))
else
    echo "❌ FAIL: Password exposed in response"
    ((FAILED++))
fi

# Summary
echo -e "\n============================================="
echo "FINAL AUDIT TEST SUMMARY"
echo "============================================="
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"
echo "TOTAL: $((PASSED + FAILED))"
echo "============================================="

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL FINAL AUDIT TESTS PASSED!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    exit 1
fi
