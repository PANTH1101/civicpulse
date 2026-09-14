#!/bin/bash

BASE_URL="http://localhost:4000/api"

# Create citizen
CITIZEN_EMAIL="testcitizen$(date +%s)@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Citizen\",\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

echo "Citizen token: ${CITIZEN_TOKEN:0:20}..."

# Create moderator
MOD_EMAIL="testmod$(date +%s)@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Mod\",\"email\":\"$MOD_EMAIL\",\"password\":\"password123\",\"role\":\"MODERATOR\"}" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$MOD_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')

echo "Moderator token: ${MOD_TOKEN:0:20}..."

# Create department
DEPT_EMAIL="testdept$(date +%s)@example.com"
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Test Dept\",\"email\":\"$DEPT_EMAIL\",\"password\":\"password123\",\"role\":\"DEPARTMENT\",\"mobile\":\"1234567890\",\"office_address\":\"Test\"}" > /dev/null

DEPT_RESPONSE=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$DEPT_EMAIL\",\"password\":\"password123\"}")

DEPT_TOKEN=$(echo "$DEPT_RESPONSE" | jq -r '.token')
DEPT_ID=$(echo "$DEPT_RESPONSE" | jq -r '.user.department_id')

echo "Department token: ${DEPT_TOKEN:0:20}..."
echo "Department ID: $DEPT_ID"

# Create issue
echo -e "\n=== Creating issue ==="
ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Test Issue" \
    -F "description=Test description" \
    -F "category=ROADS" \
    -F "location=Test location")

echo "$ISSUE_RESP" | jq '.'
ISSUE_ID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
echo "Issue ID: $ISSUE_ID"

# Verify
echo -e "\n=== Verifying issue ==="
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" | jq '.message'

# Assign
echo -e "\n=== Assigning to department ==="
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}" | jq '.message'

# Start
echo -e "\n=== Department starting work ==="
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" | jq '.message'

# Create evidence image
TEST_JPG="/tmp/evidence_test.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

# Resolve
echo -e "\n=== Resolving issue with evidence ==="
RESOLVE_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Issue fixed successfully" \
    -F "evidence=@$TEST_JPG")

echo "$RESOLVE_RESP" | jq '.'

# Cleanup
rm -f "$TEST_JPG"
