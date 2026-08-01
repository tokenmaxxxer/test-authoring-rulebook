#!/usr/bin/env bash
# Aggregator: runs every test-authoring-role plugin's own gate test suite.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
fail=0

for suite in \
  adr-proposal-shape/tests/proposal-shape-gate-tests.sh \
  ep-bva-technique/tests/technique-gate-tests.sh \
  traceability-line/tests/traceability-gate-tests.sh \
  xunit-suite-patterns/tests/suite-patterns-gate-tests.sh
do
  echo "== $suite =="
  if ! bash "$ROOT/$suite"; then
    fail=1
  fi
done

if [ "$fail" = "1" ]; then
  echo "run-all-gate-tests: FAILED"
  exit 1
fi
echo "run-all-gate-tests: all suites passed"
