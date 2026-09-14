#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "============================================="
echo "TASK 11.2 - SERVICE REQUEST WORKFLOW TEST"
echo "============================================="

PASSED=0
FAILED=0

# Setup: Login users
echo -e "\n[SETUP] Logging in users..."
CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"john@example.com","password":"password123"}')
CITIZEN_TOKEN=$(echo "$CITIZEN_LOGIN" | jq -r '.token')
CITIZEN_ID=$(echo "$CITIZEN_LOGIN" | jq -r '.user.id')

DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}')
DEPT_TOKEN=$(echo "$DEPT_LOGIN" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ]; then echo "❌ Citizen login failed"; exit 1; fi
if [ "$DEPT_TOKEN" = "null" ]; then echo "❌ Department login failed"; exit 1; fi

echo "✅ Users logged in"

# Get department info
DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT_TOKEN")
DEPT_ID=$(echo "$DEPT_INFO" | jq -r '.department.id')

if [ "$DEPT_ID" = "null" ]; then echo "❌ Failed to get department ID"; exit 1; fi
echo "✅ Department ID: $DEPT_ID"

# Get a service
SERVICES=$(curl -s -X GET "$BASE_URL/services?limit=1" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
SERVICE_ID=$(echo "$SERVICES" | jq -r '.services[0].id')

if [ "$SERVICE_ID" = "null" ]; then echo "❌ No services available"; exit 1; fi
echo "✅ Service ID: $SERVICE_ID"

# TEST 1: Citizen can view services
echo -e "\n[TEST 1] Citizen can view predefined services..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/services" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Citizen can view services"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 2: Citizen submits service request with explicit service and department
echo -e "\n[TEST 2] Citizen submits service request (explicit service + department)..."
SR_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test request\"}")
STATUS=$(echo "$SR_RESPONSE" | tail -n 1)
BODY=$(echo "$SR_RESPONSE" | sed '$d')

if [ "$STATUS" = "201" ]; then
    SR_ID=$(echo "$BODY" | jq -r '.serviceRequest.id')
    SR_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    SR_DEPT=$(echo "$BODY" | jq -r '.serviceRequest.department.id')
    
    if [ "$SR_STATUS" = "PENDING" ] && [ "$SR_DEPT" = "$DEPT_ID" ]; then
        echo "✅ PASS: Service request created (status=PENDING, routed to correct department)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status or department (status=$SR_STATUS, dept=$SR_DEPT)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    echo "Response: $BODY"
    ((FAILED++))
    exit 1
fi

# TEST 3: Non-citizen cannot submit request
echo -e "\n[TEST 3] Non-citizen cannot submit service request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Non-citizen blocked from submitting"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 4: Department can view their requests
echo -e "\n[TEST 4] Department can view requests routed to them..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/departments/service-requests" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Department can view their requests"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 5: Citizen can view their own requests
echo -e "\n[TEST 5] Citizen can view their own requests..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/services/requests/my" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Citizen can view their requests"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 6: Department accepts request (PENDING → ACCEPTED)
echo -e "\n[TEST 6] Department accepts request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/accept" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    if [ "$NEW_STATUS" = "ACCEPTED" ]; then
        echo "✅ PASS: Request accepted (PENDING → ACCEPTED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status not updated (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 7: Department starts request (ACCEPTED → IN_PROGRESS)
echo -e "\n[TEST 7] Department starts request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    if [ "$NEW_STATUS" = "IN_PROGRESS" ]; then
        echo "✅ PASS: Request started (ACCEPTED → IN_PROGRESS)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status not updated (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 8: Department completes request (IN_PROGRESS → COMPLETED)
echo -e "\n[TEST 8] Department completes request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/complete" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    if [ "$NEW_STATUS" = "COMPLETED" ]; then
        echo "✅ PASS: Request completed (IN_PROGRESS → COMPLETED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status not updated (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 9: Citizen submits feedback for completed request
echo -e "\n[TEST 9] Citizen submits feedback for completed request..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests/$SR_ID/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rating":5,"comment":"Excellent service"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "201" ]; then
    echo "✅ PASS: Feedback submitted for completed request"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 10: Reject workflow - Create new request and reject it
echo -e "\n[TEST 10] Reject workflow (PENDING → REJECTED)..."
SR2_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\",\"notes\":\"Test reject\"}")
SR2_ID=$(echo "$SR2_RESPONSE" | jq -r '.serviceRequest.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR2_ID/reject" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"rejectionReason":"Not applicable"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    if [ "$NEW_STATUS" = "REJECTED" ]; then
        echo "✅ PASS: Request rejected (PENDING → REJECTED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status not updated (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 11: Invalid status transition (cannot accept already accepted)
echo -e "\n[TEST 11] Invalid status transition prevented..."
SR3_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\"}")
SR3_ID=$(echo "$SR3_RESPONSE" | jq -r '.serviceRequest.id')

curl -s -X PATCH "$BASE_URL/services/requests/$SR3_ID/accept" \
    -H "Authorization: Bearer $DEPT_TOKEN" > /dev/null

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR3_ID/accept" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Invalid transition prevented (cannot accept twice)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 12: Cancel pending request
echo -e "\n[TEST 12] Citizen cancels pending request..."
SR4_RESPONSE=$(curl -s -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"service_id\":\"$SERVICE_ID\",\"department_id\":\"$DEPT_ID\"}")
SR4_ID=$(echo "$SR4_RESPONSE" | jq -r '.serviceRequest.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR4_ID/cancel" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.serviceRequest.status')
    if [ "$NEW_STATUS" = "CANCELLED" ]; then
        echo "✅ PASS: Request cancelled (PENDING → CANCELLED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status not updated (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 13: Citizen ownership - cannot view another citizen's request
echo -e "\n[TEST 13] Citizen ownership isolation..."

# Create another citizen
CITIZEN2_REG=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Other Citizen\",\"email\":\"other$(date +%s)@example.com\",\"password\":\"password123\"}")
CITIZEN2_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$(echo $CITIZEN2_REG | jq -r '.user.email')\",\"password\":\"password123\"}")
CITIZEN2_TOKEN=$(echo "$CITIZEN2_LOGIN" | jq -r '.token')

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/services/requests/$SR_ID" \
    -H "Authorization: Bearer $CITIZEN2_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen cannot view another citizen's request"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 14: Department isolation - cannot access another department's request
echo -e "\n[TEST 14] Department isolation..."

# Get another department
DEPTS=$(curl -s -X GET "$BASE_URL/departments" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
OTHER_DEPT_ID=$(echo "$DEPTS" | jq -r ".departments[] | select(.id != \"$DEPT_ID\") | .id" | head -n 1)

if [ "$OTHER_DEPT_ID" != "" ] && [ "$OTHER_DEPT_ID" != "null" ]; then
    # Login as other department
    OTHER_DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
        -H "Content-Type: application/json" \
        -d '{"email":"roads@civicpulse.gov","password":"department123"}')
    OTHER_DEPT_TOKEN=$(echo "$OTHER_DEPT_LOGIN" | jq -r '.token')
    
    if [ "$OTHER_DEPT_TOKEN" != "null" ]; then
        RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/services/requests/$SR_ID/accept" \
            -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
        STATUS=$(echo "$RESPONSE" | tail -n 1)
        
        if [ "$STATUS" = "403" ]; then
            echo "✅ PASS: Department cannot access another department's request"
            ((PASSED++))
        else
            echo "❌ FAIL: Expected 403, got $STATUS"
            ((FAILED++))
        fi
    else
        echo "⚠️  SKIP: Could not login as other department"
    fi
else
    echo "⚠️  SKIP: No other department available"
fi

# TEST 15: Required fields validation
echo -e "\n[TEST 15] Required fields validation..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/services/requests" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"notes":"Missing required fields"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Missing required fields rejected"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# Summary
echo -e "\n============================================="
echo "TEST SUMMARY - TASK 11.2"
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
