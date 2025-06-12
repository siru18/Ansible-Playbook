#!/bin/bash

TO="aravind_slcs_intern2@aravind.org"
LOG_FILE="/tmp/notify.log"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# Validate email format
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo "[$CURRENT_DATE] Invalid email address format: $TO. Skipping email." >> "$LOG_FILE"
    exit 1
fi

# Run updates
UPDATE_OUTPUT=$(apt update && apt -y upgrade 2>&1)
STATUS=$?

SUBJECT="✅ System Patch Complete on $HOSTNAME"
BODY="Ansible patching completed on $HOSTNAME at $CURRENT_DATE.

Update result:
$UPDATE_OUTPUT
"

# Attempt to send mail
echo "$BODY" | mail -s "$SUBJECT" "$TO"

if [[ $? -eq 0 ]]; then
    echo "[$CURRENT_DATE] Patch notification sent to $TO from $HOSTNAME." >> "$LOG_FILE"
else
    echo "[$CURRENT_DATE] Failed to send patch notification email to $TO." >> "$LOG_FILE"
fi

# Log the apt command result
if [[ $STATUS -ne 0 ]]; then
    echo "[$CURRENT_DATE] apt update/upgrade exited with error status $STATUS." >> "$LOG_FILE"
fi
