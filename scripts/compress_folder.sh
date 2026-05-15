#!/bin/bash

# === Script to compress a full folder into .tar.gz in background using nohup ===
# Usage: compress /path/to/folder

# === Input validation ===
if [ -z "$1" ]; then
  echo "❌ You must provide the path to the folder to compress."
  echo "Usage: compress /path/to/folder"
  exit 1
fi

FOLDER_PATH="$1"

# Check if the folder exists
if [ ! -d "$FOLDER_PATH" ]; then
  echo "❌ The folder '$FOLDER_PATH' does not exist."
  exit 1
fi

# Get folder name and parent directory
FOLDER_NAME=$(basename "$FOLDER_PATH")
PARENT_DIR=$(dirname "$FOLDER_PATH")

# Move to the parent directory to avoid absolute paths in the tar
cd "$PARENT_DIR" || exit 1

# Create the .tar.gz filename and log path with full quotes
TAR_NAME="${FOLDER_NAME}.tar.gz"
LOG_FILE="${FOLDER_NAME}_compress.log"

# Start compression in the background using nohup
echo "📦 Starting background compression of '$FOLDER_NAME' into '$TAR_NAME'..."
nohup sh -c "tar -czf \"$TAR_NAME\" \"$FOLDER_NAME\" && echo \"✅ DONE at \$(date)\" >> \"$LOG_FILE\"" > "$LOG_FILE" 2>&1 &

# Notify user
echo "🔄 Compression started in background. Check progress with:"
echo "   tail -f \"$PARENT_DIR/$LOG_FILE\""
echo "   ps aux | grep tar"
