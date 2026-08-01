# issue-10 current-state survey — test-authoring gate A+ remediation

**Scout skip record:** scouting skipped. Reason: the precondition (core
issue #72) fixes the reference shape already — every requirement in the
issue body reduces to "match the now-canon `gate-lib.sh`/`gate-lib.py`
contract," a pure bugfix against a fixed external spec with no open
design surface (scout-directive's stated skip condition 2).

## Precondition check: core issue #72 landing status

Confirmed landed on `tokenmaxxxer/tokenmaxxxer-core` main
(`git log --oneline`: `22a7cad deliver(implementation): gate-house
standard canonization (issue-72) (#74)`, on top of `146a129
propose(...) (#73)`). Files present at that commit:

- `core/hooks/lib/gate-lib.sh` — `gate_trap_fail_closed`,
  `gate_kill_switch_active`, `gate_deny`/`gate_allow`,
  `gate_bash_write_targets`.
- `core/hooks/lib/gate-lib.py` — `gate_parse_json_or_deny`,
  `gate_normalize_path`, `gate_reconstruct_write` (Write/Edit/MultiEdit/
  NotebookEdit, honors per-edit `replace_all`).
- `core/hooks/tests/run-gate-lib-tests.sh` — six mandatory case groups
  (replace_all-Edit, mixed-replace_all-MultiEdit, malformed-JSON,
  unrecognized-kill-switch-stays-active, absolute/`./`-path parity,
  Bash-write-target parity).
- `core/hooks/tests/compliance-check.sh` — flags hand-rolled kill
  switches and hand-rolled `.replace(...)` reconstruction.
- `docs/handbooks/gate-house-standard.md` — the migration checklist this
  proposal follows.

Precondition satisfied. This role's five gates (`test-authoring` base +
`adr-proposal-shape`, `ep-bva-technique`, `traceability-line`,
`xunit-suite-patterns`) are the migration target.

## Inventory: this repo's write surfaces

| Plugin | Gate script | Matcher | Kill switch env |
|---|---|---|---|
| `test-authoring` (base) | `${CLAUDE_PLUGIN_ROOT}/hooks/test-authoring-progress-gate.sh` | `Bash` | none |
| `adr-proposal-shape` | `proposal-shape-gate.sh` | `Write\|Edit\|MultiEdit` | `ADR_PROPOSAL_SHAPE_GATE_OFF` |
| `ep-bva-technique` | `technique-gate.sh` | `Write\|Edit\|MultiEdit` | `EP_BVA_TECHNIQUE_GATE_OFF` |
| `traceability-line` | `traceability-gate.sh` | `Write\|Edit\|MultiEdit` | `TRACEABILITY_LINE_GATE_OFF` |
| `xunit-suite-patterns` | `suite-patterns-gate.sh` | `Write\|Edit\|MultiEdit` | `XUNIT_SUITE_PATTERNS_GATE_OFF` |

## Confirmed defects (2026-08-01 audit, mapped to gate-house-standard.md)

1. **Ghost script reference (base plugin broken).**
   `test-authoring/hooks/hooks.json` PreToolUse/`Bash` points at
   `test-authoring-progress-gate.sh`; that file does not exist anywhere
   in the repo (`find test-authoring -type f` shows only
   `directive.sh`). `test-authoring/README.md` even records this as a
   pre-existing gap "out of [issue-7's] scope." Every `Bash` tool call
   in this role's session fails the hook launch. issue-10 puts this back
   in scope.

2. **Kill-switch fail-open-on-typo, 3 of 4 composing gates.**
   `ep-bva-technique/hooks/technique-gate.sh:31-35`,
   `xunit-suite-patterns/hooks/suite-patterns-gate.sh:29-32`, and
   `traceability-line/hooks/traceability-gate.sh:35-38` all use the
   pre-issue-72 idiom — unrecognized value falls to the wildcard branch,
   which **disables** the gate (`exit 0`), exactly the bug
   `gate-house-standard.md` §"the two bugs this issue fixed" #1
   documents and `gate_kill_switch_active` fixes (unrecognized ⇒ stay
   active). `adr-proposal-shape/hooks/proposal-shape-gate.sh:33-37` is
   the outlier: its wildcard branch does NOT `exit 0` — it warns and
   falls through to running the gate, so it already behaves like the
   fixed convention, just via divergent hand-rolled logic instead of
   `gate_kill_switch_active`.

3. **`replace_all` ignored, all four Write/Edit/MultiEdit gates.**
   `proposal-shape-gate.sh`, `technique-gate.sh`, `traceability-gate.sh`,
   `suite-patterns-gate.sh` each reconstruct `Edit`/`MultiEdit` via a
   hand-rolled `text.replace(o, n, 1)` (first occurrence only) and never
   read `tool_input.get("replace_all")` — the exact
   `record-fields-gate.sh` bug `gate-house-standard.md` §"the two bugs"
   #2 documents, reproduced independently four times. A `replace_all:
   true` Edit that actually replaces every occurrence is silently judged
   against a reconstruction that only replaced the first — the record
   content the gate scores is not the record content the tool actually
   produces. None of the four gates handle `NotebookEdit` either (not
   reconstructed, not even an explicit skip-with-reason — the tool
   branch is simply absent).

4. **`technique-gate` keyword theater.** `technique-gate.sh:167-180`'s
   `technique_named` check is `has_any("equivalence partitioning",
   "ep/bva", "boundary value", "ep-bva", "boundary case")` against the
   **entire reconstructed document**, lower-cased, with no positional or
   structural constraint — a citation dropped anywhere in the file
   (a stray comment, an unrelated paragraph, even inside a quoted
   negative example like "not just boundary case testing") satisfies
   it. Same shape in `proposal-shape-gate.sh` (six section checks) and
   `suite-patterns-gate.sh` (pyramid/fixture/smell checks): all are flat
   `has_any(...)` substring tests over the whole blob, matching the
   issue's "technique-gate 키워드 연극" finding and generalizing to the
   other three gates' semantic checks too.

5. **Path normalization: already reasonable, but hand-rolled.** All four
   Write/Edit/MultiEdit gates' `_under()`/`resolve()` already handle
   absolute, relative, and `./`-prefixed paths correctly via
   `os.path.realpath` + `posixpath.normpath` (independently
   re-derived four times, ~25 lines each). Not a live correctness bug
   like items 2-4, but exactly the duplication `gate_normalize_path`
   exists to collapse, and the self-reimplementation the issue's
   precondition ("자체 재구현 금지") forbids going forward.

6. **Fail-closed trap: already correct, but hand-rolled.** Each script's
   `trap __fc EXIT` at line 2 (before `set -uo pipefail`) already matches
   `gate_trap_fail_closed`'s contract exactly — four independent
   re-derivations of the same 4-line trap, once again the pattern
   `gate-lib.sh` exists to source instead of copy.

7. **Malformed-JSON deny: already correct, but hand-rolled.** Each
   Python payload's `try: json.loads(...) except ValueError: deny(...)`
   plus the `isinstance(ev, dict)` check already matches
   `gate_parse_json_or_deny`'s contract (empty payload, parse failure,
   non-object top level all deny) — again reimplemented four times
   instead of loaded from `gate-lib.py`.

8. **`gate_bash_write_targets` — no coverage gap found.** None of this
   role's four `Write|Edit|MultiEdit`-matched gates need `Bash`-write
   detection: the record surfaces they guard
   (`docs/issue-<n>/reports/test-authoring.md`,
   `docs/issue-<n>/proposals/*.md`) are role-authored markdown, and the
   role's only `Bash`-matched hook is the ghost script (defect 1) with
   no semantic check to extend. Not adopting `gate_bash_write_targets`
   in this remediation; noted for completeness against the standard's
   full function list.

## README drift

`test-authoring/README.md`'s final paragraph documents the ghost-file gap
as accepted and out of scope — now stale once defect 1 is fixed; the
per-repo migration checklist (`gate-house-standard.md` step 5) also calls
for `compliance-check.sh` evidence in the record, which does not exist
yet for this repo.

## Test coverage gap

Existing suites (`adr-proposal-shape/tests/proposal-shape-gate-tests.sh`,
`ep-bva-technique/tests/technique-gate-tests.sh`,
`traceability-line/tests/traceability-gate-tests.sh`,
`xunit-suite-patterns/tests/suite-patterns-gate-tests.sh`) were not read
line-by-line in this survey (phase-2 scope); the issue's requirement #3
(mandatory Edit/MultiEdit/replace_all/malformed-JSON/kill-switch/
absolute-path cases, green at delivery) is treated as unmet until phase-2
proves it against `run-gate-lib-tests.sh`'s six-case shape.

Sources: `tokenmaxxxer/tokenmaxxxer-core` commits `22a7cad`/`146a129` and
`core/docs/handbooks/gate-house-standard.md` (cloned read, this session);
this repo's `test-authoring/`, `adr-proposal-shape/`, `ep-bva-technique/`,
`traceability-line/`, `xunit-suite-patterns/` trees (cloned read, this
session); issue #10 body (`gh issue view 10`).
