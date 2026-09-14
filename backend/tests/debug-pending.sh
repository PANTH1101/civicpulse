#!/bin/bash

BASE_URL="http://localhost:4000/api"
TIMESTAMP=$(date +%s)

# Create test users
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Debug Citizen\",\"email\":\"debug_cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"debug_cit_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Debug Moderator\",\"email\":\"debug_mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" > /dev/null

mongosh "mongodb://127.0.0.1:27017/civicpulse" --quiet --eval "db.users.updateOne({email: 'debug_mod_${TIMESTAMP}@test.com'}, {\$set: {role: 'MODERATOR'}})" > /dev/null

MOD_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"debug_mod_${TIMESTAMP}@test.com\",\"password\":\"Pass123!\"}" | jq -r '.token')

# Create test issue
IR=$(curl -s -X POST "$BASE_URL/issues" -H "Authorization: Bearer $CITIZEN_TOKEN" \
    -F "title=Debug Issue ${TIMESTAMP}" -F "description=Test" -F "category=ROADS" -F "location=Test")
IID=$(echo "$IR" | jq -r '.issue.id')

echo "Created issue: $IID"

echo -e "\n=== BEFORE VERIFY ==="
curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN" | jq '.'

echo -e "\n=== VERIFYING ISSUE ==="
VERIFY_RESP=$(curl -s -X PATCH "$BASE_URL/issues/$IID/verify" -H "Authorization: Bearer $MOD_TOKEN" -H "Content-Type: application/json")
echo "$VERIFY_RESP" | jq '.'

echo -e "\n=== AFTER VERIFY ==="
curl -s -X GET "$BASE_URL/issues/moderator/pending" -H "Authorization: Bearer $MOD_TOKEN"
