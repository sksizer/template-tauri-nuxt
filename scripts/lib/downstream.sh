#!/usr/bin/env bash
# Shared helper: emit the combined list of downstream repo URLs on stdout.
#
# Two sources, concatenated in this order:
#   scripts/downstream.txt       — public list, checked in
#   scripts/downstream.local.txt — optional private list, gitignored
#
# Lines starting with '#' and blank lines are skipped.
# Intended to be sourced, not executed:
#   source "$(dirname "$0")/lib/downstream.sh"
#   while IFS= read -r url; do ... ; done < <(downstream_urls)

downstream_urls() {
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local files=(
        "${script_dir}/downstream.txt"
        "${script_dir}/downstream.local.txt"
    )
    local f line
    for f in "${files[@]}"; do
        [[ -f "$f" ]] || continue
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" || "$line" == \#* ]] && continue
            echo "$line"
        done < "$f"
    done
}
