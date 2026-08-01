#!/usr/bin/env bash
# ep-bva-technique's gate, exercised as a real subprocess.
# Per docs/issue-7/proposals/methodology-enforcement-machine.md §3.3.3,
# "technique-gate-tests.sh" — migrated + extended per issue-10's
# mandatory case groups and paragraph-adjacency semantic upgrade.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/technique-gate.sh"
. "$(cd "$HERE/../.." && pwd -P)/tests/resolve-core.sh"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC=docs/issue-9/reports/test-authoring.md

run() { # want name path content [env_kv]
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$3")"
  payload="$(printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$3" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$4")" "$td")"
  if [ -n "${5:-}" ]; then
    printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" "$5" /bin/bash "$GATE" >/dev/null 2>&1
  else
    printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
  fi
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}

CITED='## Test cases
Case 1: empty input list — cited via equivalence partitioning.
Case 2: boundary value at max size — boundary value analysis applied.'

NO_CITATION='## Test cases
Case 1: empty input list.
Case 2: max size input.
Case 3: negative number input.'

THOROUGH_NO_MUTATION='## Test cases
Case 1: empty input — equivalence partitioning.
This suite provides comprehensive coverage of the module.'

THOROUGH_WITH_MUTATION='## Test cases
Case 1: empty input — equivalence partitioning.
This suite provides comprehensive coverage of the module, verified via
mutation testing (92% mutant kill rate).'

CITATION_UNRELATED_PARAGRAPH='This document is not exhaustive, but it is
not just boundary case testing either — that phrase is a stray aside with
no test-case reference nearby.

## Test cases
Case 1: empty input list.
Case 2: max size input.'

run allow cited-ep-bva-no-thoroughness   "$REC" "$CITED"
run deny  no-technique-citation          "$REC" "$NO_CITATION"
run deny  thoroughness-claim-no-mutation "$REC" "$THOROUGH_NO_MUTATION"
run allow thoroughness-claim-with-mutation "$REC" "$THOROUGH_WITH_MUTATION"
run deny  semantic-upgrade-citation-not-adjacent-to-test-ref "$REC" "$CITATION_UNRELATED_PARAGRAPH"
EP_BVA_TECHNIQUE_GATE_OFF=1 run allow kill-switch-on-spelling-allows "$REC" "$NO_CITATION"
run deny  kill-switch-unrecognized-value-stays-active "$REC" "$NO_CITATION" EP_BVA_TECHNIQUE_GATE_OFF=banana

# Mandatory group: Edit with replace_all against a multiply-occurring string.
case_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'TOKEN TOKEN TOKEN\n%s' "$CITED" > "$td/$REC"
  local body rc got
  body="$(jq -n --arg fp "$REC" --arg o TOKEN --arg n REPLACED \
    '{tool_name:"Edit", tool_input:{file_path:$fp, old_string:$o, new_string:$n, replace_all:true}}')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" edit-replace-all-multiply-occurring
}
case_edit_replace_all

# Mandatory group: MultiEdit with mixed replace_all true/false edits.
case_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'QQQ QQQ QQQ\nPPP\n%s' "$CITED" > "$td/$REC"
  local body rc got
  body="$(jq -n --arg fp "$REC" \
    '{tool_name:"MultiEdit", tool_input:{file_path:$fp, edits:[{old_string:"QQQ",new_string:"ZZZ",replace_all:true},{old_string:"PPP",new_string:"RRR",replace_all:false}]}}')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" multiedit-mixed-replace-all
}
case_multiedit_mixed

# Mandatory group: malformed JSON.
run_raw() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  local rc got
  printf '%s' "$3" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report "$1" "$got" "$2"
}
run_raw deny malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw deny malformed-json-non-object '"just a string"'
run_raw deny malformed-json-empty ''

# Mandatory group: absolute-path and ./-prefixed path parity.
case_abs_and_dot_path() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  local abs="$td/$REC" body rc got
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$abs" "$NO_CITATION")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" absolute-path-same-scope

  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "./$REC" "$NO_CITATION")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$GATE" >/dev/null 2>&1
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
  mkdir -p "$td/$(dirname "$REC")"
  local body rc got
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$REC" "$NO_CITATION")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" \
    /bin/bash "$GATE" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" missing-core-CLAUDE_PLUGIN_ROOT_CORE
}
case_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
