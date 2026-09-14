#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

echo "Setting up test data..."

TIMESTAMP=$(date +%s)
HASHED_PW='$2a$10$N9qo8uLOickgx2ZMRZoMye/IVI9Bt/AQ8SJu3OY4TXUxQ7Q8T0.LK'

# Create department with self-referencing ID
DEPT_RESULT=$(mongosh "$MONGO_URI" --quiet --eval "
const result = db.users.insertOne({
    name: 'TestDept',
    email: 'dept${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'DEPARTMENT',
    mobile: '1234567890',
    office_address: 'Test',
    createdAt: new Date(),
    updatedAt: new Date()
});
db.users.updateOne({_id: result.insertedId}, {\$set: {department_id: result.insertedId}});
print(result.insertedId.toString());
")

DEPT_ID=$(echo "$DEPT_RESULT" | grep -o '[0-9a-f]\{24\}' | head -1)

# Create moderator
mongosh "$MONGO_URI" --quiet --eval "
db.users.insertOne({
    name: 'TestMod',
    email: 'mod${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'MODERATOR',
    createdAt: new Date(),
    updatedAt: new Date()
})
" > /dev/null

# Create citizen
mongosh "$MONGO_URI" --quiet --eval "
db.users.insertOne({
    name: 'TestCitizen',
    email: 'citizen${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'CITIZEN',
    createdAt: new Date(),
    updatedAt: new Date()
})
" > /dev/null

echo "Users created. Dept ID: $DEPT_ID"

# Login
CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"citizen${TIMESTAMP}@test.com\",\"password\":\"password123\"}" | jq -r '.token')

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"mod${TIMESTAMP}@test.com\",\"password\":\"password123\"}" | jq -r '.token')

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"dept${TIMESTAMP}@test.com\",\"password\":\"password123\"}" | jq -r '.token')

echo "Logged in. Testing resolve..."

# Create test JPG
TEST_JPG="/tmp/evidence_test.jpg"
echo "/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAIBAQIBAQICAgICAgICAwUDAwMDAwYEBAMFBwYHBwcGBwcICQsJCAgKCAcHCg0KCgsMDAwMBwkODw0MDgsMDAz/2wBDAQICAgMDAwYDAwYMCAcIDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAwMDAz/wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAv/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/8QAFQEBAQAAAAAAAAAAAAAAAAAAAAX/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCwAA8A/9k=" | base64 -d > "$TEST_JPG"

# Create issue -> verify -> assign -> start -> resolve
ISSUE_RESP=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Test Issue" \
    -F "description=Test" \
    -F "category=ROADS" \
    -F "location=Test")

ISSUE_ID=$(echo "$ISSUE_RESP" | jq -r '.issue.id')
echo "Issue created: $ISSUE_ID"

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

echo "Issue is now IN_PROGRESS. Attempting to resolve with evidence..."

RESOLVE_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed the issue successfully" \
    -F "evidence=@$TEST_JPG")

echo "$RESOLVE_RESP" | jq '.'

STATUS=$(echo "$RESOLVE_RESP" | jq -r '.issue.status')
EVIDENCE_URL=$(echo "$RESOLVE_RESP" | jq -r '.issue.resolution_evidence')

echo ""
if [ "$STATUS" = "RESOLVED" ]; then
    echo "✅ Issue resolved successfully!"
    echo "✅ Evidence URL: $EVIDENCE_URL"
    
    if [[ "$EVIDENCE_URL" == *"resolution-evidence"* ]]; then
        echo "✅ Evidence stored in resolution-evidence folder"
    fi
    
    # Test URL accessibility
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
