#!/usr/bin/env bash
# ============================================================================
# cluster_status.sh - Cluster-wide status overview (Slurm only, no sudo)
# ----------------------------------------------------------------------------
# Shows node properties: state, CPU, RAM (reserved by Slurm vs really used),
# CPU load and jobs. Optionally inspects disks and per-node details via SSH.
#
# Usage:
#   cluster_status              # full report (summary + ram + cpu + jobs + local disks)
#   cluster_status summary      # cluster-level aggregate (totals and percentages)
#   cluster_status ram          # per-node RAM table with usage bars
#   cluster_status cpu          # per-node CPU allocation and load
#   cluster_status jobs         # running jobs and queue summary
#   cluster_status overview     # raw sinfo, one line per node
#   cluster_status disk         # local disks (master) + remote disks via SSH
#   cluster_status disklocal    # only master disks (no SSH)
#   cluster_status diskremote   # only remote disks on every node (SSH)
#   cluster_status node <N>     # detailed view of nodeN (Slurm info + SSH probe)
#   cluster_status help
# ============================================================================

# --- SSH options used for remote probing -----------------------------------
SSH_OPTS="-o ConnectTimeout=3 -o StrictHostKeyChecking=no -o BatchMode=yes"

# --- Colors -----------------------------------------------------------------
G='\033[0;32m'   # green
Y='\033[1;33m'   # yellow
R='\033[0;31m'   # red
B='\033[1;34m'   # blue
C='\033[0;36m'   # cyan
N='\033[0m'      # reset

# --- Helpers ----------------------------------------------------------------
hr()     { printf '%.0s-' {1..80}; echo; }
header() { echo; echo -e "${B}=== $1 ===${N}"; }

# Returns a color code based on a 0-100 percentage
pct_color() {
    local p=$1
    if   [ "$p" -ge 90 ]; then echo -ne "$R"
    elif [ "$p" -ge 70 ]; then echo -ne "$Y"
    else                       echo -ne "$G"
    fi
}

# Detect node list dynamically from sinfo (no hardcoded count)
get_nodes() {
    sinfo -h -N -o "%n" 2>/dev/null | sort -u
}

# --- Views ------------------------------------------------------------------

view_slurm_overview() {
    header "SLURM OVERVIEW (sinfo)"
    sinfo -o "%10n %8t %5c %8m %8e %10O" 2>/dev/null
}

view_ram() {
    header "RAM USAGE PER NODE"
    printf "%-8s %-8s %10s %10s %10s %6s %s\n" \
        "NODE" "STATE" "TOTAL_MB" "RSV_MB" "FREE_MB" "USED%" "BAR"
    hr

    # Parse `scontrol show nodes` in a single pass
    scontrol show nodes 2>/dev/null | awk '
        /^NodeName=/   { split($1, a, "="); node=a[2] }
        /RealMemory=/  {
            for (i=1; i<=NF; i++) {
                if (match($i, /RealMemory=/)) { split($i, x, "="); real=x[2] }
                if (match($i, /AllocMem=/))   { split($i, x, "="); alloc=x[2] }
                if (match($i, /FreeMem=/))    { split($i, x, "="); free=x[2] }
            }
        }
        /State=/ {
            for (i=1; i<=NF; i++) {
                if (match($i, /^State=/)) { split($i, x, "="); state=x[2] }
            }
            print node, state, real, alloc, free
            real=""; alloc=""; free=""; state=""
        }
    ' | while read -r node state real alloc free; do
        if [ "$free" = "N/A" ] || [ -z "$free" ]; then
            printf "%-8s ${R}%-8s${N} %10s %10s %10s %6s %s\n" \
                "$node" "$state" "$real" "$alloc" "N/A" "N/A" "(node down)"
            continue
        fi
        used=$((real - free))
        pct=$((used * 100 / real))
        bar_len=$((pct / 5))   # bar 0-20 chars
        bar=$(printf '%*s' "$bar_len" '' | tr ' ' '#')
        col=$(pct_color "$pct")
        printf "%-8s %-8s %10s %10s %10s ${col}%5s%%${N} ${col}%-20s${N}\n" \
            "$node" "$state" "$real" "$alloc" "$free" "$pct" "$bar"
    done

    echo
    echo -e "${C}Note:${N} RSV_MB  = memory Slurm has reserved (AllocMem)."
    echo -e "      FREE_MB = memory actually free in the OS (FreeMem)."
    echo -e "      USED%   = (TOTAL - FREE) / TOTAL, the real usage."
}

view_cpu() {
    header "CPU USAGE PER NODE"
    printf "%-8s %-8s %6s %6s %8s %s\n" \
        "NODE" "STATE" "TOT" "ALLOC" "LOAD" "BAR"
    hr

    scontrol show nodes 2>/dev/null | awk '
        /^NodeName=/ { split($1, a, "="); node=a[2] }
        /CPUAlloc=/ {
            for (i=1; i<=NF; i++) {
                if (match($i, /CPUAlloc=/)) { split($i, x, "="); alloc=x[2] }
                if (match($i, /CPUTot=/))   { split($i, x, "="); tot=x[2] }
                if (match($i, /CPULoad=/))  { split($i, x, "="); load=x[2] }
            }
        }
        /State=/ {
            for (i=1; i<=NF; i++) {
                if (match($i, /^State=/)) { split($i, x, "="); state=x[2] }
            }
            print node, state, tot, alloc, load
            tot=""; alloc=""; load=""; state=""
        }
    ' | while read -r node state tot alloc load; do
        if [ "$load" = "N/A" ] || [ -z "$load" ]; then
            printf "%-8s ${R}%-8s${N} %6s %6s %8s %s\n" \
                "$node" "$state" "$tot" "$alloc" "N/A" "(node down)"
            continue
        fi
        # Load relative to total CPUs (cap at 100)
        pct=$(awk -v l="$load" -v t="$tot" 'BEGIN{printf "%d", (l/t)*100}')
        [ "$pct" -gt 100 ] && pct=100
        bar_len=$((pct / 5))
        bar=$(printf '%*s' "$bar_len" '' | tr ' ' '#')
        col=$(pct_color "$pct")
        printf "%-8s %-8s %6s %6s ${col}%8s${N} ${col}%-20s${N}\n" \
            "$node" "$state" "$tot" "$alloc" "$load" "$bar"
    done
}

view_jobs() {
    header "RUNNING JOBS"
    squeue -o "%.10i %.9P %.20j %.8u %.2t %.10M %.6D %R %m" 2>/dev/null

    header "QUEUE SUMMARY BY USER"
    squeue -h -o "%u %t" 2>/dev/null | sort | uniq -c | sort -rn
}

view_disks_local() {
    header "DISKS ON MASTER (local)"
    df -h | grep -vE '^tmpfs|^efivarfs|^/dev/loop'
}

view_disks_remote() {
    header "DISKS PER NODE (via SSH)"
    echo -e "${C}Probing each node over SSH (3s timeout)...${N}"
    echo

    for node in $(get_nodes); do
        printf "${B}--- %s ---${N}\n" "$node"
        ssh $SSH_OPTS "$node" \
            'df -h 2>/dev/null | grep -vE "^tmpfs|^efivarfs|^/dev/loop|^Filesystem"' \
            2>/dev/null \
            || echo -e "  ${R}(no SSH access or node down)${N}"
    done
}

view_node_detail() {
    local n=$1
    local node="node${n}"
    header "FULL DETAIL FOR $node"

    echo -e "${C}--- Slurm view ---${N}"
    scontrol show node "$node" 2>/dev/null

    echo
    echo -e "${C}--- Live view via SSH ---${N}"
    ssh $SSH_OPTS "$node" '
        echo "[hostname]"; hostname
        echo
        echo "[uptime / load]"; uptime
        echo
        echo "[memory]"; free -h
        echo
        echo "[cpu]"; lscpu | grep -E "Model name|^CPU\(s\)|Thread|Socket|Core"
        echo
        echo "[disks]"; df -h | grep -vE "^tmpfs|^efivarfs|^/dev/loop"
        echo
        echo "[top 5 processes by RAM]"
        ps -eo pid,user,pcpu,pmem,rss,comm --sort=-rss | head -6
    ' 2>/dev/null || echo -e "${R}Could not reach $node over SSH${N}"
}

view_summary() {
    header "CLUSTER SUMMARY"
    echo "Date:   $(date)"
    echo "Master: $(hostname)"
    echo

    # Count node states
    local total mix idle down alloc
    mix=$(  sinfo -h -N -o "%t" 2>/dev/null | grep -c '^mix'   )
    idle=$( sinfo -h -N -o "%t" 2>/dev/null | grep -c '^idle'  )
    alloc=$(sinfo -h -N -o "%t" 2>/dev/null | grep -c '^alloc' )
    down=$( sinfo -h -N -o "%t" 2>/dev/null | grep -c '^down'  )
    total=$(sinfo -h -N -o "%n" 2>/dev/null | wc -l)

    echo -e "Nodes total:      ${B}$total${N}"
    echo -e "  Mixed (in use): ${G}$mix${N}"
    echo -e "  Allocated:      ${Y}$alloc${N}"
    echo -e "  Idle (free):    ${G}$idle${N}"
    echo -e "  Down:           ${R}$down${N}"
    echo

    # Aggregated RAM and CPU
    scontrol show nodes 2>/dev/null | awk '
        /RealMemory=/ {
            for (i=1; i<=NF; i++) {
                if (match($i, /RealMemory=/)) { split($i, x, "="); rm+=x[2] }
                if (match($i, /AllocMem=/))   { split($i, x, "="); am+=x[2] }
                if (match($i, /FreeMem=/) && $i !~ /N\/A/) { split($i, x, "="); fm+=x[2] }
                if (match($i, /CPUTot=/))     { split($i, x, "="); ct+=x[2] }
                if (match($i, /CPUAlloc=/))   { split($i, x, "="); ca+=x[2] }
            }
        }
        END {
            if (rm == 0) { print "No node data available."; exit }
            printf "Total cluster RAM:   %.1f GB\n", rm/1024
            printf "RAM reserved (Slurm):%.1f GB (%.0f%%)\n", am/1024, am*100/rm
            printf "RAM free (OS):       %.1f GB\n", fm/1024
            printf "Total CPUs:          %d\n", ct
            printf "CPUs reserved:       %d (%.0f%%)\n", ca, ca*100/ct
        }
    '
}

# --- Main -------------------------------------------------------------------
cmd="${1:-all}"
case "$cmd" in
    all)
        view_summary
        view_slurm_overview
        view_ram
        view_cpu
        view_jobs
        view_disks_local
        ;;
    ram)        view_ram ;;
    cpu)        view_cpu ;;
    jobs)       view_jobs ;;
    disk|disks) view_disks_local; view_disks_remote ;;
    disklocal)  view_disks_local ;;
    diskremote) view_disks_remote ;;
    summary)    view_summary ;;
    overview)   view_slurm_overview ;;
    node)
        if [ -z "$2" ]; then
            echo "Usage: cluster_status node <N>  (e.g. cluster_status node 5)"
            exit 1
        fi
        view_node_detail "$2"
        ;;
    help|-h|--help)
        sed -n '2,22p' "$0"
        ;;
    *)
        echo "Unknown subcommand: $cmd"
        echo "Run: cluster_status help"
        exit 1
        ;;
esac
