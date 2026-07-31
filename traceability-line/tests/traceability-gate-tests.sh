#!/usr/bin/env bash
# traceability-line's gate, exercised as real subprocesses. Per proposal
# §3.3.3 "traceability-gate-tests.sh" — 4 cases.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/traceability-gate.sh"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-9/reports/test-authoring.md

run() { # want name content extra_env...
  local want="$1" name="$2" content="$3"; shift 3
  td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  ( cd "$td" && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m init && git checkout -q -b issue-9/test-authoring )
  mkdir -p "$td/docs/issue-9/reports"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$REC" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$content")" "$td" \
    | ( cd "$td" && env -u CLAUDE_PROJECT_DIR "$@" /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$want" "$got" "$name"
}

CASE1='## Suite: checkout
Unit tests for checkout. traces issue-9 requirement R1.'
CASE2='## Suite: checkout
Unit tests for checkout. No mention of any tie-back at all.'
CASE3='## Suite: checkout
Unit tests for checkout. traces issue-3 requirement R1.'

run allow trace-line-matches-branch "$CASE1"
run deny  no-traceability-line       "$CASE2"
run deny  mismatched-issue-ref       "$CASE3"
run allow kill-switch-no-trace-line "$CASE2" TRACEABILITY_LINE_GATE_OFF=1

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
