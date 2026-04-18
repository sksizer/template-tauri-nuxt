#!/usr/bin/env bash
# deps_upgrade_all.sh — Batch-run deps_upgrade.sh against every downstream repo.
#
# Reads the merged list from scripts/downstream.txt + scripts/downstream.local.txt
# (via scripts/lib/downstream.sh), clones each to a temp dir, and runs
# deps_upgrade.sh on each in parallel. Per-repo output is captured to a log
# file; a summary with PR URLs prints at the end.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PER_REPO="${SCRIPT_DIR}/deps_upgrade.sh"

# shellcheck source=lib/downstream.sh
source "${SCRIPT_DIR}/lib/downstream.sh"
# shellcheck source=lib/batch_summary.sh
source "${SCRIPT_DIR}/lib/batch_summary.sh"

ARGS=("$@")

WORK_DIR="$(mktemp -d)"
LOG_DIR="${WORK_DIR}/logs"
mkdir -p "$LOG_DIR"
echo "Clone directory: ${WORK_DIR}"
echo "Log directory:   ${LOG_DIR}"

PIDS=()
REPOS=()
LOGS=()

while IFS= read -r repo_url; do
    REPO_NAME="$(basename "${repo_url%/}" .git)"
    CLONE_PATH="${WORK_DIR}/${REPO_NAME}"
    LOG_PATH="${LOG_DIR}/${REPO_NAME}.log"

    echo "[${REPO_NAME}] starting (log: ${LOG_PATH})"
    (
        {
            git clone --quiet "$repo_url" "$CLONE_PATH"
            bash "$PER_REPO" ${ARGS[@]+"${ARGS[@]}"} "$CLONE_PATH"
        } >"$LOG_PATH" 2>&1
    ) &
    PIDS+=($!)
    REPOS+=("$repo_url")
    LOGS+=("$LOG_PATH")
done < <(downstream_urls)

if [[ ${#PIDS[@]} -eq 0 ]]; then
    echo "No downstream repos configured (scripts/downstream.txt + scripts/downstream.local.txt are empty)."
    rm -rf "$WORK_DIR"
    exit 0
fi

CODES=()
for i in "${!PIDS[@]}"; do
    if wait "${PIDS[$i]}"; then
        CODES+=(0)
        echo "[$(basename "${REPOS[$i]%/}" .git)] done"
    else
        CODES+=($?)
        echo "[$(basename "${REPOS[$i]%/}" .git)] FAILED" >&2
    fi
done

batch_print_summary "$WORK_DIR"

# Clean up clones, but keep logs for review.
find "$WORK_DIR" -mindepth 1 -maxdepth 1 ! -name logs -exec rm -rf {} +

FAILED=0
for c in "${CODES[@]}"; do
    [[ "$c" -ne 0 ]] && FAILED=$((FAILED + 1))
done
exit $FAILED
