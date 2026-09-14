#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║         TASK 4: RESOLUTION EVIDENCE - FINAL VERIFICATION               ║"
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

echo -e "\n[STEP 1] Creating fresh test users..."

# Create citizen
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Verify Citizen\",\"email\":\"vcitizen${TIMESTAMP}@test.com\",\"password\":\"TestPass123!\"}" > /dev/null

CITIZEN_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"vcitizen${TIMESTAMP}@test.com\",\"password\":\"TestPass123!\"}")

CITIZEN_TOKEN=$(echo "$CITIZEN_LOGIN" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ] || [ -z "$CITIZEN_TOKEN" ]; then
    echo "❌ Failed to create citizen"
    exit 1
fi

echo "✓ Citizen created and logged in"

# Create moderator
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Verify Moderator\",\"email\":\"vmod${TIMESTAMP}@test.com\",\"password\":\"TestPass123!\"}" > /dev/null

# Upgrade to MODERATOR in database
mongosh "$MONGO_URI" --quiet --eval "
db.users.updateOne(
    {email: 'vmod${TIMESTAMP}@test.com'},
    {\$set: {role: 'MODERATOR'}}
)
" > /dev/null

MOD_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"vmod${TIMESTAMP}@test.com\",\"password\":\"TestPass123!\"}")

MOD_TOKEN=$(echo "$MOD_LOGIN" | jq -r '.token')

if [ "$MOD_TOKEN" = "null" ] || [ -z "$MOD_TOKEN" ]; then
    echo "❌ Failed to create moderator"
    exit 1
fi

echo "✓ Moderator created and logged in"

# Create department user
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Verify Department\",\"email\":\"vdept${TIMESTAMP}@test.com\",\"password\":\"TestPass123!\"}" > /dev/null

# Upgrade to DEPARTMENT and set self-referencing department_id
DEPT_SETUP=$(mongosh "$MONGO_URI" --quiet --eval "
const user = db.users.findOne({email: 'vdept${TIMESTAMP}@test.com'});
if (user) {
    db.users.updateOne(
        {_id: user._id},
        {\$set: {
            role: 'DEPARTMENT',
            mobile: '1234567890',
            office_address: 'Verification Test Office',
            department_id: user._id
        }}
    );
    print(user._id.toString());
} else {
    print('ERROR');
}
")

DEPT_ID=$(echo "$DEPT_SETUP" | grep -o '[0-9a-f]\{24\}' | head -1)

if [ -z "$DEPT_ID" ] || [ "$DEPT_ID" = "ERROR" ]; then
    echo "❌ Failed to setup department"
    exit 1
fi

DEPT_LOGIN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"vdept${TIMESTAMP}@test.com\",\"password\":\"TestPass123!\"}")

DEPT_TOKEN=$(echo "$DEPT_LOGIN" | jq -r '.token')

if [ "$DEPT_TOKEN" = "null" ] || [ -z "$DEPT_TOKEN" ]; then
    echo "❌ Failed to login department"
    exit 1
fi

echo "✓ Department created and logged in (ID: $DEPT_ID)"

# Create test images
TEST_JPG="/tmp/verify_evidence_${TIMESTAMP}.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

TEST_PNG="/tmp/verify_evidence_${TIMESTAMP}.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" | base64 -d > "$TEST_PNG"

TEST_PDF="/tmp/verify_${TIMESTAMP}.pdf"
echo "%PDF-1.4 test" > "$TEST_PDF"

TEST_LARGE="/tmp/verify_large_${TIMESTAMP}.jpg"
dd if=/dev/zero of="$TEST_LARGE" bs=1M count=6 2>/dev/null

echo "✓ Test files created"

echo -e "\n[STEP 2] Creating and progressing issue to IN_PROGRESS..."

# Citizen creates issue
ISSUE_CREATE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Street Light Not Working - Verification Test" \
    -F "description=The street light on Main Street has been broken for 3 days" \
    -F "category=ELECTRICITY" \
    -F "location=Main Street, Block A")

ISSUE_ID=$(echo "$ISSUE_CREATE" | jq -r '.issue.id')

if [ "$ISSUE_ID" = "null" ] || [ -z "$ISSUE_ID" ]; then
    echo "❌ Failed to create issue"
    echo "$ISSUE_CREATE" | jq '.'
    exit 1
fi

echo "✓ Issue created: $ISSUE_ID"

# Moderator verifies
VERIFY_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json")

VERIFY_STATUS=$(echo "$VERIFY_RESP" | jq -r '.issue.status // empty')

if [ "$VERIFY_STATUS" = "VERIFIED" ]; then
    echo "✓ Issue verified"
else
    echo "❌ Verify failed: $(echo "$VERIFY_RESP" | jq -r '.message')"
    exit 1
fi

# Moderator assigns
ASSIGN_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}")

ASSIGN_STATUS=$(echo "$ASSIGN_RESP" | jq -r '.issue.status // empty')

if [ "$ASSIGN_STATUS" = "ASSIGNED" ]; then
    echo "✓ Issue assigned to department"
else
    echo "❌ Assign failed: $(echo "$ASSIGN_RESP" | jq -r '.message')"
    exit 1
fi

# Department starts work
START_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json")

START_STATUS=$(echo "$START_RESP" | jq -r '.issue.status // empty')

if [ "$START_STATUS" = "IN_PROGRESS" ]; then
    echo "✓ Issue started (IN_PROGRESS)"
else
    echo "❌ Start failed: $(echo "$START_RESP" | jq -r '.message')"
    exit 1
fi

echo -e "\n[MAIN TEST] Resolving issue with evidence (JPG)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESOLVE_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Street light bulb replaced and tested. Working properly now." \
    -F "evidence=@$TEST_JPG")

echo "$RESOLVE_RESP" | jq '.'

RESOLVE_STATUS=$(echo "$RESOLVE_RESP" | jq -r '.issue.status // empty')
RESOLUTION_DESC=$(echo "$RESOLVE_RESP" | jq -r '.issue.resolution_description // empty')
EVIDENCE_URL=$(echo "$RESOLVE_RESP" | jq -r '.issue.resolution_evidence // empty')
RESOLVED_BY=$(echo "$RESOLVE_RESP" | jq -r '.issue.resolvedBy.id // empty')
RESOLVED_AT=$(echo "$RESOLVE_RESP" | jq -r '.issue.resolvedAt // empty')

echo ""

if [ "$RESOLVE_STATUS" = "RESOLVED" ]; then
    test_pass "Issue resolved successfully"
else
    test_fail "Resolution failed (status: $RESOLVE_STATUS)"
fi

if [ -n "$RESOLUTION_DESC" ] && [ "$RESOLUTION_DESC" != "null" ]; then
    test_pass "Resolution description stored"
else
    test_fail "Resolution description missing"
fi

if [[ "$EVIDENCE_URL" == https://res.cloudinary.com/* ]]; then
    test_pass "Evidence URL is Cloudinary URL"
    
    if [[ "$EVIDENCE_URL" == *"resolution-evidence"* ]]; then
        test_pass "Evidence in correct folder (resolution-evidence)"
    else
        test_fail "Evidence not in resolution-evidence folder"
    fi
else
    test_fail "Evidence URL invalid: $EVIDENCE_URL"
fi

if [ -n "$RESOLVED_BY" ] && [ "$RESOLVED_BY" != "null" ]; then
    test_pass "resolvedBy populated"
else
    test_fail "resolvedBy missing"
fi

if [ -n "$RESOLVED_AT" ] && [ "$RESOLVED_AT" != "null" ]; then
    test_pass "resolvedAt populated"
else
    test_fail "resolvedAt missing"
fi

# Verify Cloudinary URL is accessible
if [ -n "$EVIDENCE_URL" ] && [[ "$EVIDENCE_URL" == https://* ]]; then
    echo -e "\n[CLOUDINARY] Testing evidence URL accessibility..."
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$EVIDENCE_URL")
    
    echo "  URL: $EVIDENCE_URL"
    echo "  HTTP Status: $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" = "200" ]; then
        test_pass "Evidence URL is accessible (HTTP 200)"
    else
        test_fail "Evidence URL not accessible (HTTP $HTTP_STATUS)"
    fi
fi

# Verify in database
echo -e "\n[DATABASE] Verifying MongoDB storage..."
DB_CHECK=$(mongosh "$MONGO_URI" --quiet --eval "
const issue = db.civicissues.findOne({_id: ObjectId('$ISSUE_ID')});
if (issue) {
    print(JSON.stringify({
        status: issue.status,
        resolution_evidence: issue.resolution_evidence,
        resolvedBy: issue.resolvedBy ? issue.resolvedBy.toString() : null,
        resolvedAt: issue.resolvedAt
    }));
} else {
    print('{}');
}
")

DB_STATUS=$(echo "$DB_CHECK" | jq -r '.status // empty')
DB_EVIDENCE=$(echo "$DB_CHECK" | jq -r '.resolution_evidence // empty')

if [ "$DB_STATUS" = "RESOLVED" ]; then
    test_pass "Database status is RESOLVED"
else
    test_fail "Database status incorrect: $DB_STATUS"
fi

if [[ "$DB_EVIDENCE" == https://* ]]; then
    test_pass "Database contains Cloudinary URL (no binary data)"
else
    test_fail "Database evidence field invalid"
fi

echo -e "\n[FAILURE CASES] Testing validation..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Helper to create IN_PROGRESS issue
create_test_issue() {
    IR=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
        -F "title=Test Issue $1" -F "description=Test" -F "category=ROADS" -F "location=Test")
    
    IID=$(echo "$IR" | jq -r '.issue.id')
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
    curl -s -X PATCH "$BASE_URL/issues/$IID/assign" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null
    curl -s -X PATCH "$BASE_URL/issues/$IID/start" -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json" > /dev/null
    
    echo "$IID"
}

# Test 1: Missing evidence
IID=$(create_test_issue "No Evidence")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"evidence"*"required"* ]]; then
    test_pass "Missing evidence rejected"
else
    test_fail "Should reject missing evidence"
fi

# Test 2: Missing description
IID=$(create_test_issue "No Description")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"description"*"required"* ]]; then
    test_pass "Missing description rejected"
else
    test_fail "Should reject missing description"
fi

# Test 3: Empty description
IID=$(create_test_issue "Empty Description")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=   " -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"empty"* ]]; then
    test_pass "Empty description rejected"
else
    test_fail "Should reject empty description"
fi

# Test 4: Invalid file type (PDF)
IID=$(create_test_issue "Invalid File")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_PDF")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"Invalid"* ]] || [[ "$MSG" == *"image"* ]]; then
    test_pass "Invalid file type rejected"
else
    test_fail "Should reject PDF files"
fi

# Test 5: Oversized file
IID=$(create_test_issue "Oversized File")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_LARGE")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"5MB"* ]] || [[ "$MSG" == *"large"* ]] || [[ "$MSG" == *"size"* ]]; then
    test_pass "Oversized file rejected"
else
    test_fail "Should reject oversized files"
fi

# Test 6: Citizen attempts resolve
IID=$(create_test_issue "Citizen Test")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $CITIZEN_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"department"* ]]; then
    test_pass "Citizen resolve rejected (403)"
else
    test_fail "Should reject citizen resolve"
fi

# Test 7: Moderator attempts resolve
IID=$(create_test_issue "Moderator Test")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $MOD_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"department"* ]]; then
    test_pass "Moderator resolve rejected (403)"
else
    test_fail "Should reject moderator resolve"
fi

# Test 8: ASSIGNED issue (not IN_PROGRESS)
IR=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" -F "title=ASSIGNED Test" -F "description=Test" -F "category=ROADS" -F "location=Test")
IID=$(echo "$IR" | jq -r '.issue.id')
curl -s -X PATCH "$BASE_URL/issues/$IID/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
curl -s -X PATCH "$BASE_URL/issues/$IID/assign" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null

RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"IN_PROGRESS"* ]]; then
    test_pass "ASSIGNED issue cannot be resolved"
else
    test_fail "Should reject ASSIGNED issue"
fi

# Test 9: REPORTED issue
IR=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" -F "title=REPORTED Test" -F "description=Test" -F "category=ROADS" -F "location=Test")
IID=$(echo "$IR" | jq -r '.issue.id')

RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"IN_PROGRESS"* ]] || [[ "$MSG" == *"department"* ]]; then
    test_pass "REPORTED issue cannot be resolved"
else
    test_fail "Should reject REPORTED issue"
fi

# Test 10: Already RESOLVED issue
IID=$(create_test_issue "Double Resolve")
curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=First resolve" -F "evidence=@$TEST_JPG" > /dev/null

RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Second resolve" -F "evidence=@$TEST_JPG")
MSG=$(echo "$RESP" | jq -r '.message')

if [[ "$MSG" == *"IN_PROGRESS"* ]] || [[ "$MSG" == *"RESOLVED"* ]]; then
    test_pass "Already RESOLVED issue cannot be resolved again"
else
    test_fail "Should reject re-resolution"
fi

echo -e "\n[REGRESSION] Verifying Task 3 (Civic Issue Image Upload) still works..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

TASK3_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Task 3 Regression Test" \
    -F "description=Testing image upload from Task 3" \
    -F "category=SANITATION" \
    -F "location=Test Location" \
    -F "image=@$TEST_PNG")

TASK3_IMAGE=$(echo "$TASK3_RESP" | jq -r '.issue.image_url')

if [[ "$TASK3_IMAGE" == https://res.cloudinary.com/* ]] && [[ "$TASK3_IMAGE" == *"/issues/"* ]]; then
    test_pass "Task 3 image upload still works"
else
    test_fail "Task 3 image upload broken"
fi

# Cleanup
echo -e "\n[CLEANUP] Removing test files..."
rm -f "$TEST_JPG" "$TEST_PNG" "$TEST_PDF" "$TEST_LARGE"
echo "✓ Test files removed"

# Results
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                  TASK 4 VERIFICATION RESULTS                            ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total Tests: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
[ $FAILED -eq 0 ] && echo "✅ Failed: $FAILED" || echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    echo ""
    echo "✅ Complete workflow verified:"
    echo "   REPORTED → VERIFIED → ASSIGNED → IN_PROGRESS → RESOLVED (with evidence)"
    echo ""
    echo "✅ Evidence uploaded to Cloudinary:"
    echo "   $EVIDENCE_URL"
    echo ""
    echo "✅ Task 3 regression: PASS"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
