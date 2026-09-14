#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"

TIMESTAMP=$(date +%s)
HASHED_PW='$2a$10$N9qo8uLOickgx2ZMRZoMye/IVI9Bt/AQ8SJu3OY4TXUxQ7Q8T0.LK'

# Create citizen in DB
mongosh "$MONGO_URI" --quiet --eval "
db.users.insertOne({
    name: 'TestAuth',
    email: 'testauth${TIMESTAMP}@test.com',
    password: '$HASHED_PW',
    role: 'CITIZEN',
    createdAt: new Date(),
    updatedAt: new Date()
})
" > /dev/null

echo "User created in DB"

# Login
LOGIN_RESP=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"testauth${TIMESTAMP}@test.com\",\"password\":\"password123\"}")

echo "Login response:"
echo "$LOGIN_RESP" | jq '.'

TOKEN=$(echo "$LOGIN_RESP" | jq -r '.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
    echo "❌ Login failed"
    exit 1
fi

echo "Token: ${TOKEN:0:50}..."

# Test protected route
PROTECTED_RESP=$(curl -s -X GET "$BASE_URL/auth/protected" \
    -H "Authorization: Bearer $TOKEN")

echo "Protected route response:"
echo "$PROTECTED_RESP" | jq '.'

# Test profile
PROFILE_RESP=$(curl -s -X GET "$BASE_URL/auth/profile" \
    -H "Authorization: Bearer $TOKEN")

echo "Profile response:"
echo "$PROFILE_RESP" | jq '.'
