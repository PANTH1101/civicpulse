#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 4: RESOLUTION EVIDENCE FILE UPLOAD TEST                     ║"
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

# =========================================================================
# SETUP: Create test users and data
# =========================================================================
echo -e "\n[SETUP] Creating test users..."

TIMESTAMP=$(date +%s)

# Create citizen
CITIZEN_EMAIL="citizen$TIMESTAMP@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Citizen\",\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

# Create moderator
MODERATOR_EMAIL="moderator$TIMESTAMP@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Moderator\",\"email\":\"$MODERATOR_EMAIL\",\"password\":\"password123\",\"role\":\"MODERATOR\"}" > /dev/null

MODERATOR_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$MODERATOR_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

# Create department 1
DEPT1_EMAIL="dept1_$TIMESTAMP@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Roads Department\",\"email\":\"$DEPT1_EMAIL\",\"password\":\"password123\",\"role\":\"DEPARTMENT\",\"mobile\":\"1234567890\",\"office_address\":\"City Hall\"}" > /dev/null

DEPT1_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$DEPT1_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

DEPT1_ID=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$DEPT1_EMAIL\",\"password\":\"password123\"}" | jq -r '.user.department_id')

# Create department 2
DEPT2_EMAIL="dept2_$TIMESTAMP@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Water Department\",\"email\":\"$DEPT2_EMAIL\",\"password\":\"password123\",\"role\":\"DEPARTMENT\",\"mobile\":\"9876543210\",\"office_address\":\"Water Board\"}" > /dev/null

DEPT2_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$DEPT2_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

echo "✓ Test users created"

# Create test images
echo -e "\n[SETUP] Creating test evidence images..."

TEST_JPG="/tmp/evidence_$TIMESTAMP.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

TEST_PNG="/tmp/evidence_$TIMESTAMP.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" | base64 -d > "$TEST_PNG"

TEST_WEBP="/tmp/evidence_$TIMESTAMP.webp"
printf '\x52\x49\x46\x46\x24\x00\x00\x00\x57\x45\x42\x50\x56\x50\x38\x20\x18\x00\x00\x00\x30\x01\x00\x9d\x01\x2a\x01\x00\x01\x00\x03\x00\x34\x25\xa4\x00\x03\x70\x00\xfe\xfb\x94\x00\x00' > "$TEST_WEBP"

TEST_PDF="/tmp/test_$TIMESTAMP.pdf"
echo "%PDF-1.4 fake pdf" > "$TEST_PDF"

TEST_LARGE="/tmp/large_$TIMESTAMP.jpg"
dd if=/dev/zero of="$TEST_LARGE" bs=1M count=6 2>/dev/null

echo "✓ Test files created"

# Helper function to create and progress an issue to IN_PROGRESS
create_in_progress_issue() {
    local title="$1"
    
    # Citizen reports issue
    ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
        -H "Authorization: Bearer $CITIZEN_TOKEN" \
        -F "title=$title" \
        -F "description=Test issue for resolution" \
        -F "category=ROADS" \
        -F "location=Test Street")
    
    ISSUE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.issue.id')
    
    # Moderator verifies
    curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
        -H "Authorization: Bearer $MODERATOR_TOKEN" \
        -H "Content-Type: application/json" > /dev/null
    
    # Moderator assigns to department
    curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" \
        -H "Authorization: Bearer $MODERATOR_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"department_id\":\"$DEPT1_ID\"}" > /dev/null
    
    # Department starts work
    curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
        -H "Authorization: Bearer $DEPT1_TOKEN" \
        -H "Content-Type: application/json" > /dev/null
    
    echo "$ISSUE_ID"
}

# =========================================================================
# TEST 1: Resolve with valid JPG
# =========================================================================
echo -e "\n[TEST 1] Resolve IN_PROGRESS issue with valid JPG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Issue JPG")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Fixed the issue successfully" \
    -F "evidence=@$TEST_JPG")

echo "$RESPONSE" | jq '.'

STATUS=$(echo "$RESPONSE" | jq -r '.issue.status')
EVIDENCE_URL=$(echo "$RESPONSE" | jq -r '.issue.resolution_evidence')

if [ "$STATUS" = "RESOLVED" ]; then
    test_pass "Issue resolved with JPG"
else
    test_fail "Issue not resolved: status=$STATUS"
fi

if [[ "$EVIDENCE_URL" == https://res.cloudinary.com/* ]] && [[ "$EVIDENCE_URL" == *resolution-evidence* ]]; then
    test_pass "JPG evidence uploaded to Cloudinary resolution-evidence folder"
else
    test_fail "Evidence URL invalid: $EVIDENCE_URL"
fi

# =========================================================================
# TEST 2: Resolve with PNG
# =========================================================================
echo -e "\n[TEST 2] Resolve with PNG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Issue PNG")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Resolved with PNG evidence" \
    -F "evidence=@$TEST_PNG")

STATUS=$(echo "$RESPONSE" | jq -r '.issue.status')
EVIDENCE_URL=$(echo "$RESPONSE" | jq -r '.issue.resolution_evidence')

if [ "$STATUS" = "RESOLVED" ]; then
    test_pass "Issue resolved with PNG"
else
    test_fail "PNG resolution failed"
fi

# =========================================================================
# TEST 3: Resolve with WEBP
# =========================================================================
echo -e "\n[TEST 3] Resolve with WEBP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Issue WEBP")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Resolved with WEBP evidence" \
    -F "evidence=@$TEST_WEBP;type=image/webp")

STATUS=$(echo "$RESPONSE" | jq -r '.issue.status')

if [ "$STATUS" = "RESOLVED" ]; then
    test_pass "Issue resolved with WEBP"
else
    test_fail "WEBP resolution failed"
fi

# =========================================================================
# TEST 4: Missing resolution_description
# =========================================================================
echo -e "\n[TEST 4] Missing resolution_description"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Missing Description")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "evidence=@$TEST_JPG")

echo "$RESPONSE" | jq '.'

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"description"*"required"* ]]; then
    test_pass "Missing description rejected"
else
    test_fail "Should reject missing description"
fi

# Verify issue still IN_PROGRESS
CHECK=$(curl -s -X GET "$BASE_URL/issues/$ISSUE_ID" -H "Authorization: Bearer $DEPT1_TOKEN")
CURRENT_STATUS=$(echo "$CHECK" | jq -r '.issue.status')

if [ "$CURRENT_STATUS" = "IN_PROGRESS" ]; then
    test_pass "Issue remains IN_PROGRESS after failed resolution"
else
    test_fail "Issue status changed unexpectedly: $CURRENT_STATUS"
fi

# =========================================================================
# TEST 5: Missing evidence file
# =========================================================================
echo -e "\n[TEST 5] Missing evidence file"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Missing Evidence")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Fixed it")

echo "$RESPONSE" | jq '.'

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"evidence"*"required"* ]]; then
    test_pass "Missing evidence rejected"
else
    test_fail "Should reject missing evidence"
fi

# =========================================================================
# TEST 6: Empty/whitespace description
# =========================================================================
echo -e "\n[TEST 6] Empty/whitespace description"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Empty Description")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=   " \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"empty"* ]] || [[ "$MSG" == *"required"* ]]; then
    test_pass "Whitespace-only description rejected"
else
    test_fail "Should reject whitespace description"
fi

# =========================================================================
# TEST 7: Invalid file type (PDF)
# =========================================================================
echo -e "\n[TEST 7] Invalid file type (PDF)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Invalid File")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Fixed it" \
    -F "evidence=@$TEST_PDF")

echo "$RESPONSE" | jq '.'

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"Invalid"* ]] || [[ "$MSG" == *"image"* ]]; then
    test_pass "Invalid file type rejected"
else
    test_fail "Should reject PDF files"
fi

# =========================================================================
# TEST 8: Oversized image
# =========================================================================
echo -e "\n[TEST 8] Oversized image (>5MB)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Oversized File")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Fixed it" \
    -F "evidence=@$TEST_LARGE")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"5MB"* ]] || [[ "$MSG" == *"large"* ]] || [[ "$MSG" == *"size"* ]]; then
    test_pass "Oversized file rejected"
else
    test_fail "Should reject files >5MB"
fi

# =========================================================================
# TEST 9: Unauthenticated request
# =========================================================================
echo -e "\n[TEST 9] Unauthenticated request"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Unauth")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -F "resolution_description=Fixed it" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"authorized"* ]] || [[ "$MSG" == *"token"* ]]; then
    test_pass "Unauthenticated request rejected (401)"
else
    test_fail "Should reject unauthenticated request"
fi

# =========================================================================
# TEST 10: Citizen attempts resolve
# =========================================================================
echo -e "\n[TEST 10] Citizen attempts resolve"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Citizen Resolve")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "resolution_description=I fixed it myself" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"department"* ]] || [[ "$MSG" == *"403"* ]]; then
    test_pass "Citizen resolve rejected (403)"
else
    test_fail "Should reject citizen resolve attempt"
fi

# =========================================================================
# TEST 11: Moderator attempts resolve
# =========================================================================
echo -e "\n[TEST 11] Moderator attempts resolve"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Moderator Resolve")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -F "resolution_description=Moderator resolving" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"department"* ]]; then
    test_pass "Moderator resolve rejected (403)"
else
    test_fail "Should reject moderator resolve attempt"
fi

# =========================================================================
# TEST 12: Wrong department attempts resolve
# =========================================================================
echo -e "\n[TEST 12] Wrong department attempts resolve"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Wrong Dept")

# Try to resolve with dept2 token (issue assigned to dept1)
RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT2_TOKEN" \
    -F "resolution_description=Wrong dept resolving" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"assigned to your department"* ]] || [[ "$MSG" == *"403"* ]]; then
    test_pass "Wrong department rejected (403)"
else
    test_fail "Should reject wrong department"
fi

# =========================================================================
# TEST 13: Try to resolve ASSIGNED issue
# =========================================================================
echo -e "\n[TEST 13] Try to resolve ASSIGNED issue (not IN_PROGRESS)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create issue and progress only to ASSIGNED
ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Test ASSIGNED Issue" \
    -F "description=Test" \
    -F "category=ROADS" \
    -F "location=Test")

ISSUE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.issue.id')

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" > /dev/null

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" \
    -H "Authorization: Bearer $MODERATOR_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT1_ID\"}" > /dev/null

# Try to resolve without starting
RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Trying to resolve ASSIGNED" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"IN_PROGRESS"* ]]; then
    test_pass "ASSIGNED issue cannot be resolved"
else
    test_fail "Should reject ASSIGNED issue resolution"
fi

# =========================================================================
# TEST 14: Try to resolve REPORTED issue
# =========================================================================
echo -e "\n[TEST 14] Try to resolve REPORTED issue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Test REPORTED Issue" \
    -F "description=Test" \
    -F "category=ROADS" \
    -F "location=Test")

ISSUE_ID=$(echo "$ISSUE_RESPONSE" | jq -r '.issue.id')

# Try to resolve without any progression
RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Trying to resolve REPORTED" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"IN_PROGRESS"* ]] || [[ "$MSG" == *"department"* ]]; then
    test_pass "REPORTED issue cannot be resolved"
else
    test_fail "Should reject REPORTED issue resolution"
fi

# =========================================================================
# TEST 15: Try to resolve already RESOLVED issue
# =========================================================================
echo -e "\n[TEST 15] Try to resolve already RESOLVED issue"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Double Resolve")

# Resolve once
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=First resolution" \
    -F "evidence=@$TEST_JPG" > /dev/null

# Try to resolve again
RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Second resolution" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"IN_PROGRESS"* ]] || [[ "$MSG" == *"RESOLVED"* ]]; then
    test_pass "Already RESOLVED issue cannot be resolved again"
else
    test_fail "Should reject re-resolution of RESOLVED issue"
fi

# =========================================================================
# TEST 16: Complete lifecycle with evidence
# =========================================================================
echo -e "\n[TEST 16] Complete lifecycle with resolution evidence"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Complete Lifecycle Test")

RESOLVE_RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT1_TOKEN" \
    -F "resolution_description=Complete lifecycle test resolution" \
    -F "evidence=@$TEST_JPG")

FINAL_STATUS=$(echo "$RESOLVE_RESPONSE" | jq -r '.issue.status')
EVIDENCE_URL=$(echo "$RESOLVE_RESPONSE" | jq -r '.issue.resolution_evidence')
RESOLVED_BY=$(echo "$RESOLVE_RESPONSE" | jq -r '.issue.resolvedBy.id')
RESOLVED_AT=$(echo "$RESOLVE_RESPONSE" | jq -r '.issue.resolvedAt')

echo "✓ Final status: $FINAL_STATUS"
echo "✓ Evidence URL: $EVIDENCE_URL"
echo "✓ Resolved by: $RESOLVED_BY"
echo "✓ Resolved at: $RESOLVED_AT"

if [ "$FINAL_STATUS" = "RESOLVED" ] && [ "$EVIDENCE_URL" != "null" ] && [ "$RESOLVED_BY" != "null" ] && [ "$RESOLVED_AT" != "null" ]; then
    test_pass "Complete lifecycle with evidence successful"
else
    test_fail "Complete lifecycle failed"
fi

# =========================================================================
# TEST 17: Verify evidence URL is accessible
# =========================================================================
echo -e "\n[TEST 17] Verify evidence URL is accessible"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$EVIDENCE_URL" ] && [ "$EVIDENCE_URL" != "null" ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$EVIDENCE_URL")
    
    echo "Testing URL: $EVIDENCE_URL"
    echo "HTTP Status: $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" = "200" ]; then
        test_pass "Evidence URL is accessible (200 OK)"
    else
        test_fail "Evidence URL not accessible (got $HTTP_STATUS)"
    fi
else
    test_fail "No evidence URL to test"
fi

# =========================================================================
# CLEANUP
# =========================================================================
echo -e "\n[CLEANUP] Removing test files..."
rm -f "$TEST_JPG" "$TEST_PNG" "$TEST_WEBP" "$TEST_PDF" "$TEST_LARGE"
echo "✓ Test files removed"

# =========================================================================
# RESULTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║               TASK 4: RESOLUTION EVIDENCE TEST RESULTS                 ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
if [ $FAILED -eq 0 ]; then
    echo "✅ Failed: $FAILED"
else
    echo "❌ Failed: $FAILED"
fi
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    echo ""
    echo "Evidence uploaded to Cloudinary:"
    if [ -n "$EVIDENCE_URL" ] && [ "$EVIDENCE_URL" != "null" ]; then
        echo "  Example: $EVIDENCE_URL"
    fi
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
