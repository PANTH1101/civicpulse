#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 4: RESOLUTION EVIDENCE TEST (With DB Setup)                 ║"
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

# Setup users directly in MongoDB
echo -e "\n[SETUP] Creating test users in MongoDB..."

TIMESTAMP=$(date +%s)

# Hash for "password123"
HASHED_PW='$2a$10$N9qo8uLOickgx2ZMRZoMye/IVI9Bt/AQ8SJu3OY4TXUxQ7Q8T0.LK'

# Create citizen
mongosh "$MONGO_URI" --quiet --eval "
db.users.insertOne({
    name: 'Test Citizen',
    email: 'citizen${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'CITIZEN',
    createdAt: new Date(),
    updatedAt: new Date()
})
" > /dev/null

# Create moderator
mongosh "$MONGO_URI" --quiet --eval "
db.users.insertOne({
    name: 'Test Moderator',
    email: 'moderator${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'MODERATOR',
    createdAt: new Date(),
    updatedAt: new Date()
})
" > /dev/null

# Create department with self-referencing department_id
DEPT_RESULT=$(mongosh "$MONGO_URI" --quiet --eval "
const dept = db.users.insertOne({
    name: 'Test Department',
    email: 'dept${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'DEPARTMENT',
    mobile: '1234567890',
    office_address: 'Test Office',
    createdAt: new Date(),
    updatedAt: new Date()
});
db.users.updateOne(
    { _id: dept.insertedId },
    { \$set: { department_id: dept.insertedId } }
);
print(dept.insertedId.toString());
")

DEPT_ID=$(echo "$DEPT_RESULT" | tail -1 | tr -d '\n\r')

echo "✓ Users created in database"
echo "  Department ID: $DEPT_ID"

# Login users
CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"citizen${TIMESTAMP}@test.com\",\"password\":\"password123\"}" | jq -r '.token')

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"moderator${TIMESTAMP}@test.com\",\"password\":\"password123\"}" | jq -r '.token')

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"dept${TIMESTAMP}@test.com\",\"password\":\"password123\"}" | jq -r '.token')

echo "✓ Logged in all users"

# Create test images
TEST_JPG="/tmp/evidence_$TIMESTAMP.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

TEST_PNG="/tmp/evidence_$TIMESTAMP.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" | base64 -d > "$TEST_PNG"

TEST_WEBP="/tmp/evidence_$TIMESTAMP.webp"
printf '\x52\x49\x46\x46\x24\x00\x00\x00\x57\x45\x42\x50\x56\x50\x38\x20\x18\x00\x00\x00\x30\x01\x00\x9d\x01\x2a\x01\x00\x01\x00\x03\x00\x34\x25\xa4\x00\x03\x70\x00\xfe\xfb\x94\x00\x00' > "$TEST_WEBP"

TEST_PDF="/tmp/test_$TIMESTAMP.pdf"
echo "%PDF-1.4 fake pdf" > "$TEST_PDF"

echo "✓ Test files created"

# Helper to create IN_PROGRESS issue
create_in_progress_issue() {
    local title="$1"
    
    ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
        -H "Authorization: Bearer $CITIZEN_TOKEN" \
        -F "title=$title" \
        -F "description=Test" \
        -F "category=ROADS" \
        -F "location=Test")
    
    ISSUE_ID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
    
    curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" \
        -H "Authorization: Bearer $MOD_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null
    
    curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
        -H "Authorization: Bearer $DEPT_TOKEN" \
        -H "Content-Type: application/json" > /dev/null
    
    echo "$ISSUE_ID"
}

# =========================================================================
# TEST 1: Resolve with valid JPG
# =========================================================================
echo -e "\n[TEST 1] Resolve IN_PROGRESS issue with valid JPG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test JPG")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed successfully" \
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
    test_pass "JPG uploaded to resolution-evidence folder"
    FINAL_EVIDENCE_URL="$EVIDENCE_URL"
else
    test_fail "Evidence URL invalid: $EVIDENCE_URL"
fi

# =========================================================================
# TEST 2: Resolve with PNG
# =========================================================================
echo -e "\n[TEST 2] Resolve with PNG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test PNG")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Resolved with PNG" \
    -F "evidence=@$TEST_PNG")

STATUS=$(echo "$RESPONSE" | jq -r '.issue.status')

if [ "$STATUS" = "RESOLVED" ]; then
    test_pass "Issue resolved with PNG")
else
    test_fail "PNG resolution failed"
fi

# =========================================================================
# TEST 3: Resolve with WEBP
# =========================================================================
echo -e "\n[TEST 3] Resolve with WEBP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test WEBP")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Resolved with WEBP" \
    -F "evidence=@$TEST_WEBP;type=image/webp")

STATUS=$(echo "$RESPONSE" | jq -r '.issue.status')

if [ "$STATUS" = "RESOLVED" ]; then
    test_pass "Issue resolved with WEBP"
else
    test_fail "WEBP resolution failed"
fi

# =========================================================================
# TEST 4: Missing description
# =========================================================================
echo -e "\n[TEST 4] Missing resolution_description"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Missing Desc")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"description"*"required"* ]]; then
    test_pass "Missing description rejected"
else
    test_fail "Should reject missing description: $MSG"
fi

# =========================================================================
# TEST 5: Missing evidence
# =========================================================================
echo -e "\n[TEST 5] Missing evidence file"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Missing Evidence")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"evidence"*"required"* ]]; then
    test_pass "Missing evidence rejected"
else
    test_fail "Should reject missing evidence: $MSG"
fi

# =========================================================================
# TEST 6: Empty description
# =========================================================================
echo -e "\n[TEST 6] Empty/whitespace description"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Empty Desc")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=   " \
    -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"empty"* ]]; then
    test_pass "Whitespace-only description rejected"
else
    test_fail "Should reject whitespace description: $MSG"
fi

# =========================================================================
# TEST 7: Invalid file type
# =========================================================================
echo -e "\n[TEST 7] Invalid file type (PDF)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ISSUE_ID=$(create_in_progress_issue "Test Invalid File")

RESPONSE=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed" \
    -F "evidence=@$TEST_PDF")

MSG=$(echo "$RESPONSE" | jq -r '.message')

if [[ "$MSG" == *"Invalid"* ]] || [[ "$MSG" == *"image"* ]]; then
    test_pass "Invalid file type rejected"
else
    test_fail "Should reject PDF: $MSG"
fi

# =========================================================================
# TEST 8: Verify evidence URL accessible
# =========================================================================
echo -e "\n[TEST 8] Verify evidence URL is accessible"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$FINAL_EVIDENCE_URL" ] && [ "$FINAL_EVIDENCE_URL" != "null" ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$FINAL_EVIDENCE_URL")
    
    echo "Testing URL: $FINAL_EVIDENCE_URL"
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
rm -f "$TEST_JPG" "$TEST_PNG" "$TEST_WEBP" "$TEST_PDF"
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
    if [ -n "$FINAL_EVIDENCE_URL" ]; then
        echo ""
        echo "Sample evidence URL:"
        echo "  $FINAL_EVIDENCE_URL"
    fi
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
