#!/bin/bash

BASE_URL="http://localhost:4000/api"
TIMESTAMP=$(date +%s)

# Register and login
CITIZEN_EMAIL="webptest$TIMESTAMP@example.com"

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"WEBP Test User\",\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

echo "✓ Logged in as: $CITIZEN_EMAIL"

# Create WEBP file
TEST_WEBP="/tmp/test_webp_$TIMESTAMP.webp"
printf '\x52\x49\x46\x46\x24\x00\x00\x00\x57\x45\x42\x50\x56\x50\x38\x20\x18\x00\x00\x00\x30\x01\x00\x9d\x01\x2a\x01\x00\x01\x00\x03\x00\x34\x25\xa4\x00\x03\x70\x00\xfe\xfb\x94\x00\x00' > "$TEST_WEBP"

echo "✓ Created WEBP file: $TEST_WEBP"

# Check MIME type detected by system
echo "✓ System MIME type:"
file --mime-type "$TEST_WEBP"

# Test 1: Upload without explicit MIME type
echo -e "\n[TEST 1] Upload without explicit MIME type:"
RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=WEBP Test 1" \
    -F "description=Testing WEBP upload" \
    -F "category=ROADS" \
    -F "location=Test Location" \
    -F "image=@$TEST_WEBP")

echo "$RESPONSE" | jq '.'

# Test 2: Upload with explicit MIME type
echo -e "\n[TEST 2] Upload with explicit MIME type (image/webp):"
RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=WEBP Test 2" \
    -F "description=Testing WEBP with explicit MIME" \
    -F "category=ROADS" \
    -F "location=Test Location" \
    -F "image=@$TEST_WEBP;type=image/webp")

echo "$RESPONSE" | jq '.'

# Cleanup
rm -f "$TEST_WEBP"
echo -e "\n✓ Cleanup complete"
