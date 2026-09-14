#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"
TIMESTAMP=$(date +%s)

# Setup
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Debug Cit\",\"email\":\"dbgcit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CIT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"dbgcit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Debug Mod\",\"email\":\"dbgmod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 'dbgmod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"dbgmod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

DEPT_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const dept = db.departments.findOne({name: 'Roads and Transportation Department'});
print(dept._id.toString());
" | grep -o '[0-9a-f]\{24\}')

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Debug Dept\",\"email\":\"dbgdept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'dbgdept_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: ObjectId('$DEPT_ID')}});
" > /dev/null

DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"dbgdept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create and process issue
ISSUE_ID=$(curl -s -X POST "$BASE_URL/issues" \
    -H "Authorization: Bearer $CIT_TOKEN" \
    -F "title=Debug Resolution" -F "description=Test" -F "category=ROADS" -F "location=Test" | jq -r '.issue.id')

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/verify" \
    -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/assign" \
    -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"department_id\":\"$DEPT_ID\"}" > /dev/null

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/start" \
    -H "Authorization: Bearer $DEPT_TOKEN" -H "Content-Type: application/json" > /dev/null

echo "Issue status before resolve:"
mongosh "$MONGO_URI" --quiet --eval "db.issues.findOne({_id: ObjectId('$ISSUE_ID')}).status"

echo "Attempting resolve..."
echo "test_evidence_data" > /tmp/test_evidence.jpg

curl -s -X PATCH "$BASE_URL/issues/$ISSUE_ID/resolve" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -F "resolution_description=Fixed it" \
    -F "evidence=@/tmp/test_evidence.jpg" | jq '.'

rm -f /tmp/test_evidence.jpg
