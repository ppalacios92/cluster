#!/usr/bin/env bash

# Usage:
#   diskjob 143036

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

JOBID="$1"

if [ -z "$JOBID" ]; then
    echo "Usage: diskjob <jobid>"
    exit 1
fi

WORKDIR="$("$SCRIPT_DIR/slurm_path.sh" workdir "$JOBID")"

if [ -z "$WORKDIR" ]; then
    echo "❌ Could not find WorkDir for job $JOBID"
    exit 1
fi

if [ ! -d "$WORKDIR" ]; then
    echo "❌ WorkDir does not exist:"
    echo "$WORKDIR"
    exit 1
fi

echo "📁 Job: $JOBID"
echo "📍 WorkDir: $WORKDIR"
echo

du -sh "$WORKDIR"