#!/bin/bash

# === SCRIPT TO CANCEL ALL JOBS FROM A SPECIFIC USER ===
# Author: Patricio Palacios B.
# Version: 1.3

# === CHECK FOR USER ARGUMENT ===
if [ -z "$1" ]; then
    echo "❌ You must provide a username. Usage: SOS <username>"
    exit 1
fi

TARGET_USER="$1"

# === GET USER JOB IDs ===
USER_JOBS=$(squeue -u "$TARGET_USER" -h -o "%A")

# === CHECK IF THERE ARE ANY JOBS ===
if [ -z "$USER_JOBS" ]; then
    echo "⚠️ No jobs found for user '$TARGET_USER'."
    exit 0
fi

# === DISPLAY FULL TABLE BEFORE CONFIRMATION ===
echo "🚨 TARGET USER: $TARGET_USER"
echo "🔍 JOBS TO BE CANCELLED:"
echo "============================================"
squeue -u "$TARGET_USER" -o "%.10A %.10P %.20j %.10u %.10T %.5D %.20R"
echo "============================================"
echo

read -rp "Do you want to cancel all these jobs? (y/n): " CONFIRM
if [[ "$CONFIRM" =~ ^[yY]$ ]]; then
    echo "⏳ Cancelling jobs..."
    scancel $USER_JOBS
    echo "✅ ALL JOBS FROM USER --- $TARGET_USER --- HAVE BEEN CANCELLED."
else
    echo "❌ Operation aborted by user."
fi

echo "LARGA VIDA AL LADRUÑO!!! 🏴‍☠️"
