#!/usr/bin/env bash
# sync_cousins.sh — Sync the shared Tauri scaffolding layer to cousin templates.
#
# Usage:
#   sync_cousins.sh                    # dry-run (shows what would happen)
#   sync_cousins.sh --execute          # actually run the sync
#
# Reads cousin repo URLs from scripts/cousins.txt, clones each to a temp dir,
# and uses Claude Code to intelligently sync the shared layer while adapting
# framework-specific references.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COUSINS_FILE="${SCRIPT_DIR}/cousins.txt"
PROMPT_DIR="${SCRIPT_DIR}/cousin_sync"

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

for arg in "$@"; do
    case "$arg" in
        --execute) EXECUTE=true ;;
    esac
done

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

# --- Sync one cousin repo --------------------------------------------------
sync_cousin() {
    local clone_path="$1"
    local repo_url="$2"

    cd "$clone_path"

    echo "Phase 1: Claude syncs shared layer..."
    OUTPUT="$(echo "${PROMPT}" | ${RUNNER} @anthropic-ai/claude-code --print \
        --allowed-tools ${ALLOWED_TOOLS})"
    echo "$OUTPUT"

    # Phase 2: deterministic quality gate
    # Try just first, fall back to make
    CHECK_CMD="just full-check"
    FIX_CMD="just full-write"
    if ! command -v just &>/dev/null && [[ -f Makefile ]]; then
        CHECK_CMD="make full-check"
        FIX_CMD="make full-write"
    fi

    for attempt in $(seq 1 $MAX_RETRIES); do
        echo ""
        echo "=== Quality gate (attempt ${attempt}/${MAX_RETRIES}) ==="

        if (cd "$clone_path" && eval "$CHECK_CMD" 2>&1); then
            echo "Quality gate passed."
            break
        else
            ERRORS=$( (cd "$clone_path" && eval "$CHECK_CMD" 2>&1) || true)
            if [[ $attempt -lt $MAX_RETRIES ]]; then
                echo "Quality gate failed. Submitting errors to Claude for fixing..."
                FIX_PROMPT="The quality checks failed with the following errors. Fix them and run '${CHECK_CMD}' to verify:

${ERRORS}"
                OUTPUT="$(echo "${FIX_PROMPT}" | ${RUNNER} @anthropic-ai/claude-code --print \
                    --allowed-tools ${ALLOWED_TOOLS} \
                    --continue)"
                echo "$OUTPUT"
            else
                echo "Quality gate failed after ${MAX_RETRIES} attempts for ${repo_url}." >&2
                return 1
            fi
        fi
    done

    # Phase 3: deterministic PR creation
    echo ""
    echo "=== Creating PR for ${repo_url} ==="
    cd "$clone_path"

    BRANCH="chore/sync-from-canonical-template"
    git checkout -b "$BRANCH" 2>/dev/null || git checkout "$BRANCH"
    git add -A
    git diff --cached --quiet && { echo "No changes to commit for ${repo_url}."; return 0; }

    git commit -m "chore: sync shared Tauri layer from canonical template"
    git push -u origin "$BRANCH"

    PR_URL=$(gh pr create \
        --title "chore: sync shared Tauri layer from canonical template" \
        --body "Automated sync of shared Tauri scaffolding from template-tauri-nuxt. Review for framework-specific adaptations." \
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
    if [[ ! -f "$COUSINS_FILE" ]]; then
        echo "Error: ${COUSINS_FILE} not found" >&2
        exit 1
    fi

    WORK_DIR="$(mktemp -d)"
    echo "Clone directory: ${WORK_DIR}"

    PIDS=()
    REPOS=()

    while IFS= read -r repo_url; do
        [[ -z "$repo_url" || "$repo_url" == \#* ]] && continue

        REPO_NAME="$(basename "${repo_url%/}")"
        CLONE_PATH="${WORK_DIR}/${REPO_NAME}"

        echo "Cloning: ${repo_url} -> ${CLONE_PATH}"
        (
            git clone --quiet "$repo_url" "$CLONE_PATH"
            sync_cousin "$CLONE_PATH" "$repo_url"
        ) &
        PIDS+=($!)
        REPOS+=("$repo_url")
    done < "$COUSINS_FILE"

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

    echo "Cleaning up: ${WORK_DIR}"
    rm -rf "$WORK_DIR"

    exit $FAILED
else
    echo "=== DRY RUN (cousin sync) ==="
    echo ""
    echo "${PROMPT}"
    echo "---"
    echo "Runner: ${RUNNER}"
    echo "Cousins file: ${COUSINS_FILE}"
    echo "Prompt length: ${#PROMPT} chars"
    echo "Allowed tools: ${ALLOWED_TOOLS}"
    echo "Max retries: ${MAX_RETRIES}"
    echo ""
    if [[ -f "$COUSINS_FILE" ]]; then
        echo "Cousin repos:"
        grep -v '^#' "$COUSINS_FILE" | grep -v '^$' | while read -r url; do
            echo "  - ${url}"
        done
    fi
    echo ""
    echo "Pass --execute to run this against Claude Code."
fi
