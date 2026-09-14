#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "============================================="
echo "TASK 11.3 - CIVIC ISSUE MANAGEMENT TEST"
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

if [ "$CITIZEN_TOKEN" = "null" ]; then echo "❌ Citizen login failed"; exit 1; fi
if [ "$MODERATOR_TOKEN" = "null" ]; then echo "❌ Moderator login failed"; exit 1; fi
if [ "$DEPT_TOKEN" = "null" ]; then echo "❌ Department login failed"; exit 1; fi

echo "✅ Users logged in"

# Get department ID
DEPT_INFO=$(curl -s -X GET "$BASE_URL/departments/me" \
    -H "Authorization: Bearer $DEPT_TOKEN")
DEPT_ID=$(echo "$DEPT_INFO" | jq -r '.department.id')

if [ "$DEPT_ID" = "null" ]; then echo "❌ Failed to get department ID"; exit 1; fi
echo "✅ Department ID: $DEPT_ID"

# TEST 1: Citizen reports issue without image
echo -e "\n[TEST 1] Citizen reports civic issue (no image)..."
ISSUE_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Broken streetlight","description":"Streetlight not working for 3 days","category":"PUBLIC_SAFETY","location":"Main St & 5th Ave"}')
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
    echo "Response: $BODY"
    ((FAILED++))
    exit 1
fi

# TEST 2: Only citizens can report issues
echo -e "\n[TEST 2] Non-citizen cannot report issues..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test","description":"Test desc","category":"ROADS","location":"Test loc"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Non-citizen blocked from reporting"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 3: Citizen can view their own issues
echo -e "\n[TEST 3] Citizen views own issues..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Citizen can view own issues"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 4: Citizen ownership - view single issue
echo -e "\n[TEST 4] Citizen can view own issue details..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/$ISSUE_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Citizen can view own issue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 5: Citizen cannot view another citizen's issue
echo -e "\n[TEST 5] Citizen cannot view another's issue..."
CITIZEN2_REG=$(curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Other Citizen\",\"email\":\"other$(date +%s)@example.com\",\"password\":\"password123\"}")
CITIZEN2_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$(echo $CITIZEN2_REG | jq -r '.user.email')\",\"password\":\"password123\"}")
CITIZEN2_TOKEN=$(echo "$CITIZEN2_LOGIN" | jq -r '.token')

RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/$ISSUE_ID" \
    -H "Authorization: Bearer $CITIZEN2_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Citizen blocked from viewing another's issue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 403, got $STATUS"
    ((FAILED++))
fi

# TEST 6: Moderator views pending moderation queue
echo -e "\n[TEST 6] Moderator views pending moderation queue..."
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

# TEST 7: Moderator views all issues
echo -e "\n[TEST 7] Moderator views all issues..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X GET "$BASE_URL/issues/moderator" \
    -H "Authorization: Bearer $MODERATOR_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "200" ]; then
    echo "✅ PASS: Moderator can view all issues"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 8: Moderator approves and assigns department (REPORTED → ASSIGNED)
echo -e "\n[TEST 8] Moderator approves issue with department assignment..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"decision\":\"Approved\",\"departmentId\":\"$DEPT_ID\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    ASSIGNED_DEPT=$(echo "$BODY" | jq -r '.issue.department.id')
    
    if [ "$NEW_STATUS" = "ASSIGNED" ] && [ "$ASSIGNED_DEPT" = "$DEPT_ID" ]; then
        echo "✅ PASS: Issue verified and assigned (REPORTED → ASSIGNED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Status=$NEW_STATUS, Dept=$ASSIGNED_DEPT"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    echo "Response: $BODY"
    ((FAILED++))
fi

# TEST 9: Moderator can reject issues
echo -e "\n[TEST 9] Moderator rejects an issue..."
ISSUE2_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test reject","description":"Test","category":"OTHER","location":"Test"}')
ISSUE2_ID=$(echo "$ISSUE2_RESPONSE" | jq -r '.issue.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE2_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"decision":"Rejected"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$STATUS" = "200" ]; then
    NEW_STATUS=$(echo "$BODY" | jq -r '.issue.status')
    if [ "$NEW_STATUS" = "REJECTED" ]; then
        echo "✅ PASS: Issue rejected (REPORTED → REJECTED)"
        ((PASSED++))
    else
        echo "❌ FAIL: Wrong status (got $NEW_STATUS)"
        ((FAILED++))
    fi
else
    echo "❌ FAIL: Expected 200, got $STATUS"
    ((FAILED++))
fi

# TEST 10: Department views assigned issues
echo -e "\n[TEST 10] Department views assigned issues..."
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

# TEST 11: Department starts issue (ASSIGNED → IN_PROGRESS)
echo -e "\n[TEST 11] Department starts work on issue..."
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

# TEST 12: Department resolves with evidence (IN_PROGRESS → RESOLVED)
echo -e "\n[TEST 12] Department resolves issue with evidence..."

# Create a test image file
TEST_IMAGE="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="
echo "$TEST_IMAGE" | base64 -d > /tmp/test_evidence.png

RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed the streetlight" \
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
    echo "Response: $BODY"
    ((FAILED++))
fi

rm -f /tmp/test_evidence.png

# TEST 13: Citizen submits feedback for resolved issue
echo -e "\n[TEST 13] Citizen submits feedback for resolved issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"issue_id\":\"$ISSUE_ID\",\"rating\":5,\"comment\":\"Great work!\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "201" ]; then
    echo "✅ PASS: Feedback submitted for resolved issue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 201, got $STATUS"
    ((FAILED++))
fi

# TEST 14: Cannot submit feedback for non-resolved issue
echo -e "\n[TEST 14] Cannot submit feedback for non-resolved issue..."
ISSUE3_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test feedback","description":"Test","category":"ROADS","location":"Test"}')
ISSUE3_ID=$(echo "$ISSUE3_RESPONSE" | jq -r '.issue.id')

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/feedback" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"issue_id\":\"$ISSUE3_ID\",\"rating\":5}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Feedback blocked for non-resolved issue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 15: Invalid status transition prevented
echo -e "\n[TEST 15] Invalid status transition prevented..."
ISSUE4_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test transition","description":"Test","category":"WATER","location":"Test"}')
ISSUE4_ID=$(echo "$ISSUE4_RESPONSE" | jq -r '.issue.id')

# Try to start without verifying
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE4_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ] || [ "$STATUS" = "403" ]; then
    echo "✅ PASS: Invalid transition prevented (cannot start unassigned)"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400/403, got $STATUS"
    ((FAILED++))
fi

# TEST 16: Department isolation
echo -e "\n[TEST 16] Department isolation..."
OTHER_DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"roads@civicpulse.gov","password":"department123"}')
OTHER_DEPT_TOKEN=$(echo "$OTHER_DEPT_LOGIN" | jq -r '.token')

if [ "$OTHER_DEPT_TOKEN" != "null" ]; then
    RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
        -H "Authorization: Bearer $OTHER_DEPT_TOKEN")
    STATUS=$(echo "$RESPONSE" | tail -n 1)
    
    if [ "$STATUS" = "403" ] || [ "$STATUS" = "400" ]; then
        echo "✅ PASS: Department cannot access another department's issue"
        ((PASSED++))
    else
        echo "❌ FAIL: Expected 403/400, got $STATUS"
        ((FAILED++))
    fi
else
    echo "⚠️  SKIP: Could not login as other department"
fi

# TEST 17: Required fields validation
echo -e "\n[TEST 17] Required fields validation..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Test"}')
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Missing required fields rejected"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# TEST 18: Cannot verify already verified issue
echo -e "\n[TEST 18] Cannot verify already verified issue..."
RESPONSE=$(curl -s -w "\n%{http_code}" -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"decision\":\"Approved\",\"departmentId\":\"$DEPT_ID\"}")
STATUS=$(echo "$RESPONSE" | tail -n 1)

if [ "$STATUS" = "400" ]; then
    echo "✅ PASS: Cannot verify already verified issue"
    ((PASSED++))
else
    echo "❌ FAIL: Expected 400, got $STATUS"
    ((FAILED++))
fi

# Summary
echo -e "\n============================================="
echo "TEST SUMMARY - TASK 11.3"
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
