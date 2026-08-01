# issue-10 phase-2 record — test-authoring gate A+ remediation

loop_state: landed

## What was done

Migrated all four `Write|Edit|MultiEdit` gates
(`adr-proposal-shape/hooks/proposal-shape-gate.sh`,
`ep-bva-technique/hooks/technique-gate.sh`,
`traceability-line/hooks/traceability-gate.sh`,
`xunit-suite-patterns/hooks/suite-patterns-gate.sh`) to source/load
`tokenmaxxxer-core`'s `gate-lib.sh`/`gate-lib.py`, per
`docs/issue-10/proposals/gate-a-plus-remediation.md`:

1. Fail-closed trap, kill switch, malformed-JSON deny, path
   normalization, and `Write`/`Edit`/`MultiEdit`/`NotebookEdit`
   reconstruction all now call the shared `gate_*` functions instead of
   each gate's own hand-rolled copy. This fixes the kill-switch
   fail-open-on-unrecognized-value bug in three of the four gates
   (`technique-gate.sh`, `suite-patterns-gate.sh`,
   `traceability-gate.sh`) and the `replace_all`-ignored bug in all four.
2. `test-authoring/hooks/hooks.json`'s dangling `PreToolUse`/`Bash` entry
   pointing at the nonexistent `test-authoring-progress-gate.sh` is
   removed (base plugin was broken; every `Bash` call failed hook
   launch).
3. Semantic checks upgraded from whole-document substring presence to
   heading/paragraph/line-adjacency structure:
   `proposal-shape-gate.sh` now requires each of the six section names as
   a markdown heading line; `technique-gate.sh` requires the EP/BVA
   citation and the mutation-testing escalation to share a paragraph with
   a test-case reference/completeness-claim escalation trigger respectively;
   `suite-patterns-gate.sh` requires the pyramid-level word and
   pyramid-term to be on the same/adjacent line, and the fixture-strategy
   phrase to be stated directly rather than buried in an unrelated
   sentence. `traceability-gate.sh` was already line-scoped — no semantic
   change, migration-only.
4. Each plugin's `tests/*-gate-tests.sh` extended with the six mandatory
   case groups (Edit+replace_all, MultiEdit mixed replace_all, malformed
   JSON, kill-switch-unrecognized-value-stays-active, absolute/`./`-path
   parity) plus semantic-upgrade adjacency cases. New shared
   `tests/resolve-core.sh` + `tests/run-all-gate-tests.sh` aggregator.
5. All four plugin `README.md`s and the top-level `README.md`/
   `test-authoring/README.md` reflect the migrated implementation and
   the removed ghost-hook.

## Why

Based on the approved `docs/issue-10/proposals/gate-a-plus-remediation.md`
plan: issue-10 required raising this role's gates from grade B- to A+ by
fixing the four named defects and migrating to core's now-landed
gate-house standard rather than re-deriving equivalent logic.

## Upstream basis

Basis: `tokenmaxxxer-core` issue #72's landed gate-house standard
(`core/hooks/lib/gate-lib.sh`/`gate-lib.py`,
`docs/handbooks/gate-house-standard.md`), and this role's own
`docs/issue-10/reports/test-authoring/survey.md` current-state survey.

## Verification

Full suite green at delivery: `bash tests/run-all-gate-tests.sh` — 58
cases across the four plugins, 0 failures.

`core/hooks/tests/compliance-check.sh` run against this repo's `hooks/`
trees, clean on all four migrated gates (delivery evidence per
gate-house-standard.md step 4-5):

```
=== adr-proposal-shape/hooks ===
compliance-check: ok — adr-proposal-shape/hooks/proposal-shape-gate.sh
=== ep-bva-technique/hooks ===
compliance-check: ok — ep-bva-technique/hooks/technique-gate.sh
=== traceability-line/hooks ===
compliance-check: ok — traceability-line/hooks/traceability-gate.sh
=== xunit-suite-patterns/hooks ===
compliance-check: ok — xunit-suite-patterns/hooks/suite-patterns-gate.sh
overall rc=0
```

## Suite architecture

Unit tests are the primary test-level for these four gate suites,
matching pyramid guidance: each spawns the gate script itself as a real
subprocess against a throwaway fixture directory, with no live Claude
Code session dependency.

## Fixture strategy

Each test builds a fresh fixture; no shared fixture state between cases.
Every case gets its own `mktemp -d` + `git init` directory, removed
immediately after the case runs.

## Smells found

No smells found in these suites after review: each case builds its own
fixture, assertions are unconditional, and no case depends on another
case's ordering or side effects.

## Test-design technique

Case 1: malformed-JSON deny — truncated / non-object / empty payload
partitions, cited via equivalence partitioning.
Case 2: kill-switch boundary — the recognized-on-spelling vs. any
unrecognized-value cases sit at the boundary the kill switch's contract
draws, cited via boundary value analysis.

## Open findings

None open at delivery. Every mandatory case group (Edit/MultiEdit/
replace_all/malformed-JSON/kill-switch/absolute-path) is present across
all four migrated gates and green.

## Traceability

Suite: gate-lib migration + defect fixes. traces issue-10 requirement 1.
Suite: structural semantic checks. traces issue-10 requirement 2.
Suite: mandatory test cases, full green suite. traces issue-10
requirement 3.
Suite: README parity. traces issue-10 requirement 4.

Sources: `docs/issue-10/proposals/gate-a-plus-remediation.md`;
`tokenmaxxxer/tokenmaxxxer-core` `docs/handbooks/gate-house-standard.md`
and `core/hooks/lib/gate-lib.sh`/`gate-lib.py`/`core/hooks/tests/
compliance-check.sh` (commit `22a7cad`, local checkout read this
session); this repo's migrated `adr-proposal-shape/`, `ep-bva-technique/`,
`traceability-line/`, `xunit-suite-patterns/`, `test-authoring/` trees
(this session).
