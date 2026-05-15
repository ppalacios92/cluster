#!/usr/bin/env bash
# ============================================================================
# quick_ram.sh - Quick per-node RAM table (Slurm only, no SSH)
# ----------------------------------------------------------------------------
# Single-line summary per node showing:
#   TOTAL_GB   - physical memory reported to Slurm (RealMemory)
#   RSV_GB     - memory reserved by running jobs    (AllocMem)
#   FREE_GB    - memory actually free on the OS     (FreeMem)
#   USED_GB    - TOTAL - FREE
#   USED%      - real usage percentage (not reserved)
# ============================================================================

echo "NODE     STATE    TOTAL_GB   RSV_GB   FREE_GB   USED_GB  USED%"
echo "--------------------------------------------------------------------"

scontrol show nodes 2>/dev/null | awk '
    /^NodeName=/ { split($1, a, "="); node=a[2] }
    /RealMemory=/ {
        real=""; alloc=""; free=""
        for (i=1; i<=NF; i++) {
            if (match($i, /RealMemory=/)) { split($i, x, "="); real=x[2] }
            if (match($i, /AllocMem=/))   { split($i, x, "="); alloc=x[2] }
            if (match($i, /FreeMem=/))    { split($i, x, "="); free=x[2] }
        }
    }
    /State=/ {
        state=""
        for (i=1; i<=NF; i++) {
            if (match($i, /^State=/)) { split($i, x, "="); state=x[2] }
        }
        if (free == "N/A" || free == "") {
            printf "%-8s %-8s %8.1f %8.1f %9s %9s %5s\n", \
                node, state, real/1024, alloc/1024, "N/A", "N/A", "N/A"
        } else {
            used = real - free
            pct  = (used * 100) / real
            printf "%-8s %-8s %8.1f %8.1f %9.1f %9.1f %4d%%\n", \
                node, state, real/1024, alloc/1024, free/1024, used/1024, pct
        }
    }
'
