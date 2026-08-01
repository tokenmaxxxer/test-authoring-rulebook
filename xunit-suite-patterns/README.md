# xunit-suite-patterns

Gates test-authoring's phase-2 record (`docs/issue-<n>/reports/
test-authoring.md`) for the three Meszaros *xUnit Test Patterns* elements
this plugin owns (issue-1(b) items 1-3): a suite-architecture note naming a
test-pyramid level, a stated fixture strategy (fresh vs. shared fixture),
and a smell list drawn from Meszaros' test-smell catalog — or an explicit
"no smells found" exit when the suite genuinely has none.

## How it works

- `hooks/suite-patterns-gate.sh` — `PreToolUse` gate (`Write|Edit|
  MultiEdit`) on `docs/issue-<n>/reports/test-authoring.md`, sourcing
  `tokenmaxxxer-core`'s `core/hooks/lib/gate-lib.sh`/`gate-lib.py` (the
  gate-house standard, core issue #72, reference only) for the trap,
  kill switch, JSON parse, path normalize, and `Write`/`Edit`/`MultiEdit`/
  `NotebookEdit` reconstruction. The suite-architecture check now requires
  a pyramid-level word (unit/integration/e2e) and a test-level/pyramid
  term on the same or an adjacent line, and the fixture-strategy check
  requires the fresh-/shared-fixture phrase on its own line — both moved
  off whole-document substring presence (issue-10). The smell-list check
  (smell word near a digit or a named smell, or an explicit "no smells
  found" escape valve) was already locally adjacent and is unchanged.
  Fails closed on an unparseable payload, an unreadable existing file, or
  a write whose resulting content cannot be determined. Kill switch:
  `XUNIT_SUITE_PATTERNS_GATE_OFF` — only a recognized on-spelling
  (`1`/`true`/`yes`/`on`) disables the gate; empty, a recognized
  off-spelling, or any unrecognized value all keep it active (the
  correctness fix: the pre-issue-10 version disabled on any unrecognized
  value).
- `hooks/hooks.json` — registers the gate under `PreToolUse`, scoped to
  `${CLAUDE_PLUGIN_ROOT}`.
- `.claude-plugin/plugin.json` — plugin manifest (name, description with
  `use_when`, author).
- `checklists/smell-catalog.md` — Meszaros' 18-item xUnit Test Patterns
  test-smell reference checklist, for authors to consult while writing the
  suite-architecture record.
- `tests/suite-patterns-gate-tests.sh` — real-subprocess allow/deny test
  suite for the gate (throwaway git-init'd fixture, JSON `PreToolUse`
  payload on stdin, exit 0=allow / 2=deny), including the mandatory
  `Edit`/`MultiEdit`-with-`replace_all`, malformed-JSON,
  unrecognized-kill-switch-stays-active, and absolute/`./`-path cases,
  plus adjacency-upgrade cases for the suite-architecture and
  fixture-strategy checks.

## Scope of evidence

This plugin's gate design, keyword sets, and false-positive/false-negative
analysis are grounded in `docs/issue-7/reports/test-authoring/
scout-brief.md`'s survey of comparable same-org gates (`pricing/hooks/
methodology-gate.sh`, `core`'s `freelunch`/`scout` plugin completeness
baseline). The methodology owned (Meszaros xUnit Test Patterns) is
otherwise unmeasured by this rulebook as of this plugin's creation — the
gate enforces presence of the adopted vocabulary, not the correctness of
any suite design decision.
