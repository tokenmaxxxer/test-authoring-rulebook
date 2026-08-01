# issue-13 phase-2 record — test-authoring gate A+ final closeout

loop_state: landed

## What was done

Applied `docs/issue-13/proposals/gate-a-plus-final-closeout.md` against
this role's four `Write|Edit|MultiEdit` gates
(`adr-proposal-shape/hooks/proposal-shape-gate.sh`,
`ep-bva-technique/hooks/technique-gate.sh`,
`traceability-line/hooks/traceability-gate.sh`,
`xunit-suite-patterns/hooks/suite-patterns-gate.sh`):

1. **Source guard (defect 1)** — each gate's
   `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` line now carries
   `tokenmaxxxer-core` issue #75's landed `||` guard:
   `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`,
   closing the fail-open path where an unreachable core left
   `gate_kill_switch_active` undefined and the following
   `gate_kill_switch_active ... || { exit 0; }` line read the resulting
   127 as "kill switch off," silently allowing every write.
2. **Matcher/code parity (defect 2)** — all four plugins'
   `hooks/hooks.json` `PreToolUse` matcher widened from
   `"Write|Edit|MultiEdit"` to `"Write|Edit|MultiEdit|NotebookEdit"`,
   making each gate's already-existing `NotebookEdit` branch in its
   Python judge (`gate_lib.gate_reconstruct_write`) reachable instead of
   dead code, matching what each plugin's `README.md` already advertised
   as delivered (issue-10 scope).
3. **Missing-core test case (defect 3)** — one case added to each
   plugin's `tests/*-gate-tests.sh`, mirroring core issue #75's own
   `run-gate-lib-tests.sh` missing-core case: invokes the gate with
   `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path, asserts
   exit code 2 (deny), never exit 0. This is the regression guard for
   item 1 — a future accidental drop of the `||` guard now fails the
   suite.
4. **README doc-follows-code (defect 4)** — each of the four plugin
   `README.md`'s "How it works" section updated to describe the
   `||`-guarded source, the widened `NotebookEdit` matcher, and the new
   missing-core deny case. No deletions: the repo-wide sweep for stale
   role names/ghost files (`README.md`, `test-authoring/README.md`, all
   four plugin `README.md`s, `.claude-plugin/marketplace.json`, all five
   `plugin.json`s) confirmed zero live residue — `test-authoring/
   README.md`'s `test-authoring-progress-gate.sh` mention is accurate
   past-tense history of its issue-10 removal, not a live pointer;
   `marketplace.json`'s five `source` paths and plugin `name`s match the
   five directories on disk 1:1; no `plugin.json` carries an old role
   name.

## Why

Based on the approved
`docs/issue-13/proposals/gate-a-plus-final-closeout.md` plan: issue-13's
2026-08-01 re-audit named four common residual defects against this
role's four gates, to be closed by applying `tokenmaxxxer-core` issue
#75's now-landed reference fixes (source guard, missing-core test
pattern) rather than re-deriving equivalent logic, plus this issue's own
literal matcher-parity wording and a doc-follows-code README pass.

## Upstream basis

Basis: `tokenmaxxxer-core` issue #75 (PR #77, commit `52bdc15`) — the
`||`-guarded `gate-lib.sh` usage contract, `compliance-check.sh`'s new
no-guard detection rule, and `run-gate-lib-tests.sh`'s missing-core deny
case — applied here as the reference implementation, not re-derived; and
this role's own `docs/issue-13/reports/test-authoring/survey.md`
current-state survey.

## Verification

Full suite green at delivery: `bash tests/run-all-gate-tests.sh` — 62
cases across the four plugins (58 pre-existing + 4 new missing-core
cases, one per plugin), 0 failures:

```
== adr-proposal-shape/tests/proposal-shape-gate-tests.sh ==
== 17 passed, 0 failed ==
== ep-bva-technique/tests/technique-gate-tests.sh ==
== 15 passed, 0 failed ==
== traceability-line/tests/traceability-gate-tests.sh ==
== 13 passed, 0 failed ==
== xunit-suite-patterns/tests/suite-patterns-gate-tests.sh ==
== 17 passed, 0 failed ==
run-all-gate-tests: all suites passed
```

`tokenmaxxxer-core`'s `core/hooks/tests/compliance-check.sh` run against
this repo's four gate `hooks/` trees. Before the fix, all four FAILed
with "sources gate-lib.sh with no || guard on the same line — fail-open
when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)" (survey
evidence). After the fix, clean on all four:

```
=== adr-proposal-shape ===
compliance-check: ok — adr-proposal-shape/hooks/proposal-shape-gate.sh
=== ep-bva-technique ===
compliance-check: ok — ep-bva-technique/hooks/technique-gate.sh
=== traceability-line ===
compliance-check: ok — traceability-line/hooks/traceability-gate.sh
=== xunit-suite-patterns ===
compliance-check: ok — xunit-suite-patterns/hooks/suite-patterns-gate.sh
overall rc=0
```

## Suite architecture

Unit tests remain the primary test-level for these four gate suites,
matching pyramid guidance: each case spawns the gate script itself as a
real subprocess against a throwaway fixture directory, with no live
Claude Code session dependency. The four new missing-core cases follow
the same shape as core's own `run-gate-lib-tests.sh` group 7: they set
`CLAUDE_PLUGIN_ROOT_CORE` to a nonexistent path in the subprocess
environment and assert the resulting exit code, rather than mocking or
stubbing `gate-lib.sh` itself.

## Fixture strategy

Each new case builds its own fresh `mktemp -d` + `git init` fixture
directory (unshared, matching the existing case pattern in each
`tests/*-gate-tests.sh`), removed immediately after the case runs. No
shared fixture state between cases, including the new ones.

## Smells found

No smells found in the four new missing-core cases or elsewhere in these
suites after review: each case builds its own fixture, assertions are
unconditional (a fixed want/got comparison via the existing `report`
helper), and no case depends on another case's ordering or side effects.

## Test-design technique

Case (new, all four plugins): missing/unresolvable
`CLAUDE_PLUGIN_ROOT_CORE` — a boundary case on the source-guard's
contract (resolvable core path vs. any unresolvable path), cited via
boundary value analysis, directly regression-guarding the equivalence
class boundary the `||` guard fix in item 1 introduces (guarded source
denies vs. a resolvable source proceeds).

## Open findings

None open at delivery. All four common defects named in issue-13's
2026-08-01 re-audit are closed: source guard applied and
compliance-check-verified, matcher/code parity closed, missing-core
regression case present and green in all four plugins, README parity
restored. The issue body's separate `has_test_id`/"technique 단독 불릿
통과" finding is left deliberately out of scope per the approved
proposal — it matches no existing predicate name anywhere in this repo's
code, tests, or handbooks (`grep -rn has_test_id .` returns zero
matches), and acting on it now would mean inventing new gate semantics
the issue never specified a form for.

## Traceability

Suite: `proposal-shape-gate-tests.sh` (source guard + missing-core case
+ matcher-widening regression coverage). traces issue-13 requirement 1.
Suite: `technique-gate-tests.sh` (source guard + missing-core case +
matcher-widening regression coverage). traces issue-13 requirement 1.
Suite: `traceability-gate-tests.sh` (source guard + missing-core case +
matcher-widening regression coverage). traces issue-13 requirement 1.
Suite: `suite-patterns-gate-tests.sh` (source guard + missing-core case
+ matcher-widening regression coverage). traces issue-13 requirement 1.
Suite: all four plugins' `hooks/hooks.json` `NotebookEdit`-widened
matcher, verified structurally (not exercised by these shell-subprocess
suites, which invoke the gate script directly). traces issue-13
requirement 2.
Suite: `tests/run-all-gate-tests.sh` full-suite green (62 cases) +
`core/hooks/tests/compliance-check.sh` clean record above. traces
issue-13 requirement 3.
Suite: README/manifest sweep (zero live ghost references, doc-follows-
code updates to all four plugin `README.md`s). traces issue-13
requirement 4.

Sources: `docs/issue-13/proposals/gate-a-plus-final-closeout.md`;
`docs/issue-13/reports/test-authoring/survey.md`;
`tokenmaxxxer/tokenmaxxxer-core` commit `52bdc15` (issue #75, PR #77),
`core/hooks/lib/gate-lib.sh`, `core/hooks/tests/compliance-check.sh`,
`core/hooks/tests/run-gate-lib-tests.sh` (local checkout read this
session); this repo's `adr-proposal-shape/`, `ep-bva-technique/`,
`traceability-line/`, `xunit-suite-patterns/` trees (this session).
