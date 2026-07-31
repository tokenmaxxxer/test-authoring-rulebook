#!/usr/bin/env bash
# adr-proposal-shape gate, exercised as real subprocesses (issue-7 §3.3.3).
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOKS="$HERE/../hooks"
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

# 1. ALLOW — all six headers, Sources:, survey.md present
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

# 6. DENY — Edit whose old_string does not match current content
case6() {
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
  report deny "$got" case6-deny-edit-nomatch
}
case6

run_with_survey allow case7-allow-killswitch-on "ADR_PROPOSAL_SHAPE_GATE_OFF=1" "$TARGET" "$MISSING_ONE" no
run_with_survey deny  case8-deny-killswitch-garbled "ADR_PROPOSAL_SHAPE_GATE_OFF=banana" "$TARGET" "$MISSING_ONE" yes

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
