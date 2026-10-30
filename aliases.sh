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
# nodes: node usage of the cluster, per partition and per user (read-only: sinfo, squeue, scontrol)
#   nodes      partitions, then every user with running or pending jobs (yours marked with *)
#   nodes -v   the same, plus your running jobs
# NODES counts distinct nodes (a node with several jobs of one user counts once);
# NODES_PD is the sum of the nodes requested by pending jobs.
nodes() {
    local me=${USER:-$(whoami)}
    echo "PARTITION    ALLOC   IDLE  OTHER  TOTAL"
    sinfo -h -o "%P %F" | tr -d '*' | awk '{split($2, a, "/"); printf "%-10s %7d %6d %6d %6d\n", $1, a[1], a[2], a[3], a[4]}'
    echo
    {
        squeue -h -t R -o "%u %N" | while read -r u nl; do
            [ -n "$nl" ] && scontrol show hostnames "$nl" | sed "s/^/R $u /"
        done
        squeue -h -t R -o "%u" | sed 's/^/J /'
        squeue -h -t PD -o "%u %D" | sed 's/^/P /'
    } | awk -v me="$me" '
        $1 == "R" { if (!(($2, $3) in seen)) { seen[$2, $3] = 1; nodes[$2]++ }
                    users[$2] = 1; used[$3] = 1; if ($2 != me) other[$3] = 1 }
        $1 == "J" { jr[$2]++; users[$2] = 1 }
        $1 == "P" { jp[$2]++; np[$2] += $3; users[$2] = 1 }
        END {
            printf "%-16s %6s %7s %8s %9s\n", "USER", "NODES", "JOBS_R", "JOBS_PD", "NODES_PD"
            for (u in users)
                printf "%-16s %6d %7d %8d %9d\n", u (u == me ? "*" : ""),
                       nodes[u], jr[u], jp[u], np[u] | "sort -k2,2nr -k1,1"
            close("sort -k2,2nr -k1,1")
            nu = 0; for (n in used) nu++
            no = 0; for (n in other) no++
            printf "\nYou (%s): %d nodes | other users: %d nodes | in use: %d nodes\n", me, nodes[me], no, nu
        }'
    if [ "$1" = "-v" ]; then
        echo
        squeue -u "$me" -t R -o "%.8i %.32j %.6D %.11M  %N"
    fi
}
