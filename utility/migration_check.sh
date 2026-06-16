#!/bin/bash
#SBATCH --chdir=.
#SBATCH --job-name=Migration_check
#SBATCH --mem=10G
#SBATCH --cpus-per-task=1
#SBATCH --mail-type=NONE
#SBATCH --output=/root/%x_%A.txt
#SBATCH --error=/root/%x_%A.txt
# Maintainer: Jaewoong Lee <jaewoong@unist.ac.kr>
# Purpose:
#   Verify a migrated directory against saved tree.txt and md5.txt manifests,
#   then email a PASS/FAIL report.
# Usage:
#   sbatch utility/migration_check.sh
set -euo pipefail
IFS=$'\n\t'

readonly MAIL_TO="${MIGRATION_CHECK_MAIL_TO:-root@compbio.unist.ac.kr}"
readonly HOST_NAME="$(hostname)"
readonly WORK_DIR="$(pwd -P)"
readonly WORK_NAME="$(basename "$WORK_DIR")"

report_file="$(mktemp "${TMPDIR:-/tmp}/migration_check_report.XXXXXX")"
tree_output="$(mktemp "${TMPDIR:-/tmp}/migration_check_tree.XXXXXX")"
md5_output="$(mktemp "${TMPDIR:-/tmp}/migration_check_md5.XXXXXX")"
current_tree="$(mktemp "${TMPDIR:-/tmp}/migration_check_current_tree.XXXXXX")"
trap 'rm -f "$report_file" "$tree_output" "$md5_output" "$current_tree"' EXIT

tree_status=0
md5_status=0
mail_status=0

if tree -ls -I "tree.txt|md5.txt" >"$current_tree" 2>"$tree_output"; then
    if diff "$current_tree" tree.txt >>"$tree_output" 2>&1; then
        tree_status=0
    else
        tree_status=$?
    fi
else
    tree_status=$?
    printf 'tree command failed; diff was not run.\n' >>"$tree_output"
fi

if md5sum -c md5.txt >"$md5_output" 2>&1; then
    md5_status=0
else
    md5_status=$?
fi

tree_result="PASS"
md5_result="PASS"
report_result="PASS"

if (( tree_status != 0 )); then
    tree_result="FAIL"
    report_result="FAIL"
fi

if (( md5_status != 0 )); then
    md5_result="FAIL"
    report_result="FAIL"
fi

{
    printf 'Migration check report\n'
    printf 'Host: %s\n' "$HOST_NAME"
    printf 'Directory: %s\n' "$WORK_DIR"
    printf 'Generated: %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
    printf 'Overall result: %s\n\n' "$report_result"

    printf '== Tree diff ==\n'
    printf 'Result: %s (exit %d)\n' "$tree_result" "$tree_status"
    printf 'Command: tree -ls -I "tree.txt|md5.txt" | diff - tree.txt\n\n'
    if [[ -s "$tree_output" ]]; then
        cat "$tree_output"
    else
        printf 'No differences reported.\n'
    fi
    printf '\n'

    printf '== MD5 check ==\n'
    printf 'Result: %s (exit %d)\n' "$md5_result" "$md5_status"
    printf 'Command: md5sum -c md5.txt\n\n'
    if [[ -s "$md5_output" ]]; then
        cat "$md5_output"
    else
        printf 'No checksum output reported.\n'
    fi
} >"$report_file"

if mail -s "${report_result}: Migration check report for ${HOST_NAME}: ${WORK_NAME}" "$MAIL_TO" <"$report_file"; then
    mail_status=0
else
    mail_status=$?
fi

if (( tree_status != 0 )); then
    exit "$tree_status"
fi

if (( md5_status != 0 )); then
    exit "$md5_status"
fi

exit "$mail_status"
