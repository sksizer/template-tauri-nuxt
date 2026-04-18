#!/usr/bin/env bash
# deps_update.sh — Update JS (pnpm) and Rust (cargo) dependencies within their
# declared semver ranges, verify the project still builds, and open a PR.
#
# Usage:
#   deps_update.sh                    # dry-run (shows the prompt)
#   deps_update.sh --execute          # actually run the update
#   deps_update.sh --execute /path    # run against a specific directory
#
# For cross-major bumps that rewrite manifests, see deps_upgrade.sh.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_DIR="${SCRIPT_DIR}/deps_update"

MAX_RETRIES=3

# --- Locate a JS package runner (pnpm dlx preferred, npx fallback) ----------
find_runner() {
    if command -v pnpm &>/dev/null; then
        echo "pnpm dlx"
    elif command -v npx &>/dev/null; then
        echo "npx"
    else
        echo "Error: neither pnpm nor npx found. Install one of them first." >&2
        exit 1
    fi
}

RUNNER="$(find_runner)"

# --- Parse arguments --------------------------------------------------------
EXECUTE=false
TARGET_DIR=""

for arg in "$@"; do
    case "$arg" in
        --execute) EXECUTE=true ;;
        *) TARGET_DIR="$arg" ;;
    esac
done

if [[ -n "$TARGET_DIR" ]]; then
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
else
    TARGET_DIR="$(pwd)"
fi

# --- Compose the prompt from markdown files ---------------------------------
compose_prompt() {
    local prompt=""
    if [[ -f "${PROMPT_DIR}/role.md" ]]; then
        prompt+="$(cat "${PROMPT_DIR}/role.md")"
        prompt+=$'\n\n'
    fi
    for f in "${PROMPT_DIR}"/*.md; do
        [[ "$(basename "$f")" == "role.md" ]] && continue
        prompt+="$(cat "$f")"
        prompt+=$'\n\n'
    done
    echo "$prompt"
}

PROMPT="$(compose_prompt)"

# --- Allowed tools ----------------------------------------------------------
ALLOWED_TOOLS="Read Edit Write Bash WebFetch"

# --- Execute or dry-run -----------------------------------------------------
if [[ "$EXECUTE" == true ]]; then
    echo "Using runner: ${RUNNER}"
    echo "Target:       ${TARGET_DIR}"
    echo "Prompt chars: ${#PROMPT}"
    echo "Max retries:  ${MAX_RETRIES}"
    echo "---"
    cd "$TARGET_DIR"
    echo "${PROMPT}" | ${RUNNER} @anthropic-ai/claude-code --print \
        --allowed-tools ${ALLOWED_TOOLS}
else
    echo "=== DRY RUN ==="
    echo ""
    echo "${PROMPT}"
    echo "---"
    echo "Runner:       ${RUNNER}"
    echo "Target:       ${TARGET_DIR}"
    echo "Prompt chars: ${#PROMPT}"
    echo "Allowed:      ${ALLOWED_TOOLS}"
    echo ""
    echo "Pass --execute to run this against Claude Code."
fi
