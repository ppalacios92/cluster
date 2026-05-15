#!/usr/bin/env bash
# ============================================================================
# watch_cluster.sh - Live cluster monitor (refreshes every N seconds)
# ----------------------------------------------------------------------------
# Usage:
#   watch_cluster           # refresh every 5s
#   watch_cluster 10        # refresh every 10s
#
# Exit with Ctrl+C.
# ============================================================================

INTERVAL="${1:-5}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

watch -n "$INTERVAL" -c "
    echo '=== CLUSTER STATUS - ' \$(date) ' ==='
    echo
    $SCRIPT_DIR/quick_ram.sh
    echo
    echo '=== RUNNING JOBS ==='
    squeue -o '%.10i %.9P %.20j %.8u %.2t %.10M %.6D %R'
"
