#!/usr/bin/env bash

# === Script to submit all .in files in the current folder (recursive) as SW4 Slurm jobs ===
# Usage: sw4run <nodes>
# Example: sw4run 15

# === Input validation ===
if [ -z "$1" ]; then
  echo "❌ You must provide the number of nodes."
  echo "Usage: sw4run <nodes>"
  exit 1
fi

if ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "❌ Nodes must be an integer."
  echo "Usage: sw4run <nodes>"
  exit 1
fi

# === Config ===
NODES="$1"
TASKS_PER_NODE=16
SW4_EXE="sw4"
LIB_PATH="/mnt/nfshare/lib_local"
BASE_DIR="$(pwd)"

# === Find all .in files recursively ===
mapfile -t IN_FILES < <(find "$BASE_DIR" -type f -name "*.in" | sort)

if [ "${#IN_FILES[@]}" -eq 0 ]; then
  echo "❌ No .in files found in: $BASE_DIR"
  exit 1
fi

echo "📁 Base dir: $BASE_DIR"
echo "🔍 Found ${#IN_FILES[@]} .in file(s)"
echo "⚙️  Nodes: $NODES | tasks-per-node: $TASKS_PER_NODE"
echo

# === Loop over each .in file ===
for IN_FILE in "${IN_FILES[@]}"; do
  IN_DIR="$(dirname "$IN_FILE")"
  IN_NAME="$(basename "$IN_FILE")"
  JOB_NAME="$(basename "$IN_DIR")"
  SCRIPT_PATH="$IN_DIR/run.sh"

  # === Write run.sh ===
  cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash
#SBATCH --job-name=${JOB_NAME}
#SBATCH --nodes=${NODES}
#SBATCH --tasks-per-node=${TASKS_PER_NODE}
#SBATCH --output=log_${JOB_NAME}.log

pwd; hostname; date
SECONDS=0
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:${LIB_PATH}
mpirun ${SW4_EXE} ${IN_NAME}
echo "Elapsed: \$SECONDS seconds."
date
EOF

  chmod +x "$SCRIPT_PATH"
  echo "📝 $SCRIPT_PATH (job=$JOB_NAME)"

  # === Submit the job from its own folder ===
  pushd "$IN_DIR" > /dev/null
  SUBMIT_OUT="$(sbatch run.sh)"
  popd > /dev/null

  JOB_ID="$(echo "$SUBMIT_OUT" | awk '{print $NF}')"
  echo "🚀 Job $JOB_ID submitted from $IN_DIR"
  echo
done

echo "✅ All jobs submitted."