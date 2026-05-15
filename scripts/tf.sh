#!/usr/bin/env bash

# Usage:
#   tf
#   tf log.log
#   tf log 143036
#   tf 143036

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$1" = "log" ] && [ -n "$2" ]; then
    LOG_FILE="$("$SCRIPT_DIR/slurm_path.sh" stdout "$2")"

elif [[ "$1" =~ ^[0-9]+$ ]]; then
    LOG_FILE="$("$SCRIPT_DIR/slurm_path.sh" stdout "$1")"

else
    LOG_FILE="${1:-log.log}"
fi

if [ -z "$LOG_FILE" ]; then
    echo "❌ Could not find log file."
    exit 1
fi

if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file does not exist:"
    echo "$LOG_FILE"
    exit 1
fi

echo "📄 Following log:"
echo "$LOG_FILE"
echo

tail -n 50 -f "$LOG_FILE"