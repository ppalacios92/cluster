#!/usr/bin/env bash

# Usage:
#   slurm_path.sh stdout <jobid>
#   slurm_path.sh workdir <jobid>

set -e

MODE="$1"
JOBID="$2"

if [ -z "$MODE" ] || [ -z "$JOBID" ]; then
    echo "Usage: slurm_path.sh <stdout|workdir|command> <jobid>"
    exit 1
fi

case "$MODE" in
    stdout)
        scontrol show job "$JOBID" | awk -F= '/StdOut=/{print $2}'
        ;;
    workdir)
        scontrol show job "$JOBID" | awk -F= '/WorkDir=/{print $2}'
        ;;
    command)
        scontrol show job "$JOBID" | awk -F= '/Command=/{print $2}'
        ;;
    *)
        echo "Unknown mode: $MODE"
        echo "Use: stdout, workdir, command"
        exit 1
        ;;
esac