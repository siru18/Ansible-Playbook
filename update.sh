#!/bin/bash

# Email address to send report to
TO="srinisudhan.balaji@aravind.org"

# Validate email format
if ! [[ "$TO" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
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
            apt update -q -y 2>/dev/null
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

} &> "$LOG_FILE"

# Prepare email content
SUBJECT="✅ System Patch Complete on $(hostname)"
CURRENT_DATE=$(date '+%Y-%m-%d %H:%M:%S')
BODY="Ansible patching completed successfully on $(hostname) at $CURRENT_DATE.

Please find the patch update log below:

$(cat $LOG_FILE)
"

# Send email
echo "$BODY" | mail -s "$SUBJECT" "$TO"
