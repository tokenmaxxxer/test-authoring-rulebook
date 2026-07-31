#!/usr/bin/env bash
# Real-subprocess allow/deny tests for xunit-suite-patterns/hooks/
# suite-patterns-gate.sh, following implementation-rulebook's
# tests/run-gate-tests.sh pattern: throwaway git-init'd fixture, JSON
# PreToolUse payload on stdin, exit 0=allow / 2=deny.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
HOOK="$HERE/../hooks/suite-patterns-gate.sh"
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

# 6. ALLOW — kill switch set, content missing all three components.
run allow kill-switch-off "$REC" "nothing relevant here" XUNIT_SUITE_PATTERNS_GATE_OFF=1

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
