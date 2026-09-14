#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 4: RESOLUTION EVIDENCE FILE UPLOAD - COMPLETE TEST          ║"
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

# Register fresh users
echo -e "\n[SETUP] Creating fresh test users..."

curl -s -X POST "$BASE_URL/auth/register" -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Citizen\",\"email\":\"testcit${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" \
    -d "{\"email\":\"testcit${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

curl -s -X POST "$BASE_URL/auth/register" -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Mod\",\"email\":\"testmod${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 'testmod${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" \
    -d "{\"email\":\"testmod${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

curl -s -X POST "$BASE_URL/auth/register" -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Dept\",\"email\":\"testdept${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

DEPT_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'testdept${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: u._id}});
print(u._id.toString());
" | grep -o '[0-9a-f]\{24\}')

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" \
    -d "{\"email\":\"testdept${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

if [ "$CITIZEN_TOKEN" = "null" ] || [ -z "$CITIZEN_TOKEN" ] || [ "$MOD_TOKEN" = "null" ] || [ -z "$MOD_TOKEN" ] || [ "$DEPT_TOKEN" = "null" ] || [ -z "$DEPT_TOKEN" ] || [ -z "$DEPT_ID" ]; then
    echo "❌ Setup failed - could not create users"
    echo "  Citizen token: ${CITIZEN_TOKEN:0:20}..."
    echo "  Mod token: ${MOD_TOKEN:0:20}..."
    echo "  Dept token: ${DEPT_TOKEN:0:20}..."
    echo "  Dept ID: $DEPT_ID"
    exit 1
fi

echo "✓ Users created successfully"
echo "  Department ID: $DEPT_ID"

# Create test files
TEST_JPG="/tmp/ev_$TIMESTAMP.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

TEST_PNG="/tmp/ev_$TIMESTAMP.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" | base64 -d > "$TEST_PNG"

TEST_WEBP="/tmp/ev_$TIMESTAMP.webp"
printf '\x52\x49\x46\x46\x24\x00\x00\x00\x57\x45\x42\x50\x56\x50\x38\x20\x18\x00\x00\x00\x30\x01\x00\x9d\x01\x2a\x01\x00\x01\x00\x03\x00\x34\x25\xa4\x00\x03\x70\x00\xfe\xfb\x94\x00\x00' > "$TEST_WEBP"

TEST_PDF="/tmp/ev_$TIMESTAMP.pdf"
echo "%PDF-1.4" > "$TEST_PDF"

echo "✓ Test files created"

# Helper
create_in_progress_issue() {
    local title="$1"
    
    IR=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
        -F "title=$title" -F "description=Test" -F "category=ROADS" -F "location=Test")
    
    IID=$(echo "$IR" | jq -r '.issue.id')
    
    curl -s -X PATCH "$BASE_URL/issues/$IID/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
    curl -s -X PATCH "$BASE_URL/issues/$IID/assign" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null
    curl -s -X PATCH "$BASE_URL/issues/$IID/start" -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json" > /dev/null
    
    echo "$IID"
}

# TEST 1: JPG
echo -e "\n[TEST 1] Resolve with JPG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test JPG $TIMESTAMP")

RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Issue fixed successfully" -F "evidence=@$TEST_JPG")

ST=$(echo "$RESP" | jq -r '.issue.status // empty')
EV=$(echo "$RESP" | jq -r '.issue.resolution_evidence // empty')

if [ "$ST" = "RESOLVED" ]; then
    test_pass "JPG resolution successful"
else
    test_fail "JPG resolution failed (status: $ST)"
fi

if [[ "$EV" == https://res.cloudinary.com/* ]] && [[ "$EV" == *"resolution-evidence"* ]]; then
    test_pass "JPG uploaded to resolution-evidence folder"
    FINAL_URL="$EV"
else
    test_fail "JPG evidence URL invalid"
fi

# TEST 2: PNG
echo -e "\n[TEST 2] Resolve with PNG"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test PNG $TIMESTAMP")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=PNG evidence" -F "evidence=@$TEST_PNG")

ST=$(echo "$RESP" | jq -r '.issue.status // empty')

if [ "$ST" = "RESOLVED" ]; then
    test_pass "PNG resolution successful"
else
    test_fail "PNG resolution failed"
fi

# TEST 3: WEBP
echo -e "\n[TEST 3] Resolve with WEBP"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test WEBP $TIMESTAMP")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=WEBP evidence" -F "evidence=@$TEST_WEBP;type=image/webp")

ST=$(echo "$RESP" | jq -r '.issue.status // empty')

if [ "$ST" = "RESOLVED" ]; then
    test_pass "WEBP resolution successful"
else
    test_fail "WEBP resolution failed"
fi

# TEST 4: Missing description
echo -e "\n[TEST 4] Missing description"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test No Desc $TIMESTAMP")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESP" | jq -r '.message // empty')

if [[ "$MSG" == *"description"*"required"* ]]; then
    test_pass "Missing description rejected"
else
    test_fail "Should reject missing description"
fi

# TEST 5: Missing evidence
echo -e "\n[TEST 5] Missing evidence"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test No Evidence $TIMESTAMP")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed")

MSG=$(echo "$RESP" | jq -r '.message // empty')

if [[ "$MSG" == *"evidence"*"required"* ]]; then
    test_pass "Missing evidence rejected"
else
    test_fail "Should reject missing evidence"
fi

# TEST 6: Empty description
echo -e "\n[TEST 6] Empty description"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test Empty Desc $TIMESTAMP")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=   " -F "evidence=@$TEST_JPG")

MSG=$(echo "$RESP" | jq -r '.message // empty')

if [[ "$MSG" == *"empty"* ]]; then
    test_pass "Empty description rejected"
else
    test_fail "Should reject empty description"
fi

# TEST 7: Invalid file type
echo -e "\n[TEST 7] Invalid file type (PDF)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

IID=$(create_in_progress_issue "Test PDF $TIMESTAMP")
RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Fixed" -F "evidence=@$TEST_PDF")

MSG=$(echo "$RESP" | jq -r '.message // empty')

if [[ "$MSG" == *"Invalid"* ]] || [[ "$MSG" == *"image"* ]]; then
    test_pass "Invalid file type rejected"
else
    test_fail "Should reject PDF"
fi

# TEST 8: URL accessible
echo -e "\n[TEST 8] Evidence URL accessible"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$FINAL_URL" ]; then
    HTTP_ST=$(curl -s -o /dev/null -w "%{http_code}" "$FINAL_URL")
    
    if [ "$HTTP_ST" = "200" ]; then
        test_pass "Evidence URL accessible"
    else
        test_fail "Evidence URL not accessible"
    fi
else
    test_fail "No evidence URL"
fi

# CLEANUP
echo -e "\n[CLEANUP]"
rm -f "$TEST_JPG" "$TEST_PNG" "$TEST_WEBP" "$TEST_PDF"
echo "✓ Test files removed"

# RESULTS
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     TASK 4 TEST RESULTS                                 ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Total: $((PASSED + FAILED))"
echo "✅ Passed: $PASSED"
[ $FAILED -eq 0 ] && echo "✅ Failed: $FAILED" || echo "❌ Failed: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 ALL TESTS PASSED!"
    [ -n "$FINAL_URL" ] && echo "  Evidence URL: $FINAL_URL"
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
