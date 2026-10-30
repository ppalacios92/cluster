#!/usr/bin/env bash

# Usage:
#   tf                 follow ./log.log
#   tf file.log        follow a file
#   tf <jobid>         Slurm job: running -> header, last 20 lines, follow, notice when it ends
#                                 pending -> notice (no output yet)
#                                 finished -> last 50 lines and a summary
#   tf log <jobid>     Slurm record of the job: state, times, nodes, CPUs, memory and disk
#
# Slurm forgets a job 300 s after it ends (MinJobAge) and has no accounting (sacct), so the
# log of a finished job is found in ~/.cache/tf_jobs.tsv (job -> log, filled every time tf
# runs) or, as a last resort, by name (*-<jobid>.out) under the project disks.

REGISTRY="$HOME/.cache/tf_jobs.tsv"
SEARCH_ROOTS=(/mnt/leviathanchest/pxpalacios /mnt/deadmanschest/pxpalacios /mnt/krakenschest/home/pxpalacios)
POLL=20

mkdir -p "$(dirname "$REGISTRY")"; touch "$REGISTRY"

# remember job -> stdout of every job of the user that Slurm still knows
record_jobs() {
    scontrol -o show job 2>/dev/null | awk -v u="$USER" '
        $0 ~ "UserId="u"\\(" {
            id = ""; out = ""
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^JobId=/)  id  = substr($i, 7)
                if ($i ~ /^StdOut=/) out = substr($i, 8)
            }
            if (id != "" && out != "") print id "\t" out
        }' >> "$REGISTRY"
    sort -u -o "$REGISTRY" "$REGISTRY"
}

# one field of 'scontrol show job' (empty if Slurm no longer knows the job)
job_field() {
    scontrol -o show job "$1" 2>/dev/null | tr ' ' '\n' | awk -v k="$2" 'index($0, k "=") == 1 {print substr($0, length(k) + 2); exit}'
}

find_log() {
    local id=$1 log
    log="$(job_field "$id" StdOut)"
    [ -z "$log" ] && log="$(awk -F'\t' -v id="$id" '$1 == id {print $2}' "$REGISTRY" | tail -1)"
    if [ -z "$log" ] || [ ! -f "$log" ]; then
        echo "🔎 Slurm no longer knows job $id; searching the disks for its .out (~20 s)..." >&2
        log="$(find "${SEARCH_ROOTS[@]}" -maxdepth 7 \
                \( -name greens_functions -o -name out -o -name .git -o -name v_ENV -o -name perf \) -prune -o \
                -type f \( -name "*-$id.out" -o -name "*_$id.out" -o -name "slurm-$id.out" \) -print 2>/dev/null | head -1)"
        [ -n "$log" ] && printf '%s\t%s\n' "$id" "$log" >> "$REGISTRY"
    fi
    echo "$log"
}

# progress bars of ShakerMaker may be written with \r: show them as separate lines
clean() { tr '\r' '\n' | grep -v '^[[:space:]]*$'; }

summary() {
    echo "── summary ──"
    # after a 'done' line, the 'task N: Killed' lines are the /scratch guard step being stopped (normal)
    local guard='^$'
    clean < "$1" | grep -q ' done$' && guard='srun: error: .*: task [0-9]+: Killed'
    clean < "$1" | grep -E ' done$|Total time: [0-9.]+ hrs|^stage 2:|^rup_bl_[0-9]+: |Traceback|Error|ERROR|CANCELLED AT|oom|Killed' \
        | grep -v 'STEP .* CANCELLED' | grep -vE "$guard" | tail -10
}

follow_job() {
    local id=$1 log=$2 tpid st ec
    tail -n 0 -F "$log" 2>/dev/null | tr '\r' '\n' &
    tpid=$!
    trap 'kill $tpid 2>/dev/null; echo; exit 0' INT TERM
    while squeue -h -j "$id" 2>/dev/null | grep -q .; do sleep "$POLL"; done
    sleep 2
    kill "$tpid" 2>/dev/null
    echo
    echo "■ Job $id left execution ($(date '+%Y-%m-%d %H:%M'))."
    st="$(job_field "$id" JobState)"; ec="$(job_field "$id" ExitCode)"
    [ -n "$st" ] && echo "  final state: $st   exit code: $ec"
    summary "$log"
}

show_job() {
    local id=$1 state st name nodes elapsed reason nnodes log js ec
    record_jobs
    state="$(squeue -h -j "$id" -o '%T|%j|%N|%M|%r|%D' 2>/dev/null)"
    IFS='|' read -r st name nodes elapsed reason nnodes <<< "$state"
    case "$st" in
        RUNNING|COMPLETING)
            log="$(find_log "$id")"
            echo "▶ Job $id ($name) running on $nnodes nodes [$nodes] for $elapsed. Ctrl+C to exit."
            echo "  $log"
            echo
            if [ -f "$log" ]; then
                clean < "$log" | tail -n 20
                follow_job "$id" "$log"
            else
                echo "  (no output in the .out yet)"
            fi
            ;;
        PENDING|CONFIGURING|SUSPENDED|REQUEUED)
            log="$(job_field "$id" StdOut)"
            echo "⏳ Job $id ($name) in the queue: $st, reason $reason. No output yet."
            [ -n "$log" ] && echo "  will write to: $log"
            ;;
        *)
            log="$(find_log "$id")"
            if [ -z "$log" ] || [ ! -f "$log" ]; then
                echo "❌ Could not find the .out of job $id (not in Slurm, $REGISTRY or the disks)."
                exit 1
            fi
            js="$(job_field "$id" JobState)"; ec="$(job_field "$id" ExitCode)"
            echo "■ Job $id finished. Last write to the .out: $(date -r "$log" '+%Y-%m-%d %H:%M')"
            if [ -n "$js" ]; then
                echo "  final state: $js   exit code: $ec"
            else
                echo "  final state and exit code: not available (Slurm forgets a job 300 s after it ends and has no accounting)"
            fi
            echo "  $log"
            echo
            clean < "$log" | tail -n 50
            echo
            summary "$log"
            ;;
    esac
}

show_record() {
    local id=$1 rec log perf
    record_jobs
    rec="$(scontrol -o show job "$id" 2>/dev/null)"
    if [ -n "$rec" ]; then
        echo "📋 Slurm record of job $id"
        echo "$rec" | tr ' ' '\n' | grep -E '^(JobName|JobState|Reason|ExitCode|SubmitTime|StartTime|EndTime|RunTime|NodeList|NumNodes|NumCPUs|NumTasks|CPUs/Task|TRES|Partition|WorkDir|StdOut)=' \
            | sed 's/^/  /'
        if squeue -h -j "$id" -t RUNNING 2>/dev/null | grep -q .; then
            echo "  usage per step (sstat): step | max memory | node | disk read | disk written"
            sstat -n -P -a -j "$id" -o JobID,MaxRSS,MaxRSSNode,MaxDiskRead,MaxDiskWrite 2>/dev/null | sed 's/^/    /'
        fi
        return
    fi
    log="$(find_log "$id")"
    echo "📋 Slurm no longer has a record of job $id (it forgets it 300 s after it ends; no accounting)."
    [ -z "$log" ] && { echo "❌ Its .out was not found either."; exit 1; }
    echo "  .out: $log  (last write $(date -r "$log" '+%Y-%m-%d %H:%M'))"
    perf="$(ls -d "$(dirname "$log")"/perf/*_"$id" 2>/dev/null | head -1)"
    if [ -n "$perf" ] && [ -f "$perf/slurm_start.txt" ]; then
        echo "  record saved by the job ($perf):"
        grep -hoE '(JobName|SubmitTime|StartTime|NodeList|NumNodes|NumCPUs|TRES)=[^ ]+' "$perf/slurm_start.txt" | sed 's/^/    /'
        [ -f "$perf/slurm_end.txt" ] && grep -hoE 'RunTime=[^ ]+' "$perf/slurm_end.txt" | sed 's/^/    at the end of the script: /'
    fi
}

if [ "$1" = "log" ] && [[ "$2" =~ ^[0-9]+(_[0-9]+)?$ ]]; then
    show_record "$2"
elif [[ "$1" =~ ^[0-9]+(_[0-9]+)?$ ]]; then
    show_job "$1"
else
    LOG_FILE="${1:-log.log}"
    if [ ! -f "$LOG_FILE" ]; then
        echo "❌ Log file does not exist:"
        echo "$LOG_FILE"
        exit 1
    fi
    echo "📄 Following log:"
    echo "$LOG_FILE"
    echo
    tail -n 50 -f "$LOG_FILE"
fi
