#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "Testing resolution evidence upload..."

# Login
CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d '{"email":"alice@example.com","password":"citizen123"}' | jq -r '.token')
MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d '{"email":"moderator@civicpulse.gov","password":"moderator123"}' | jq -r '.token')
DEPT_RESP=$(curl -s -X POST "$BASE_URL/auth/login" -H "Content-Type: application/json" -d '{"email":"roads@civicpulse.gov","password":"department123"}')
DEPT_TOKEN=$(echo "$DEPT_RESP" | jq -r '.token')
DEPT_ID=$(echo "$DEPT_RESP" | jq -r '.user.department_id')

echo "✓ Logged in"
echo "  Dept ID: $DEPT_ID"

# Create test image
TEST_JPG="/tmp/evidence_test.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

# Create issue
ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" -F "title=Test Issue" -F "description=Test" -F "category=ROADS" -F "location=Test")
ISSUE_ID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
echo "✓ Issue created: $ISSUE_ID"

# Verify
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
echo "✓ Verified"

# Assign
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null
echo "✓ Assigned"

# Start
curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json" > /dev/null
echo "✓ Started"

# Resolve with evidence
echo -e "\n=== Resolving with evidence ===" 
RESOLVE_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" -H "Authorization: Bearer $DEPT_TOKEN" -F "resolution_description=Road repaired and tested successfully. All potholes filled." -F "evidence=@$TEST_JPG")

echo "$RESOLVE_RESP" | jq '.'

STATUS=$(echo "$RESOLVE_RESP" | jq -r '.issue.status')
EVIDENCE_URL=$(echo "$RESOLVE_RESP" | jq -r '.issue.resolution_evidence')

echo ""
if [ "$STATUS" = "RESOLVED" ]; then
    echo "✅ Issue resolved successfully!"
    echo "✅ Status: $STATUS"
    echo "✅ Evidence URL: $EVIDENCE_URL"
    
    if [[ "$EVIDENCE_URL" == *"resolution-evidence"* ]]; then
        echo "✅ Evidence in correct folder (resolution-evidence)"
    fi
    
    # Test URL
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$EVIDENCE_URL")
    if [ "$HTTP_STATUS" = "200" ]; then
        echo "✅ Evidence URL is accessible (HTTP 200)"
    else
        echo "❌ Evidence URL not accessible (HTTP $HTTP_STATUS)"
    fi
else
    echo "❌ Resolution failed. Status: $STATUS"
fi

rm -f "$TEST_JPG"
