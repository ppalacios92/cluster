#!/bin/bash

# === Script to extract a .tar.gz archive ===
# Usage: extract /path/to/archive.tar.gz

# === Input validation ===
if [ -z "$1" ]; then
  echo "❌ You must provide the path to the .tar.gz archive."
  echo "Usage: extract /path/to/archive.tar.gz"
  exit 1
fi

ARCHIVE_PATH="$1"

# Check if the file exists
if [ ! -f "$ARCHIVE_PATH" ]; then
  echo "❌ File '$ARCHIVE_PATH' does not exist."
  exit 1
fi

# Check if the file has .tar.gz extension
if [[ "$ARCHIVE_PATH" != *.tar.gz ]]; then
  echo "❌ File is not a .tar.gz archive."
  exit 1
fi

# Get directory and archive name
ARCHIVE_DIR=$(dirname "$ARCHIVE_PATH")
ARCHIVE_NAME=$(basename "$ARCHIVE_PATH")

# Go to the archive's directory
cd "$ARCHIVE_DIR" || exit 1

# Extract archive
echo "📂 Extracting '$ARCHIVE_NAME'..."
tar -xzf "$ARCHIVE_NAME"

# Confirmation
if [ $? -eq 0 ]; then
  echo "✅ Successfully extracted: $ARCHIVE_NAME"
else
  echo "⚠️ An error occurred during extraction."
fi
