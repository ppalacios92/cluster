#!/usr/bin/env bash

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
SOURCE_LINE="source $REPO_DIR/aliases.sh"

echo "Installing cluster tools..."
echo "Repo path: $REPO_DIR"

chmod +x "$REPO_DIR"/scripts/*.sh
chmod +x "$REPO_DIR"/aliases.sh

if grep -Fxq "$SOURCE_LINE" "$BASHRC"; then
    echo "aliases.sh is already sourced in $BASHRC"
else
    echo "" >> "$BASHRC"
    echo "# Cluster tools" >> "$BASHRC"
    echo "$SOURCE_LINE" >> "$BASHRC"
    echo "Added aliases.sh to $BASHRC"
fi

echo "Done."
echo "Run:"
echo "  source ~/.bashrc"