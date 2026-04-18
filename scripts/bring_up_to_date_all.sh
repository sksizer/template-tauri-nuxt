#!/usr/bin/env bash
# bring_up_to_date_all.sh — Batch-sync all downstream projects in parallel.
#
# Reads repo URLs from scripts/downstream.txt, clones each to a temp dir,
# and runs bring_up_to_date.sh on each in parallel.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRING_UP="${SCRIPT_DIR}/bring_up_to_date.sh"

# shellcheck source=lib/downstream.sh
source "${SCRIPT_DIR}/lib/downstream.sh"

# Forward all args (e.g. --execute) to each invocation
ARGS=("$@")

# Create a shared tmp directory for all clones
WORK_DIR="$(mktemp -d)"
echo "Clone directory: ${WORK_DIR}"

PIDS=()
REPOS=()

while IFS= read -r repo_url; do
    REPO_NAME="$(basename "${repo_url%/}" .git)"
    CLONE_PATH="${WORK_DIR}/${REPO_NAME}"

    echo "Cloning: ${repo_url} -> ${CLONE_PATH}"
    (
        git clone --quiet "$repo_url" "$CLONE_PATH"
        bash "$BRING_UP" ${ARGS[@]+"${ARGS[@]}"} "$CLONE_PATH"
    ) &
    PIDS+=($!)
    REPOS+=("$repo_url")
done < <(downstream_urls)

if [[ ${#PIDS[@]} -eq 0 ]]; then
    echo "No downstream repos configured (scripts/downstream.txt + scripts/downstream.local.txt are empty)."
    rm -rf "$WORK_DIR"
    exit 0
fi

# Wait for all and report results
FAILED=0
for i in "${!PIDS[@]}"; do
    if wait "${PIDS[$i]}"; then
        echo "Done: ${REPOS[$i]}"
    else
        echo "FAILED: ${REPOS[$i]}" >&2
        FAILED=$((FAILED + 1))
    fi
done

echo "---"
echo "Finished: $((${#PIDS[@]} - FAILED))/${#PIDS[@]} succeeded"

# Clean up clones
echo "Cleaning up: ${WORK_DIR}"
rm -rf "$WORK_DIR"

exit $FAILED
