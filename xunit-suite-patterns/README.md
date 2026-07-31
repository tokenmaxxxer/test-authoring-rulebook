# xunit-suite-patterns

Gates test-authoring's phase-2 record (`docs/issue-<n>/reports/
test-authoring.md`) for the three Meszaros *xUnit Test Patterns* elements
this plugin owns (issue-1(b) items 1-3): a suite-architecture note naming a
test-pyramid level, a stated fixture strategy (fresh vs. shared fixture),
and a smell list drawn from Meszaros' test-smell catalog — or an explicit
"no smells found" exit when the suite genuinely has none.

## How it works

- `hooks/suite-patterns-gate.sh` — `PreToolUse` gate (`Write|Edit|
  MultiEdit`) on `docs/issue-<n>/reports/test-authoring.md`. Reconstructs
  the resulting document content (full content for `Write`; applies
  `old_string`/`new_string` for `Edit`/`MultiEdit`), then checks, via a
  lower-cased `has_any(...)` substring-presence pattern, that the content
  states a suite-architecture note, a fixture strategy, and a smell list
  (or its "no smells found" escape valve). Fails closed on an
  unparseable payload, an unreadable existing file, or an `Edit`/
  `MultiEdit` whose `old_string` cannot be located in the current file
  (resulting content indeterminate). Kill switch:
  `XUNIT_SUITE_PATTERNS_GATE_OFF` (off-means-off; any non-empty value
  other than `0|false|no|off` disables the gate, with a stderr warning on
  an unrecognized value).
- `hooks/hooks.json` — registers the gate under `PreToolUse`, scoped to
  `${CLAUDE_PLUGIN_ROOT}`.
- `.claude-plugin/plugin.json` — plugin manifest (name, description with
  `use_when`, author).
- `checklists/smell-catalog.md` — Meszaros' 18-item xUnit Test Patterns
  test-smell reference checklist, for authors to consult while writing the
  suite-architecture record.
- `tests/suite-patterns-gate-tests.sh` — real-subprocess allow/deny test
  suite for the gate, following `run-gate-tests.sh`'s pattern (throwaway
  git-init'd fixture, JSON `PreToolUse` payload on stdin, exit 0=allow /
  2=deny).

## Scope of evidence

This plugin's gate design, keyword sets, and false-positive/false-negative
analysis are grounded in `docs/issue-7/reports/test-authoring/
scout-brief.md`'s survey of comparable same-org gates (`pricing/hooks/
methodology-gate.sh`, `core`'s `freelunch`/`scout` plugin completeness
baseline). The methodology owned (Meszaros xUnit Test Patterns) is
otherwise unmeasured by this rulebook as of this plugin's creation — the
gate enforces presence of the adopted vocabulary, not the correctness of
any suite design decision.
