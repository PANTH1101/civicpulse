#!/bin/bash

BASE_URL="http://localhost:4000/api"
MONGO_URI="mongodb://127.0.0.1:27017/civicpulse"
TIMESTAMP=$(date +%s)

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

echo "Testing limit=0:"
curl -s -X GET "$BASE_URL/departments/my-issues?limit=0" \
    -H "Authorization: Bearer $DEPT_TOKEN" | jq '{message, limit}'
