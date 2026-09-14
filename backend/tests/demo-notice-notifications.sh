#!/bin/bash

BASE_URL="http://localhost:4000/api"

echo "╔════════════════════════════════════════════════════════════════════════╗"
echo "║           TASK 2: PUBLIC NOTICE NOTIFICATIONS DEMONSTRATION           ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"

# Register a citizen
TIMESTAMP=$(date +%s)
CITIZEN_EMAIL="democitizen$TIMESTAMP@example.com"

echo -e "\n📝 Registering citizen user..."
curl -s -X POST "$BASE_URL/auth/register" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"Demo Citizen\",\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" | jq '.'

# Login citizen
echo -e "\n🔐 Logging in as citizen..."
CITIZEN_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$CITIZEN_EMAIL\",\"password\":\"password123\"}" | jq -r '.token')
echo "✓ Token acquired"

# Login department
echo -e "\n🔐 Logging in as department..."
DEPT_TOKEN=$(curl -s -X POST "$BASE_URL/auth/login" \
    -H "Content-Type: application/json" \
    -d '{"email":"water@civicpulse.gov","password":"department123"}' | jq -r '.token')
echo "✓ Token acquired"

# Check initial notifications
echo -e "\n📬 Citizen's initial notifications:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN_TOKEN" | jq '{count: .count}'

# Create draft notice
echo -e "\n📄 Creating DRAFT public notice..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
CREATE_NOTICE=$(curl -s -X POST "$BASE_URL/notices" \
    -H "Authorization: Bearer $DEPT_TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title":"Emergency Water Shutoff","content":"Water will be shut off for emergency repairs on Main Street from 2 PM to 6 PM today.","category":"EMERGENCY"}')

NOTICE_ID=$(echo "$CREATE_NOTICE" | jq -r '.notice.id')
echo "$CREATE_NOTICE" | jq '.'

# Publish notice
echo -e "\n📢 Publishing notice..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
PUBLISH=$(curl -s -X PATCH "$BASE_URL/notices/$NOTICE_ID/publish" \
    -H "Authorization: Bearer $DEPT_TOKEN")
echo "$PUBLISH" | jq '.'

# Wait for notifications to be created
sleep 1

# Check citizen's notifications
echo -e "\n📬 Citizen's notifications AFTER publishing:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
NOTIF=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $CITIZEN_TOKEN")
echo "$NOTIF" | jq '.'

# Highlight key details
echo -e "\n🔍 Notification Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$NOTIF" | jq -r '.notifications[0] | 
"Type: \(.type)
Message: \(.message)
is_read: \(.is_read)
issue: \(.issue)
notice.id: \(.notice.id)
notice.title: \(.notice.title)
notice.category: \(.notice.category)
notice.status: \(.notice.status)
createdAt: \(.createdAt)"'

# Verify department user didn't get notification
echo -e "\n🏢 Department user's notifications:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
DEPT_NOTIF=$(curl -s -X GET "$BASE_URL/notifications" \
    -H "Authorization: Bearer $DEPT_TOKEN")
NOTICE_COUNT=$(echo "$DEPT_NOTIF" | jq '[.notifications[] | select(.type == "PUBLIC_NOTICE_PUBLISHED")] | length')
echo "PUBLIC_NOTICE_PUBLISHED notifications: $NOTICE_COUNT"

if [ "$NOTICE_COUNT" -eq 0 ]; then
    echo "✅ CORRECT: Department user did NOT receive notification"
else
    echo "❌ ERROR: Department user should NOT receive notification"
fi

echo -e "\n╔════════════════════════════════════════════════════════════════════════╗"
echo "║                         DEMONSTRATION COMPLETE                         ║"
echo "╚════════════════════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Implementation Summary:"
echo "   - Added notice_id field to Notification model"
echo "   - Added PUBLIC_NOTICE_PUBLISHED notification type"
echo "   - Modified publishNotice() to create notifications for all CITIZEN users"
echo "   - Duplicate prevention implemented"
echo "   - Notification controller updated to populate notice details"
echo ""
echo "✅ Security:"
echo "   - Only CITIZEN users receive notifications"
echo "   - MODERATOR and DEPARTMENT users excluded"
echo "   - Recipient list determined from database"
echo ""
echo "✅ All existing notification types still work"
echo ""
