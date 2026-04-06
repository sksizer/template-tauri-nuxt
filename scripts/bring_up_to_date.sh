#!/usr/bin/env bash
# bring_up_to_date.sh — Sync a project with its upstream template using Claude Code.
#
# Usage:
#   bring_up_to_date.sh                    # dry-run (shows what would happen)
#   bring_up_to_date.sh --execute          # actually run the sync
#   bring_up_to_date.sh --execute /path    # run against a specific directory
#
# The script uses Claude Code to intelligently merge template changes while
# respecting project-specific overrides. A deterministic quality gate loop
# ensures all checks pass before PR creation.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_DIR="${SCRIPT_DIR}/bring_up_to_date"

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

# Resolve target directory (default: current directory)
if [[ -n "$TARGET_DIR" ]]; then
    TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
else
    TARGET_DIR="$(pwd)"
fi

# --- Compose the prompt from markdown files ---------------------------------
compose_prompt() {
    local prompt=""

    # Role comes first
    if [[ -f "${PROMPT_DIR}/role.md" ]]; then
        prompt+="$(cat "${PROMPT_DIR}/role.md")"
        prompt+=$'\n\n'
    fi

    # Then every other .md file in sorted order
    for f in "${PROMPT_DIR}"/*.md; do
        [[ "$(basename "$f")" == "role.md" ]] && continue
        prompt+="$(cat "$f")"
        prompt+=$'\n\n'
    done

    echo "$prompt"
}

PROMPT="$(compose_prompt)"

# --- Open a URL in the default browser (best-effort) -----------------------
open_url() {
    local url="$1"
    case "$(uname -s)" in
        Darwin)  open "$url" ;;
        Linux)   xdg-open "$url" ;;
        MINGW*|MSYS*|CYGWIN*) cmd.exe /c start "$url" ;;
    esac 2>/dev/null || true
}

# --- Allowed tools ----------------------------------------------------------
ALLOWED_TOOLS="Read Edit Write Bash WebFetch"

# --- Quality gate with retry loop ------------------------------------------
run_with_quality_gate() {
    cd "$TARGET_DIR"

    echo "Phase 1: Claude applies template changes..."
    OUTPUT="$(echo "${PROMPT}" | ${RUNNER} @anthropic-ai/claude-code --print \
        --allowed-tools ${ALLOWED_TOOLS})"
    echo "$OUTPUT"

    # Phase 2: deterministic quality gate
    for attempt in $(seq 1 $MAX_RETRIES); do
        echo ""
        echo "=== Quality gate (attempt ${attempt}/${MAX_RETRIES}) ==="

        if (cd "$TARGET_DIR" && just full-check 2>&1); then
            echo "Quality gate passed."
            break
        else
            ERRORS=$( (cd "$TARGET_DIR" && just full-check 2>&1) || true)
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                echo "Quality gate failed. Submitting errors to Claude for fixing..."
                FIX_PROMPT="The quality checks failed with the following errors. Fix them and run 'just full-check' to verify:

${ERRORS}"
                OUTPUT="$(echo "${FIX_PROMPT}" | ${RUNNER} @anthropic-ai/claude-code --print \
                    --allowed-tools ${ALLOWED_TOOLS} \
                    --continue)"
                echo "$OUTPUT"
            else
                echo "Quality gate failed after ${MAX_RETRIES} attempts. Manual intervention needed." >&2
                exit 1
            fi
        fi
    done

    # Phase 3: deterministic PR creation
    echo ""
    echo "=== Creating PR ==="
    cd "$TARGET_DIR"

    BRANCH="chore/update-from-template"
    git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
    git add -A
    git diff --cached --quiet && { echo "No changes to commit."; exit 0; }

    git commit -m "chore: update project from upstream template"
    git push -u origin "$BRANCH"

    PR_URL=$(gh pr create \
        --title "chore: update from upstream template" \
        --body "Automated sync with upstream template. Review changes for project-specific overrides." \
        2>&1) || true

    if [[ -n "$PR_URL" && "$PR_URL" == https://* ]]; then
        echo "PR created: ${PR_URL}"
        open_url "$PR_URL"
    else
        echo "PR creation output: ${PR_URL}"
    fi
}

# --- Execute or dry-run -----------------------------------------------------
if [[ "$EXECUTE" == true ]]; then
    echo "Using runner: ${RUNNER}"
    echo "Target: ${TARGET_DIR}"
    echo "Prompt length: ${#PROMPT} chars"
    echo "Allowed tools: ${ALLOWED_TOOLS}"
    echo "Max retries: ${MAX_RETRIES}"
    echo "---"
    run_with_quality_gate
else
    echo "=== DRY RUN ==="
    echo ""
    echo "${PROMPT}"
    echo "---"
    echo "Runner: ${RUNNER}"
    echo "Target: ${TARGET_DIR}"
    echo "Prompt length: ${#PROMPT} chars"
    echo "Allowed tools: ${ALLOWED_TOOLS}"
    echo "Max retries: ${MAX_RETRIES}"
    echo ""
    echo "Pass --execute to run this against Claude Code."
fi
