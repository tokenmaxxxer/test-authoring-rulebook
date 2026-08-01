#!/usr/bin/env bash
# traceability-line's gate, exercised as real subprocesses. Per proposal
# §3.3.3 "traceability-gate-tests.sh", migrated + extended per issue-10's
# mandatory case groups (no semantic change — already line-scoped).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/traceability-gate.sh"
. "$(cd "$HERE/../.." && pwd -P)/tests/resolve-core.sh"
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
run allow kill-switch-on-spelling-allows "$CASE2" TRACEABILITY_LINE_GATE_OFF=1
run deny  kill-switch-unrecognized-value-stays-active "$CASE2" TRACEABILITY_LINE_GATE_OFF=banana

# Mandatory group: Edit with replace_all against a multiply-occurring string.
case_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  ( cd "$td" && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m init && git checkout -q -b issue-9/test-authoring )
  mkdir -p "$td/docs/issue-9/reports"
  printf 'TOKEN TOKEN TOKEN\n%s' "$CASE1" > "$td/$REC"
  local body rc got
  body="$(jq -n --arg fp "$REC" --arg o TOKEN --arg n REPLACED \
    '{tool_name:"Edit", tool_input:{file_path:$fp, old_string:$o, new_string:$n, replace_all:true}}')"
  printf '%s' "$body" | ( cd "$td" && env -u CLAUDE_PROJECT_DIR /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" edit-replace-all-multiply-occurring
}
case_edit_replace_all

# Mandatory group: MultiEdit with mixed replace_all true/false edits.
case_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  ( cd "$td" && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m init && git checkout -q -b issue-9/test-authoring )
  mkdir -p "$td/docs/issue-9/reports"
  printf 'QQQ QQQ QQQ\nPPP\n%s' "$CASE1" > "$td/$REC"
  local body rc got
  body="$(jq -n --arg fp "$REC" \
    '{tool_name:"MultiEdit", tool_input:{file_path:$fp, edits:[{old_string:"QQQ",new_string:"ZZZ",replace_all:true},{old_string:"PPP",new_string:"RRR",replace_all:false}]}}')"
  printf '%s' "$body" | ( cd "$td" && env -u CLAUDE_PROJECT_DIR /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" multiedit-mixed-replace-all
}
case_multiedit_mixed

# Mandatory group: malformed JSON.
run_raw() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  local rc got
  printf '%s' "$3" | ( cd "$td" && env -u CLAUDE_PROJECT_DIR /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}
run_raw deny malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw deny malformed-json-non-object '"just a string"'
run_raw deny malformed-json-empty ''

# Mandatory group: absolute-path and ./-prefixed path parity.
case_abs_and_dot_path() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  ( cd "$td" && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m init && git checkout -q -b issue-9/test-authoring )
  mkdir -p "$td/docs/issue-9/reports"
  local abs="$td/$REC" body rc got
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$abs" "$CASE2")"
  printf '%s' "$body" | ( cd "$td" && env -u CLAUDE_PROJECT_DIR /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" absolute-path-same-scope

  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "./$REC" "$CASE2")"
  printf '%s' "$body" | ( cd "$td" && env -u CLAUDE_PROJECT_DIR /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report deny "$got" dot-prefixed-path-same-scope
}
case_abs_and_dot_path

# Mandatory group (issue-75/issue-13): CLAUDE_PLUGIN_ROOT_CORE pointed
# nowhere resolvable -> the guarded gate-lib.sh source must deny (exit 2),
# never silently allow.
case_missing_core() {
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  ( cd "$td" && git config user.email t@t && git config user.name t && git commit -q --allow-empty -m init && git checkout -q -b issue-9/test-authoring )
  mkdir -p "$td/docs/issue-9/reports"
  local body rc got
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$REC" "$CASE2")"
  printf '%s' "$body" | ( cd "$td" && env -u CLAUDE_PROJECT_DIR CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" /bin/bash "$GATE" ) >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" missing-core-CLAUDE_PLUGIN_ROOT_CORE
}
case_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
