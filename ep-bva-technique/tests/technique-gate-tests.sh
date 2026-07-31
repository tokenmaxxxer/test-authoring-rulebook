#!/usr/bin/env bash
# ep-bva-technique's gate, exercised as a real subprocess.
# Per docs/issue-7/proposals/methodology-enforcement-machine.md §3.3.3,
# "technique-gate-tests.sh" — 5 cases.
set -uo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
GATE="$HERE/../hooks/technique-gate.sh"
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

run allow cited-ep-bva-no-thoroughness   "$REC" "$CITED"
run deny  no-technique-citation          "$REC" "$NO_CITATION"
run deny  thoroughness-claim-no-mutation "$REC" "$THOROUGH_NO_MUTATION"
run allow thoroughness-claim-with-mutation "$REC" "$THOROUGH_WITH_MUTATION"
EP_BVA_TECHNIQUE_GATE_OFF=1 run allow kill-switch-zero-citations "$REC" "$NO_CITATION"

printf '\n== %d passed, %d failed ==\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
