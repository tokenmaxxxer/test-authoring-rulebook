# Phase-2 record: methodology-enforcement plugin set (issue-7)

Subject: issue-7. Approved per `APPROVE issue-7/test-authoring` (single-account
mode, issue comment) on the approved proposal
`docs/issue-7/proposals/methodology-enforcement-machine.md`.

## What was done

Built four independently-registered plugins, one per adopted methodology
from issue-1(a)/(b), each self-contained (own `.claude-plugin/plugin.json`,
`README.md`, `hooks/hooks.json`, gate script, `tests/`), per proposal
§3.1/§3.3.1 — never one combined gate:

| Plugin | Methodology owned | Gate | Tests |
|---|---|---|---|
| `adr-proposal-shape` | Phase-1 ADR-style proposal shape (issue-1(a)) | `hooks/proposal-shape-gate.sh` | `tests/proposal-shape-gate-tests.sh` — 8/8 pass |
| `xunit-suite-patterns` | Meszaros suite architecture / fixture strategy / smell list (issue-1(b) 1-3) | `hooks/suite-patterns-gate.sh` | `tests/suite-patterns-gate-tests.sh` — 6/6 pass |
| `ep-bva-technique` | Test-design-technique citation, mutation-testing escalation (issue-1(b) 4) | `hooks/technique-gate.sh` | `tests/technique-gate-tests.sh` — 5/5 pass |
| `traceability-line` | Requirement↔suite traceability line (issue-1(b) 5) | `hooks/traceability-gate.sh` | `tests/traceability-gate-tests.sh` — 4/4 pass |

Total: 23/23 gate-test cases pass (real-subprocess allow/deny cases per
plugin, following `run-gate-tests.sh`'s pattern — see stdout below).

Each gate: fail-closed (`trap __fc EXIT`, denies on any non-{0,2} exit),
`has_any(...)` keyword-presence checks on lower-cased reconstructed
resulting content (Write/Edit/MultiEdit), a per-plugin kill switch
(`ADR_PROPOSAL_SHAPE_GATE_OFF`, `XUNIT_SUITE_PATTERNS_GATE_OFF`,
`EP_BVA_TECHNIQUE_GATE_OFF`, `TRACEABILITY_LINE_GATE_OFF`) with
off-means-off semantics (`""|0|false|no|off` = not off; any other
non-empty value = off, unrecognized values warn to stderr) — all per
proposal §3.3.1, adapted verbatim from
`pricing/hooks/methodology-gate.sh` and `core/freelunch/hooks/freelunch.sh`.

`.claude-plugin/marketplace.json` registers all four new entries alongside
the existing `test-authoring` role plugin (unchanged source path).
`test-authoring/hooks/directive.sh`'s PRODUCES string now points at the
four composing plugins by name instead of inlining the requirements;
`test-authoring/hooks/hooks.json` is unchanged (each new plugin registers
its own `PreToolUse` gate under its own `hooks.json`). `test-authoring/
README.md`'s Enforcement section documents the composition below.

## Why

Based on: `docs/issue-7/proposals/methodology-enforcement-machine.md`
(approved), itself grounded in `docs/issue-1/proposals/
test-authoring-methodology-norms.md`'s adopted methodology and the
upstream approver feedback on PR #8 requiring the plugin-set structure.

Issue-1's adopted test-authoring methodology existed only as a directive
one-liner with no machine enforcement (issue-7's ask). The approver's PR
#8 feedback required this be built as an independently-registered plugin
set — one plugin per methodology, mirroring how core's own marketplace
keeps `freelunch` and `scout` separate rather than merging both into one
plugin — rather than a single combined gate, so that each methodology's
enforcement can evolve, version, and be disabled independently.

## Composition (the design artifact the approver asked for)

- **Phase-1 proposal norm** = `adr-proposal-shape` alone. One methodology,
  one plugin, no composition needed.
- **Phase-2 deliverable norm** = `xunit-suite-patterns` + `ep-bva-technique`
  + `traceability-line`, all three firing (ANDed) on the same
  `docs/issue-<n>/reports/test-authoring.md` write — the record is
  well-formed only when all three independently pass; the norm is the
  conjunction of three plugins, not a fourth combined gate re-checking the
  same file.

## Test output (pasted verbatim from this session's runs)

```
=== adr-proposal-shape ===
ok     case1-allow-complete               allow
ok     case2-deny-no-survey               deny
ok     case3-deny-no-sources              deny
ok     case4-deny-missing-header          deny
ok     case5-allow-unrelated-path         allow
ok     case6-deny-edit-nomatch            deny
ok     case7-allow-killswitch-on          allow
ok     case8-deny-killswitch-garbled      deny
== 8 passed, 0 failed ==

=== xunit-suite-patterns ===
ok     full-record                        allow
ok     no-smells-valve                    allow
ok     missing-fixture                    deny
ok     missing-arch-note                  deny
ok     foreign-path                       allow
ok     kill-switch-off                    allow
== 6 passed, 0 failed ==

=== ep-bva-technique ===
ok     cited-ep-bva-no-thoroughness       allow
ok     no-technique-citation              deny
ok     thoroughness-claim-no-mutation     deny
ok     thoroughness-claim-with-mutation   allow
ok     kill-switch-zero-citations         allow
== 5 passed, 0 failed ==

=== traceability-line ===
ok     trace-line-matches-branch          allow
ok     no-traceability-line               deny
ok     mismatched-issue-ref               deny
ok     kill-switch-no-trace-line          allow
== 4 passed, 0 failed ==
```

`core/hooks/tests/stub-check.sh test-authoring/hooks` (canon-referenced,
run against the deepened `directive.sh`):

```
stub-check: ok — no vendored 'trailer-gate.sh' under test-authoring/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under test-authoring/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under test-authoring/hooks
stub-check: ok — no vendored 'parse-check.sh' under test-authoring/hooks
stub-check: ok — no vendored 'stub-check.sh' under test-authoring/hooks
stub-check: ok — test-authoring/hooks/directive.sh is a role-directive stub
```

## Open findings

- Proposal §3.3.2 flagged several keyword sets as likely needing a
  follow-up addition (e.g. `adr-proposal-shape`'s "Deliberately out of
  scope" heading variant, `ep-bva-technique`'s `boundary case` phrasing).
  `boundary case` was adopted directly into `ep-bva-technique`'s keyword
  set during this delivery; the remaining flagged variants are left as
  the accepted false-negative risk the proposal already disclosed, not
  silently fixed — a real occurrence of a missed variant is the trigger
  for a future keyword-set edit, not a hypothetical one.
- `test-authoring-progress-gate.sh` (referenced in `test-authoring/hooks/
  hooks.json`, file still missing) remains out of this issue's scope per
  issue-2's survey — unchanged by this delivery.
- Whether the four plugins should eventually live in a shared
  cross-rulebook location rather than this repo was left as a phase-2
  judgment call in the proposal (§6); no such mechanism was found during
  scouting, so they ship as siblings of `test-authoring/` in this repo.

## Deliberately out of scope (unchanged from proposal §6)

Core canon changes; mutation-testing tooling selection; `write_scope`
unchanged (`['test/**']` still governs this role's test-suite output, a
distinct write surface from the proposal/record surfaces the new plugins
govern).

loop_state: landed
