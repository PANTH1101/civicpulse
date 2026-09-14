#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"
TIMESTAMP=$(date +%s)

# Create test users
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Assign Citizen\",\"email\":\"assign_cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"assign_cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Assign Moderator\",\"email\":\"assign_mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "$MONGO_URI" --quiet --eval "db.users.updateOne({email: 'assign_mod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"assign_mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create department user
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Assign Dept\",\"email\":\"assign_dept_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

DEPT_ID=$(mongosh "$MONGO_URI" --quiet --eval "
const u = db.users.findOne({email: 'assign_dept_${TIMESTAMP}@test.com'});
db.users.updateOne({_id: u._id}, {\$set: {role: 'DEPARTMENT', mobile: '1234567890', office_address: 'Test', department_id: u._id}});
print(u._id.toString());
" | grep -o '[0-9a-f]\{24\}')

echo "Created department ID: $DEPT_ID"

# Create issue
IR=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Assign Test ${TIMESTAMP}" -F "description=Test" -F "category=ROADS" -F "location=Test")
IID=$(echo "$IR" | jq -r '.issue.id')

echo "Created issue: $IID"

# Verify issue
curl -s -X PATCH "$BASE_URL/issues/$IID/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json" > /dev/null
echo "Verified issue"

# Assign issue
echo -e "\n=== ASSIGNING ISSUE ==="
ASSIGN_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/assign" -H "Authorization: Bearer $MOD_TOKEN" \
    -H "Content-Type: application/json" -d "{\"department_id\":\"$DEPT_ID\"}")
echo "$ASSIGN_RESP" | jq '.'

echo -e "\n=== CHECKING ASSIGNED ISSUE IN MODERATOR LIST ==="
curl -s -X GET "$BASE_URL/issues/moderator?status=ASSIGNED" -H "Authorization: Bearer $MOD_TOKEN" | jq ".issues[] | select(.id == \"$IID\")"

echo -e "\n=== CHECKING IN DATABASE ==="
mongosh "$MONGO_URI" --quiet --eval "db.issues.findOne({_id: ObjectId('$IID')})" | jq '.'
