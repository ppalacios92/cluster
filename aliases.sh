#!/usr/bin/env bash

# Get the directory where this aliases.sh file lives
CLUSTER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLUSTER_TOOLS="$CLUSTER_ROOT/scripts"

alias SOS="$CLUSTER_TOOLS/sos.sh"
alias tf="$CLUSTER_TOOLS/tf.sh"
alias extract="$CLUSTER_TOOLS/extract_folder.sh"
alias compress="$CLUSTER_TOOLS/compress_folder.sh"
alias diskjob="$CLUSTER_TOOLS/diskjob.sh"

gotojob() {
    if [ -z "$1" ]; then
        echo "Usage: gotojob <jobid>"
        return 1
    fi

    local workdir
    workdir="$("$CLUSTER_TOOLS/slurm_path.sh" workdir "$1")"

    if [ -z "$workdir" ]; then
        echo "❌ Could not find WorkDir for job $1"
        return 1
    fi

    if [ ! -d "$workdir" ]; then
        echo "❌ WorkDir does not exist:"
        echo "$workdir"
        return 1
    fi

    echo "📍 cd $workdir"
    cd "$workdir" || return 1
}