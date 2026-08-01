#!/usr/bin/env bash
# adr-proposal-shape gate, exercised as real subprocesses (issue-7 §3.3.3;
# migrated + extended per issue-10's mandatory case groups).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
. "$(cd "$HERE/../.." && pwd -P)/tests/resolve-core.sh"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

GOOD='## What was asked
Asked to propose.
## Survey pointer
See survey.
## Adopted methodology
Six sections.
## Rationale
Because.
## Plugin reflection plan
Later.
## Deliberately out of scope
Not everything.
Sources: scout-brief.md'

MISSING_ONE='## What was asked
Asked to propose.
## Survey pointer
See survey.
## Adopted methodology
Six sections.
## Rationale
Because.
## Plugin reflection plan
Later.
Sources: scout-brief.md'

NO_SOURCES='## What was asked
Asked to propose.
## Survey pointer
See survey.
## Adopted methodology
Six sections.
## Rationale
Because.
## Plugin reflection plan
Later.
## Deliberately out of scope
Not everything.'

PROSE_ONLY='This proposal covers what was asked, the survey pointer, the
adopted methodology, the rationale, the plugin reflection plan, and what
is deliberately out of scope, but none of those are headings - just one
unstructured paragraph mentioning every section name in passing.
Sources: scout-brief.md'

# run: want name env target_path content [existing_current]
run() {
  local want="$1" name="$2" envset="$3" target="$4" content="$5" existing="${6:-}"
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/reports/test-authoring"
  if [ -n "$existing" ]; then
    mkdir -p "$td/$(dirname "$target")"
    printf '%s' "$existing" > "$td/$target"
  fi
  local body
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$target" "$content")"
  local rc got
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" $envset /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

# ALLOW/DENY — all six headers, Sources:, survey.md present
run_with_survey() {
  local want="$1" name="$2" envset="$3" target="$4" content="$5" survey="$6"
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/reports/test-authoring"
  if [ "$survey" = "yes" ]; then
    printf 'survey' > "$td/docs/issue-9/reports/test-authoring/survey.md"
  fi
  local body
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$target" "$content")"
  local rc got
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" $envset /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

TARGET="docs/issue-9/proposals/foo.md"

run_with_survey allow case1-allow-complete "" "$TARGET" "$GOOD" yes
run_with_survey deny  case2-deny-no-survey "" "$TARGET" "$GOOD" no
run_with_survey deny  case3-deny-no-sources "" "$TARGET" "$NO_SOURCES" yes
run_with_survey deny  case4-deny-missing-header "" "$TARGET" "$MISSING_ONE" yes
run_with_survey allow case5-allow-unrelated-path "" "README.md" "nothing here" yes
run_with_survey deny  case-semantic-upgrade-prose-only-no-headings "" "$TARGET" "$PROSE_ONLY" yes

# DENY — Edit whose old_string does not match current content
case_edit_nomatch() {
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/proposals" "$td/docs/issue-9/reports/test-authoring"
  printf 'survey' > "$td/docs/issue-9/reports/test-authoring/survey.md"
  printf 'original content' > "$td/docs/issue-9/proposals/foo.md"
  local body rc got
  body="$(python3 -c 'import json; print(json.dumps({"tool_name":"Edit","tool_input":{"file_path":"docs/issue-9/proposals/foo.md","old_string":"nonexistent text","new_string":"x"}}))')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" case-deny-edit-nomatch
}
case_edit_nomatch

run_with_survey allow case-allow-killswitch-on "ADR_PROPOSAL_SHAPE_GATE_OFF=1" "$TARGET" "$MISSING_ONE" no
run_with_survey deny  case-deny-killswitch-garbled-stays-active "ADR_PROPOSAL_SHAPE_GATE_OFF=banana" "$TARGET" "$MISSING_ONE" yes

# Mandatory group: Edit with replace_all against a multiply-occurring string.
case_edit_replace_all() {
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/proposals" "$td/docs/issue-9/reports/test-authoring"
  printf 'survey' > "$td/docs/issue-9/reports/test-authoring/survey.md"
  printf 'TOKEN TOKEN TOKEN\n%s' "$GOOD" > "$td/docs/issue-9/proposals/foo.md"
  local body rc got
  body="$(jq -n --arg fp docs/issue-9/proposals/foo.md --arg o TOKEN --arg n REPLACED \
    '{tool_name:"Edit", tool_input:{file_path:$fp, old_string:$o, new_string:$n, replace_all:true}}')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" case-allow-edit-replace-all
}
case_edit_replace_all

# Mandatory group: MultiEdit with mixed replace_all true/false edits.
case_multiedit_mixed() {
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/proposals" "$td/docs/issue-9/reports/test-authoring"
  printf 'survey' > "$td/docs/issue-9/reports/test-authoring/survey.md"
  printf 'QQQ QQQ QQQ\nPPP\n%s' "$GOOD" > "$td/docs/issue-9/proposals/foo.md"
  local body rc got
  body="$(jq -n --arg fp docs/issue-9/proposals/foo.md \
    '{tool_name:"MultiEdit", tool_input:{file_path:$fp, edits:[{old_string:"QQQ",new_string:"ZZZ",replace_all:true},{old_string:"PPP",new_string:"RRR",replace_all:false}]}}')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report allow "$got" case-allow-multiedit-mixed-replace-all
}
case_multiedit_mixed

# Mandatory group: malformed JSON (truncated / non-object / empty).
run_raw() {
  local want="$1" name="$2" payload="$3"
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  local rc got
  printf '%s' "$payload" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}
run_raw deny case-deny-malformed-json-truncated '{"tool_name":"Write","tool_input":{'
run_raw deny case-deny-malformed-json-non-object '"just a string"'
run_raw deny case-deny-malformed-json-empty ''

# Mandatory group: absolute-path and ./-prefixed path parity.
case_abs_and_dot_path() {
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/reports/test-authoring"
  printf 'survey' > "$td/docs/issue-9/reports/test-authoring/survey.md"
  local abs="$td/docs/issue-9/proposals/foo.md"
  local body rc got
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$abs" "$MISSING_ONE")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" case-deny-absolute-path-same-scope

  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "./docs/issue-9/proposals/foo.md" "$MISSING_ONE")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" case-deny-dot-prefixed-path-same-scope
}
case_abs_and_dot_path

# Mandatory group (issue-75/issue-13): CLAUDE_PLUGIN_ROOT_CORE pointed
# nowhere resolvable -> the guarded gate-lib.sh source must deny (exit 2),
# never silently allow.
case_missing_core() {
  local td; td="$(cd "$(mktemp -d)" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/docs/issue-9/proposals" "$td/docs/issue-9/reports/test-authoring"
  printf 'survey' > "$td/docs/issue-9/reports/test-authoring/survey.md"
  local body rc got
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "docs/issue-9/proposals/foo.md" "$GOOD")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" \
    /bin/bash "$HOOKS/proposal-shape-gate.sh" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" case-deny-missing-core-CLAUDE_PLUGIN_ROOT_CORE
}
case_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
