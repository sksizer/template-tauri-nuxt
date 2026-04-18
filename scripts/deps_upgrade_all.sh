#!/usr/bin/env bash
# deps_upgrade_all.sh — Batch-run deps_upgrade.sh against every downstream repo.
#
# Reads the merged list from scripts/downstream.txt + scripts/downstream.local.txt
# (via scripts/lib/downstream.sh), clones each to a temp dir, and runs
# deps_upgrade.sh on each in parallel.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PER_REPO="${SCRIPT_DIR}/deps_upgrade.sh"

# shellcheck source=lib/downstream.sh
source "${SCRIPT_DIR}/lib/downstream.sh"

ARGS=("$@")

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
        bash "$PER_REPO" ${ARGS[@]+"${ARGS[@]}"} "$CLONE_PATH"
    ) &
    PIDS+=($!)
    REPOS+=("$repo_url")
done < <(downstream_urls)

if [[ ${#PIDS[@]} -eq 0 ]]; then
    echo "No downstream repos configured (scripts/downstream.txt + scripts/downstream.local.txt are empty)."
    rm -rf "$WORK_DIR"
    exit 0
fi

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

echo "Cleaning up: ${WORK_DIR}"
rm -rf "$WORK_DIR"

exit $FAILED
