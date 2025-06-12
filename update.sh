#!/bin/sh

# Email address to send report to
TO="srinisudhan.balaji@aravind.org"

# Validate email format (POSIX-safe)
echo "$TO" | grep -E "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Invalid email address format. Aborting email send."
    exit 1
fi

# Prepare log file with timestamp
LOG_FILE="/tmp/patch_report_$(date +%F_%H-%M-%S).log"

{
    echo "=== Patch Report: $(date) on $(hostname) ==="
    echo ""

    # Detect OS
    echo "Detecting OS..."
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
    else
        echo "OS detection failed."
        exit 1
    fi
    echo "Detected OS: $OS_ID"
    echo ""

    # Update based on OS
    case "$OS_ID" in
        ubuntu|debian)
            echo "Running apt update and upgrade..."
            apt update -q -y >/dev/null 2>&1
            UPGRADE_OUTPUT=$(apt -y upgrade 2>/dev/null)
            if echo "$UPGRADE_OUTPUT" | grep -q "0 upgraded"; then
                echo "No packages needed upgrading."
            else
                echo "Some packages were upgraded."
            fi
            ;;
        centos|rhel|fedora)
            echo "Running yum/dnf update..."
            if command -v dnf >/dev/null 2>&1; then
                UPDATE_OUTPUT=$(dnf -y upgrade 2>/dev/null)
            else
                UPDATE_OUTPUT=$(yum -y update 2>/dev/null)
            fi
            if echo "$UPDATE_OUTPUT" | grep -q "No packages marked for update"; then
                echo "No packages needed upgrading."
            else
                echo "Some packages were upgraded."
            fi
            ;;
        *)
            echo "Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    echo ""
    echo "Patch update completed at $(date)."

} > "$LOG_FILE" 2>&1

# Email subject and body
SUBJECT="✅ System Patch Complete on $(hostname)"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BODY="Ansible patching completed successfully on $(hostname) at $CURRENT_DATE.

Please find the patch update log below:

$(cat "$LOG_FILE")
"

# Send email
echo "$BODY" | mail -s "$SUBJECT" "$TO"
notify.sh
#!/bin/bash

TO="srinisudhan.balaji@aravind.org"
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
