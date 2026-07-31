# adr-proposal-shape ⚓

Gates the test-authoring role's phase-1 proposals against the six
required ADR-derived sections adopted in issue-1(a): every write to
`docs/issue-<n>/proposals/*.md` must contain "What was asked", "Survey
pointer", "Adopted methodology", "Rationale", "Plugin reflection plan",
and "Deliberately out of scope" (as `##`-level headings), at least one
`Sources:` citation line, and — as an independent order constraint — the
issue's `docs/issue-<n>/reports/test-authoring/survey.md` must already
exist on disk before the proposal is allowed to land.

## How it works

- `hooks/hooks.json` — registers `hooks/proposal-shape-gate.sh` on
  `PreToolUse` for `Write|Edit|MultiEdit`, scoped to
  `${CLAUDE_PLUGIN_ROOT}`.
- `hooks/proposal-shape-gate.sh` — the gate itself. Fail-closed
  (`trap __fc EXIT`, denies on any non-{0,2} exit), reconstructs the
  resulting file content for `Write`/`Edit`/`MultiEdit` calls the same
  way `pricing/hooks/methodology-gate.sh` does, and denies (exit 2) when
  the resulting content is indeterminate rather than guessing. Checks the
  six required section headers and the `Sources:` line via lower-cased
  substring presence (`has_any`), and separately denies when the matching
  `survey.md` for that issue number is missing from disk. Kill switch:
  `ADR_PROPOSAL_SHAPE_GATE_OFF` (off-means-off case statement, mirroring
  `freelunch/hooks/freelunch.sh`).
- `tests/proposal-shape-gate-tests.sh` — runs the gate as a real bash
  subprocess against a throwaway git-init'd fixture directory for each of
  the 8 enumerated test cases, asserting exit 0 (allow) / exit 2 (deny),
  and prints an aggregate pass/fail count.

## Scope of evidence

This gate's heuristics — the six section-header keyword sets, the
`Sources:` check, and the survey-file order constraint — are grounded in
`docs/issue-7/reports/test-authoring/scout-brief.md`, not independently
validated. Per that brief's own disclosure, presence-based `has_any`
checks trade false-deny risk (a synonym heading gets rejected) against
false-allow risk (a stray heading match still passes); that tradeoff is
accepted here, not hidden.
