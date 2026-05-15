#!/usr/bin/env bash
CLUSTER_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# ---------------------------------------------------------
CLUSTER_TOOLS="$CLUSTER_ROOT/scripts"

get_ladruno() {
    "$CLUSTER_TOOLS/get_ladruno.sh"
}

# alias_name:script_name
TOOLS=(
    "SOS:sos.sh"
    "tf:tf.sh"
    "extract:extract_folder.sh"
    "compress:compress_folder.sh"
    "diskjob:diskjob.sh"
    "sw4run:sw4run.sh"
)

# Create normal aliases and ladruno_ aliases
# Both execute the script directly.
# No banner here.
for item in "${TOOLS[@]}"; do
    name="${item%%:*}"
    script="${item##*:}"
    alias "$name=$CLUSTER_TOOLS/$script"
    alias "ladruno_$name=$CLUSTER_TOOLS/$script"
done
# ---------------------------------------------------------
# QA / monitoring tools (separate folder)
CLUSTER_QA="$CLUSTER_ROOT/qa"

QA_TOOLS=(
    "cluster_status:cluster_status.sh"
    "quick_ram:quick_ram.sh"
    "watch_cluster:watch_cluster.sh"
)

for item in "${QA_TOOLS[@]}"; do
    name="${item%%:*}"
    script="${item##*:}"
    alias "$name=$CLUSTER_QA/$script"
    alias "ladruno_$name=$CLUSTER_QA/$script"
done
# ---------------------------------------------------------
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

ladruno_gotojob() {
    gotojob "$@"
}