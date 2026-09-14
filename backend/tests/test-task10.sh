#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "========================================="
echo "TASK 10 - VERIFICATION + ASSIGNMENT TEST"
echo "========================================="

PASSED=0
FAILED=0

# Login as citizen
echo -e "\n[SETUP] Login as citizen..."
CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"john@example.com","password":"password123"}')
CITIZEN_TOKEN=$(echo "$CITIZEN_LOGIN" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ] || [ -z "$CITIZEN_TOKEN" ]; then
    echo "❌ Failed to login as citizen"
    exit 1
fi
echo "✅ Citizen logged in"

# Login as moderator
echo -e "\n[SETUP] Login as moderator..."
MODERATOR_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"moderator@test.com","password":"password123"}')
MODERATOR_TOKEN=$(echo "$MODERATOR_LOGIN" | jq -r '.token')

if [ "$MODERATOR_TOKEN" = "null" ] || [ -z "$MODERATOR_TOKEN" ]; then
    echo "❌ Failed to login as moderator"
    exit 1
fi
echo "✅ Moderator logged in"

# Login as department user
echo -e "\n[SETUP] Login as department user..."
DEPARTMENT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}')
DEPARTMENT_TOKEN=$(echo "$DEPARTMENT_LOGIN" | jq -r '.token')

if [ "$DEPARTMENT_TOKEN" = "null" ] || [ -z "$DEPARTMENT_TOKEN" ]; then
    echo "❌ Failed to login as department user"
    exit 1
fi
echo "✅ Department user logged in"

# Get department ID
echo -e "\n[SETUP] Get department ID..."
DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN")
DEPARTMENT_ID=$(echo "$DEPT_INFO" | jq -r '.department.id')

if [ "$DEPARTMENT_ID" = "null" ] || [ -z "$DEPARTMENT_ID" ]; then
    echo "❌ Failed to get department ID"
    exit 1
fi
echo "✅ Department ID: $DEPARTMENT_ID"

# Create a test issue
echo -e "\n[SETUP] Create test issue..."
ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Task10 Test Issue","description":"Testing verification and assignment","category":"WATER","location":"Test Location"}')
ISSUE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.issue.id')

if [ "$ISSUE_ID" = "null" ] || [ -z "$ISSUE_ID" ]; then
    echo "❌ Failed to create issue"
    exit 1
fi
echo "✅ Issue created: $ISSUE_ID"

# TEST 1: Unauthenticated verify → 401
echo -e "\n[TEST 1] Unauthenticated verify..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "401" ]; then
    echo "✅ PASS: Unauthenticated verify blocked (401)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 401, got $STATUS"
    ((FAILED++))
fi

# TEST 2: Citizen verify → 403
echo -e "\n[TEST 2] Citizen verify..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen verify blocked (403)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 3: Department verify → 403
echo -e "\n[TEST 3] Department verify..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Department verify blocked (403)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 4: Approved without departmentId → 400
echo -e "\n[TEST 4] Approved without departmentId..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Approved without departmentId blocked (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 5: Invalid decision → 400
echo -e "\n[TEST 5] Invalid decision..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Maybe","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Invalid decision blocked (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 6: Invalid departmentId → 400
echo -e "\n[TEST 6] Invalid departmentId..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"507f1f77bcf86cd799439011"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Invalid departmentId blocked (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 7: Moderator approved verification → 200
echo -e "\n[TEST 7] Moderator approved verification..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    ISSUE_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    VERIFIED_BY=$(echo "$BODY" | jq -r '.issue.verifiedBy.id')
    DEPT_ID=$(echo "$BODY" | jq -r '.issue.department.id')
    
    if [ "$ISSUE_STATUS" = "ASSIGNED" ] && [ "$DEPT_ID" = "$DEPARTMENT_ID" ] && [ "$VERIFIED_BY" != "null" ]; then
        echo "✅ PASS: Approved verification works (status=ASSIGNED, department set, verifiedBy set)"
        ((PASSED++))
    else
        echo "❌ FAIL: Approved verification incomplete (status=$ISSUE_STATUS, dept=$DEPT_ID, verified=$VERIFIED_BY)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 8: Already verified issue → 400
echo -e "\n[TEST 8] Already verified issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Already verified issue blocked (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 9: Rejected issue → 200
echo -e "\n[TEST 9] Rejected issue..."
ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Task10 Reject Test","description":"Testing rejection","category":"ROADS","location":"Test Location"}')
REJECT_ISSUE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.issue.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$REJECT_ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Rejected","remarks":"Does not meet requirements"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    ISSUE_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    VERIFIED_BY=$(echo "$BODY" | jq -r '.issue.verifiedBy.id')
    
    if [ "$ISSUE_STATUS" = "REJECTED" ] && [ "$VERIFIED_BY" != "null" ]; then
        echo "✅ PASS: Rejected issue works (status=REJECTED, verifiedBy set)"
        ((PASSED++))
    else
        echo "❌ FAIL: Rejected issue incomplete (status=$ISSUE_STATUS, verified=$VERIFIED_BY)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 10: Rejected issue cannot be verified again
echo -e "\n[TEST 10] Rejected issue cannot be verified again..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$REJECT_ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Already verified (rejected) issue blocked (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 11: Citizen receives ISSUE_VERIFIED notification
echo -e "\n[TEST 11] Citizen receives ISSUE_VERIFIED notification..."
NOTIF_RESPONSE=$(curl -s -X GET "$BASE_URL/notifications?limit=50" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
VERIFIED_NOTIF=$(echo "$NOTIF_RESPONSE" | jq -r '.notifications[] | select(.type == "ISSUE_VERIFIED" and .issue.id == "'$ISSUE_ID'") | .type')

if [ "$VERIFIED_NOTIF" = "ISSUE_VERIFIED" ]; then
    echo "✅ PASS: Citizen received ISSUE_VERIFIED notification"
    ((PASSED++))
else
    echo "❌ FAIL: Citizen did not receive ISSUE_VERIFIED notification"
    ((FAILED++))
fi

# TEST 12: Department receives ISSUE_ASSIGNED notification
echo -e "\n[TEST 12] Department receives ISSUE_ASSIGNED notification..."
NOTIF_RESPONSE=$(curl -s -X GET "$BASE_URL/notifications?limit=50" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN")
ASSIGNED_NOTIF=$(echo "$NOTIF_RESPONSE" | jq -r '.notifications[] | select(.type == "ISSUE_ASSIGNED" and .issue.id == "'$ISSUE_ID'") | .type')

if [ "$ASSIGNED_NOTIF" = "ISSUE_ASSIGNED" ]; then
    echo "✅ PASS: Department received ISSUE_ASSIGNED notification"
    ((PASSED++))
else
    echo "❌ FAIL: Department did not receive ISSUE_ASSIGNED notification"
    ((FAILED++))
fi

# TEST 13: Rejected citizen receives ISSUE_REJECTED notification
echo -e "\n[TEST 13] Rejected citizen receives ISSUE_REJECTED notification..."
NOTIF_RESPONSE=$(curl -s -X GET "$BASE_URL/notifications?limit=50" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
REJECTED_NOTIF=$(echo "$NOTIF_RESPONSE" | jq -r '.notifications[] | select(.type == "ISSUE_REJECTED" and .issue.id == "'$REJECT_ISSUE_ID'") | .type')

if [ "$REJECTED_NOTIF" = "ISSUE_REJECTED" ]; then
    echo "✅ PASS: Citizen received ISSUE_REJECTED notification"
    ((PASSED++))
else
    echo "❌ FAIL: Citizen did not receive ISSUE_REJECTED notification"
    ((FAILED++))
fi

# TEST 14: Pending queue removes approved issue
echo -e "\n[TEST 14] Pending queue removes approved issue..."
PENDING_RESPONSE=$(curl -s -X GET "$BASE_URL/issues/moderator/pending?limit=50" \
    -H "Authorization: Bearer $MODERATOR_TOKEN")
FOUND_APPROVED=$(echo "$PENDING_RESPONSE" | jq -r '.issues[] | select(.id == "'$ISSUE_ID'") | .id')

if [ -z "$FOUND_APPROVED" ] || [ "$FOUND_APPROVED" = "null" ]; then
    echo "✅ PASS: Approved issue removed from pending queue"
    ((PASSED++))
else
    echo "❌ FAIL: Approved issue still in pending queue"
    ((FAILED++))
fi

# TEST 15: Pending queue removes rejected issue
echo -e "\n[TEST 15] Pending queue removes rejected issue..."
PENDING_RESPONSE=$(curl -s -X GET "$BASE_URL/issues/moderator/pending?limit=50" \
    -H "Authorization: Bearer $MODERATOR_TOKEN")
FOUND_REJECTED=$(echo "$PENDING_RESPONSE" | jq -r '.issues[] | select(.id == "'$REJECT_ISSUE_ID'") | .id')

if [ -z "$FOUND_REJECTED" ] || [ "$FOUND_REJECTED" = "null" ]; then
    echo "✅ PASS: Rejected issue removed from pending queue"
    ((PASSED++))
else
    echo "❌ FAIL: Rejected issue still in pending queue"
    ((FAILED++))
fi

# TEST 16: Old /assign cannot bypass verification
echo -e "\n[TEST 16] Old /assign cannot bypass verification..."
UNVERIFIED_ISSUE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Task10 Unverified","description":"Testing assign without verify","category":"ELECTRICITY","location":"Test Location"}')
UNVERIFIED_ID=$(echo "$UNVERIFIED_ISSUE" | jq -r '.issue.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$UNVERIFIED_ID/assign" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"department_id":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Old /assign endpoint requires verification (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 17: Department can start assigned issue
echo -e "\n[TEST 17] Department can start assigned issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    ISSUE_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    if [ "$ISSUE_STATUS" = "IN_PROGRESS" ]; then
        echo "✅ PASS: Department started issue (status=IN_PROGRESS)"
        ((PASSED++))
    else
        echo "❌ FAIL: Issue status not IN_PROGRESS (got $ISSUE_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 18: Missing decision → 400
echo -e "\n[TEST 18] Missing decision..."
MISSING_ISSUE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Task10 Missing Decision","description":"Testing missing decision","category":"SANITATION","location":"Test Location"}')
MISSING_ID=$(echo "$MISSING_ISSUE" | jq -r '.issue.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$MISSING_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Missing decision blocked (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 19: Cannot verify non-REPORTED issue
echo -e "\n[TEST 19] Cannot verify non-REPORTED issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Cannot verify non-REPORTED issue (400)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 20: Verify workflow preserves existing functionality
echo -e "\n[TEST 20] Verify complete workflow..."
WORKFLOW_ISSUE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Task10 Complete Workflow","description":"Testing complete workflow","category":"WATER","location":"Test Location"}')
WORKFLOW_ID=$(echo "$WORKFLOW_ISSUE" | jq -r '.issue.id')

# Verify and assign
curl -s -X PATCH "$BASE_URL/issues/$WORKFLOW_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Approved","departmentId":"'$DEPARTMENT_ID'"}' > /dev/null

# Start
curl -s -X PATCH "$BASE_URL/issues/$WORKFLOW_ID/start" \
    -H "Authorization: Bearer $DEPARTMENT_TOKEN" > /dev/null

# Check status
CHECK_RESPONSE=$(curl -s -X GET "$BASE_URL/issues/$WORKFLOW_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
WORKFLOW_STATUS=$(echo "$CHECK_RESPONSE" | jq -r '.issue.status')

if [ "$WORKFLOW_STATUS" = "IN_PROGRESS" ]; then
    echo "✅ PASS: Complete workflow works (REPORTED → ASSIGNED → IN_PROGRESS)"
    ((PASSED++))
else
    echo "❌ FAIL: Workflow failed (status=$WORKFLOW_STATUS)"
    ((FAILED++))
fi

# Summary
echo -e "\n========================================="
echo "TEST SUMMARY"
echo "========================================="
echo "✅ PASSED: $PASSED"
echo "❌ FAILED: $FAILED"
echo "TOTAL: $((PASSED + FAILED))"
echo "========================================="

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    exit 0
else
    echo "⚠️  SOME TESTS FAILED"
    exit 1
fi
