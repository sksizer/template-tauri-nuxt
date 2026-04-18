#!/usr/bin/env bash
# Shared helpers for the *_all.sh batch scripts: per-repo logging, PR-URL
# extraction, and a summary block printed at the end of a parallel run.
#
# Intended to be sourced:
#   source "${SCRIPT_DIR}/lib/batch_summary.sh"

# Extract the first GitHub PR URL printed in a log, if any.
batch_extract_pr_url() {
    local log_file="$1"
    [[ -f "$log_file" ]] || return 0
    grep -Eo 'https://github\.com/[^[:space:]]+/pull/[0-9]+' "$log_file" \
        | head -n 1 || true
}

# Classify a per-repo run. Echoes one of: success | no-op | failed
# Args: <exit_code> <log_file>
batch_classify() {
    local code="$1"
    local log_file="$2"

    if [[ "$code" -ne 0 ]]; then
        echo "failed"
        return
    fi

    # Look for explicit "nothing to do" markers from the per-repo scripts /
    # prompts. If present, treat as a no-op rather than a successful PR.
    if [[ -f "$log_file" ]] && grep -qE \
        'No changes to commit\.|No dependency updates available\.' \
        "$log_file"; then
        echo "no-op"
        return
    fi

    echo "success"
}

# Print the final summary block.
#
# Reads the parallel arrays REPOS / LOGS / CODES from the caller's scope
# (avoids bash 4.3+ namerefs so this works on the macOS-stock bash 3.2).
# Args: <work_dir>
batch_print_summary() {
    local work_dir="$1"

    local total=${#REPOS[@]}
    local ok=0 noop=0 fail=0

    echo ""
    echo "================ Summary ================"
    printf '%-40s  %-8s  %s\n' "REPO" "STATUS" "PR / NOTE"
    printf '%-40s  %-8s  %s\n' "----" "------" "---------"

    local i status pr_url note repo_short
    for i in "${!REPOS[@]}"; do
        status="$(batch_classify "${CODES[$i]}" "${LOGS[$i]}")"
        pr_url="$(batch_extract_pr_url "${LOGS[$i]}")"
        repo_short="$(basename "${REPOS[$i]%/}" .git)"

        case "$status" in
            success)
                ok=$((ok + 1))
                note="${pr_url:-(no PR URL found — see log)}"
                ;;
            no-op)
                noop=$((noop + 1))
                note="no changes — nothing to PR"
                ;;
            failed)
                fail=$((fail + 1))
                note="see log: ${LOGS[$i]}"
                ;;
        esac

        printf '%-40s  %-8s  %s\n' "$repo_short" "$status" "$note"
    done

    echo ""
    echo "Totals: ${ok} succeeded, ${noop} no-op, ${fail} failed (of ${total})"
    echo "Logs:   ${work_dir}/logs"

    if [[ "$ok" -gt 0 ]]; then
        echo ""
        echo "PR links:"
        for i in "${!REPOS[@]}"; do
            pr_url="$(batch_extract_pr_url "${LOGS[$i]}")"
            if [[ -n "$pr_url" ]]; then
                echo "  ${pr_url}"
            fi
        done
    fi

    return 0
}
