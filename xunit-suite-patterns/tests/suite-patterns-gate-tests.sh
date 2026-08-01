#!/usr/bin/env bash
# Real-subprocess allow/deny tests for xunit-suite-patterns/hooks/
# suite-patterns-gate.sh: throwaway git-init'd fixture, JSON PreToolUse
# payload on stdin, exit 0=allow / 2=deny. Migrated + extended per
# issue-10's mandatory case groups and adjacency semantic upgrade.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOK="$HERE/../hooks/suite-patterns-gate.sh"
. "$(cd "$HERE/../.." && pwd -P)/tests/resolve-core.sh"
pass=0; fail=0
report() { if [ "$2" = "$1" ]; then pass=$((pass+1)); printf 'ok     %-34s %s\n' "$3" "$2"; else fail=$((fail+1)); printf 'FAIL   %-34s want=%s got=%s\n' "$3" "$1" "$2"; fi; }

REC="docs/issue-7/reports/test-authoring.md"

run() { # want name file content [extra_env...]
  local want="$1" name="$2" file="$3" content="$4"; shift 4
  local extra_env=("$@")
  td="$(cd "$(mktemp -d "${TMPDIR:-/tmp}/xspg-test.XXXXXX")" && pwd -P)"
  git init -q "$td"
  mkdir -p "$td/$(dirname "$file")"
  printf '{"tool_name":"Write","tool_input":{"file_path":"%s","content":%s},"cwd":"%s"}' \
    "$file" "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "$content")" "$td" \
    | env "${extra_env[@]}" CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report "$want" "$got" "$name"
}

GOOD='## Suite architecture
Unit tests cover the parser at the test-level closest to the pyramid base.
## Fixture strategy
Each test builds a fresh fixture; no shared fixture state between tests.
## Smells found
General fixture smell #1 was removed by extracting a builder helper.'

NO_SMELLS='## Suite architecture
Unit tests are the primary test-level here, matching pyramid guidance.
## Fixture strategy
Tests use a fresh fixture per case, built in setup.
## Smells
No smells found in this suite after review.'

MISSING_FIXTURE='## Suite architecture
Unit tests at the test-level base of the pyramid.
## Smells
Mystery guest smell #2 was found in the loader tests.'

NO_ARCH_WORD='## Fixture strategy
Fresh fixture per test, verified in review.
## Smells
Conditional test logic smell #3 found in the validator suite.'

NON_ADJACENT_ARCH='Unit tests are used here for isolated logic.

Several paragraphs later, unrelated to the above, this document also
happens to mention the word pyramid in a completely different context —
diagrams look like a pyramid shape sometimes.

## Fixture strategy
Fresh fixture per test.
## Smells
No smells found.'

FIXTURE_MENTIONED_NOT_OWN_LINE='## Suite architecture
Unit tests at the test-level base of the pyramid.
## Fixture strategy
We considered a fresh fixture approach as part of a longer sentence about strategy, not stated as its own line.
## Smells
No smells found.'

# 1. ALLOW — pyramid-level word, fixture strategy, named smell.
run allow full-record "$REC" "$GOOD"

# 2. ALLOW — explicit "no smells found" escape valve.
run allow no-smells-valve "$REC" "$NO_SMELLS"

# 3. DENY — missing fixture-strategy language entirely.
run deny missing-fixture "$REC" "$MISSING_FIXTURE"

# 4. DENY — smell list present but no pyramid-level word / test-level / pyramid term.
run deny missing-arch-note "$REC" "$NO_ARCH_WORD"

# 5. ALLOW — write to an unrelated path (no-op regardless of content).
run allow foreign-path "README.md" "no relevant content here at all"

# 6. ALLOW — kill switch set (on-spelling), content missing all three components.
run allow kill-switch-on-spelling-allows "$REC" "nothing relevant here" XUNIT_SUITE_PATTERNS_GATE_OFF=1

# 7. DENY — kill switch set to an unrecognized value stays active.
run deny kill-switch-unrecognized-value-stays-active "$REC" "nothing relevant here" XUNIT_SUITE_PATTERNS_GATE_OFF=banana

# Semantic-upgrade cases: pyramid-level word and pyramid term present but
# not adjacent; fixture phrase present but not on its own line.
run deny semantic-upgrade-arch-words-not-adjacent "$REC" "$NON_ADJACENT_ARCH"
run deny semantic-upgrade-fixture-not-own-line "$REC" "$FIXTURE_MENTIONED_NOT_OWN_LINE"

# Mandatory group: Edit with replace_all against a multiply-occurring string.
case_edit_replace_all() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'TOKEN TOKEN TOKEN\n%s' "$GOOD" > "$td/$REC"
  local body rc got
  body="$(jq -n --arg fp "$REC" --arg o TOKEN --arg n REPLACED \
    '{tool_name:"Edit", tool_input:{file_path:$fp, old_string:$o, new_string:$n, replace_all:true}}')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" edit-replace-all-multiply-occurring
}
case_edit_replace_all

# Mandatory group: MultiEdit with mixed replace_all true/false edits.
case_multiedit_mixed() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"; mkdir -p "$td/$(dirname "$REC")"
  printf 'QQQ QQQ QQQ\nPPP\n%s' "$GOOD" > "$td/$REC"
  local body rc got
  body="$(jq -n --arg fp "$REC" \
    '{tool_name:"MultiEdit", tool_input:{file_path:$fp, edits:[{old_string:"QQQ",new_string:"ZZZ",replace_all:true},{old_string:"PPP",new_string:"RRR",replace_all:false}]}}')"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"; report allow "$got" multiedit-mixed-replace-all
}
case_multiedit_mixed

# Mandatory group: malformed JSON.
run_raw() {
  td="$(cd "$(mktemp -d)" && pwd -P)"; git init -q "$td"
  local rc got
  printf '%s' "$3" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
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
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$abs" "$MISSING_FIXTURE")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
  rc=$?; case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  report deny "$got" absolute-path-same-scope

  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "./$REC" "$MISSING_FIXTURE")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" /bin/bash "$HOOK" >/dev/null 2>&1
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
  body="$(python3 -c 'import json,sys; print(json.dumps({"tool_name":"Write","tool_input":{"file_path":sys.argv[1],"content":sys.argv[2]}}))' "$REC" "$MISSING_FIXTURE")"
  printf '%s' "$body" | env CLAUDE_PROJECT_DIR="$td" CLAUDE_PLUGIN_ROOT_CORE="$td/no-such-core" \
    /bin/bash "$HOOK" >/dev/null 2>&1
  rc=$?
  case "$rc" in 0) got=allow ;; 2) got=deny ;; *) got="exit-$rc" ;; esac
  rm -rf "$td"
  report deny "$got" missing-core-CLAUDE_PLUGIN_ROOT_CORE
}
case_missing_core

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
