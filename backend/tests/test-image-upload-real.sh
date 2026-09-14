#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║       TASK 3: IMAGE UPLOAD - REAL CLOUDINARY TEST                      ║"
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
# SETUP
# =========================================================================
echo -e "\n[SETUP] Registering and logging in..."

TIMESTAMP=$(date +%s)
CITIZEN_EMAIL="realtest$TIMESTAMP@example.com"

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Real Test User\",\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

echo "✓ Test user created: $CITIZEN_EMAIL"

# =========================================================================
# Create test images
# =========================================================================
echo -e "\n[SETUP] Creating test images..."

# Create a small valid PNG (1x1 pixel, red)
TEST_PNG="/tmp/test_image_$TIMESTAMP.png"
echo "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==" | base64 -d > "$TEST_PNG"

# Create a small valid JPEG
TEST_JPG="/tmp/test_image_$TIMESTAMP.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

# Create a small valid WEBP (1x1 pixel)
TEST_WEBP="/tmp/test_image_$TIMESTAMP.webp"
printf '\x52\x49\x46\x46\x24\x00\x00\x00\x57\x45\x42\x50\x56\x50\x38\x20\x18\x00\x00\x00\x30\x01\x00\x9d\x01\x2a\x01\x00\x01\x00\x03\x00\x34\x25\xa4\x00\x03\x70\x00\xfe\xfb\x94\x00\x00' > "$TEST_WEBP"

echo "✓ Test images created"

# =========================================================================
# TEST 1: Upload PNG image
# =========================================================================
echo -e "\n[TEST 1] Upload issue with PNG image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE_PNG=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Pothole with PNG Image" \
    -F "description=Large pothole on Main Street" \
    -F "category=ROADS" \
    -F "location=Main Street" \
    -F "image=@$TEST_PNG")

echo "$RESPONSE_PNG" | jq '.'

STATUS_MSG=$(echo "$RESPONSE_PNG" | jq -r '.message')
IMAGE_URL_PNG=$(echo "$RESPONSE_PNG" | jq -r '.issue.image_url')

if [ "$STATUS_MSG" = "Issue reported successfully" ]; then
    test_pass "Issue with PNG created successfully"
else
    test_fail "Issue creation failed: $STATUS_MSG"
fi

if [ "$IMAGE_URL_PNG" != "null" ] && [ -n "$IMAGE_URL_PNG" ] && [[ "$IMAGE_URL_PNG" == https://res.cloudinary.com/* ]]; then
    test_pass "PNG uploaded to Cloudinary"
    ISSUE_ID_PNG=$(echo "$RESPONSE_PNG" | jq -r '.issue.id')
else
    test_fail "PNG upload failed or invalid URL: $IMAGE_URL_PNG"
fi

# =========================================================================
# TEST 2: Upload JPEG image
# =========================================================================
echo -e "\n[TEST 2] Upload issue with JPEG image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE_JPG=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Broken Light with JPEG" \
    -F "description=Street light not working" \
    -F "category=ELECTRICITY" \
    -F "location=Oak Avenue" \
    -F "image=@$TEST_JPG")

echo "$RESPONSE_JPG" | jq '.'

STATUS_MSG=$(echo "$RESPONSE_JPG" | jq -r '.message')
IMAGE_URL_JPG=$(echo "$RESPONSE_JPG" | jq -r '.issue.image_url')

if [ "$STATUS_MSG" = "Issue reported successfully" ]; then
    test_pass "Issue with JPEG created successfully"
else
    test_fail "Issue creation failed"
fi

if [ "$IMAGE_URL_JPG" != "null" ] && [ -n "$IMAGE_URL_JPG" ] && [[ "$IMAGE_URL_JPG" == https://res.cloudinary.com/* ]]; then
    test_pass "JPEG uploaded to Cloudinary"
    ISSUE_ID_JPG=$(echo "$RESPONSE_JPG" | jq -r '.issue.id')
else
    test_fail "JPEG upload failed"
fi

# =========================================================================
# TEST 3: Upload WEBP image
# =========================================================================
echo -e "\n[TEST 3] Upload issue with WEBP image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

RESPONSE_WEBP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Water Leak with WEBP" \
    -F "description=Pipe leaking water" \
    -F "category=WATER" \
    -F "location=Park Street" \
    -F "image=@$TEST_WEBP;type=image/webp")

echo "$RESPONSE_WEBP" | jq '.'

STATUS_MSG=$(echo "$RESPONSE_WEBP" | jq -r '.message')
IMAGE_URL_WEBP=$(echo "$RESPONSE_WEBP" | jq -r '.issue.image_url')

if [ "$STATUS_MSG" = "Issue reported successfully" ]; then
    test_pass "Issue with WEBP created successfully"
else
    test_fail "Issue creation failed: $STATUS_MSG"
fi

if [ "$IMAGE_URL_WEBP" != "null" ] && [ -n "$IMAGE_URL_WEBP" ] && [[ "$IMAGE_URL_WEBP" == https://res.cloudinary.com/* ]]; then
    test_pass "WEBP uploaded to Cloudinary"
    ISSUE_ID_WEBP=$(echo "$RESPONSE_WEBP" | jq -r '.issue.id')
else
    test_fail "WEBP upload failed"
fi

# =========================================================================
# TEST 4: Verify image URL in GET endpoint
# =========================================================================
echo -e "\n[TEST 4] Verify image URL persists in GET endpoints"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$ISSUE_ID_PNG" ]; then
    SINGLE_ISSUE=$(curl -s -X GET "$BASE_URL/issues/$ISSUE_ID_PNG" \
        -H "Authorization: Bearer $CITIZEN_TOKEN")
    
    echo "Single issue response:"
    echo "$SINGLE_ISSUE" | jq '.issue | {id, title, image_url}'
    
    IMAGE_URL_GET=$(echo "$SINGLE_ISSUE" | jq -r '.issue.image_url')
    
    if [ "$IMAGE_URL_GET" != "null" ] && [ -n "$IMAGE_URL_GET" ]; then
        test_pass "GET /issues/:id returns image_url"
    else
        test_fail "GET /issues/:id missing image_url"
    fi
fi

# =========================================================================
# TEST 5: Verify image URLs in list endpoint
# =========================================================================
echo -e "\n[TEST 5] Verify image URLs in issue list"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MY_ISSUES=$(curl -s -X GET "$BASE_URL/issues/my-issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")

echo "Issue list (first 3):"
echo "$MY_ISSUES" | jq '.issues[0:3] | .[] | {id, title, image_url}'

IMAGES_WITH_URL=$(echo "$MY_ISSUES" | jq '[.issues[] | select(.image_url != null)] | length')

if [ "$IMAGES_WITH_URL" -ge 2 ]; then
    test_pass "GET /issues/my-issues returns image_url for $IMAGES_WITH_URL issues"
else
    test_fail "Expected at least 2 issues with image_url, got $IMAGES_WITH_URL"
fi

# =========================================================================
# TEST 6: Verify Cloudinary URL accessibility
# =========================================================================
echo -e "\n[TEST 6] Verify Cloudinary URLs are accessible"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -n "$IMAGE_URL_PNG" ] && [ "$IMAGE_URL_PNG" != "null" ]; then
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$IMAGE_URL_PNG")
    
    echo "Testing URL: $IMAGE_URL_PNG"
    echo "HTTP Status: $HTTP_STATUS"
    
    if [ "$HTTP_STATUS" = "200" ]; then
        test_pass "Cloudinary image URL is accessible (200 OK)"
    else
        test_fail "Cloudinary image URL not accessible (got $HTTP_STATUS)"
    fi
else
    test_fail "No image URL to test"
fi

# =========================================================================
# TEST 7: Complete workflow - Issue lifecycle with image
# =========================================================================
echo -e "\n[TEST 7] Complete workflow - Issue lifecycle with image"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create issue with image
WORKFLOW_RESPONSE=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Workflow Test with Image" \
    -F "description=Testing complete lifecycle" \
    -F "category=SANITATION" \
    -F "location=Test Street" \
    -F "image=@$TEST_PNG")

WORKFLOW_ISSUE_ID=$(echo "$WORKFLOW_RESPONSE" | jq -r '.issue.id')
WORKFLOW_IMAGE_URL=$(echo "$WORKFLOW_RESPONSE" | jq -r '.issue.image_url')

echo "✓ Issue created with ID: $WORKFLOW_ISSUE_ID"
echo "✓ Image URL: $WORKFLOW_IMAGE_URL"

# Verify image URL present throughout lifecycle
ISSUE_CHECK=$(curl -s -X GET "$BASE_URL/issues/$WORKFLOW_ISSUE_ID" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")

FINAL_IMAGE_URL=$(echo "$ISSUE_CHECK" | jq -r '.issue.image_url')

if [ "$FINAL_IMAGE_URL" = "$WORKFLOW_IMAGE_URL" ]; then
    test_pass "Image URL preserved throughout lifecycle"
else
    test_fail "Image URL changed or lost"
fi

# =========================================================================
# Cleanup
# =========================================================================
echo -e "\n[CLEANUP] Removing test files..."
rm -f "$TEST_PNG" "$TEST_JPG" "$TEST_WEBP"
echo "✓ Test files removed"

# =========================================================================
# RESULTS
# =========================================================================
echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                     REAL CLOUDINARY TEST RESULTS                       ║"
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
    echo "🎉 ALL TESTS PASSED! Image upload fully functional!"
    echo ""
    echo "Cloudinary URLs generated:"
    if [ -n "$IMAGE_URL_PNG" ] && [ "$IMAGE_URL_PNG" != "null" ]; then
        echo "  PNG: $IMAGE_URL_PNG"
    fi
    if [ -n "$IMAGE_URL_JPG" ] && [ "$IMAGE_URL_JPG" != "null" ]; then
        echo "  JPEG: $IMAGE_URL_JPG"
    fi
    if [ -n "$IMAGE_URL_WEBP" ] && [ "$IMAGE_URL_WEBP" != "null" ]; then
        echo "  WEBP: $IMAGE_URL_WEBP"
    fi
    exit 0
else
    echo "❌ SOME TESTS FAILED"
    exit 1
fi
