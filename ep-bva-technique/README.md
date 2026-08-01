# ep-bva-technique

Gates test-authoring's phase-2 record so it cites a real test-design
technique (equivalence partitioning / boundary value analysis) instead of
listing test cases with no stated design rationale, and escalates to
requiring a mutation-testing mention whenever the record's own language
claims thoroughness — a claim of "comprehensive coverage" is not evidence
of it, and this plugin is the one place that distinction is enforced
mechanically rather than left to reviewer judgment.

## How it works

- `hooks/hooks.json` — registers `hooks/technique-gate.sh` under
  `PreToolUse` (`matcher: "Write|Edit|MultiEdit|NotebookEdit"`), scoped to
  `${CLAUDE_PLUGIN_ROOT}` (matcher widened to `NotebookEdit` in issue-13's
  closeout so it reaches the gate's already-existing `NotebookEdit`
  reconstruction branch).
- `hooks/technique-gate.sh` — fail-closed `PreToolUse` gate, sourcing
  `tokenmaxxxer-core`'s `core/hooks/lib/gate-lib.sh`/`gate-lib.py` (the
  gate-house standard, core issue #72, reference only) with an
  `||`-guarded source line (issue-75/issue-13: an unreachable core now
  denies via exit 2 instead of silently allowing every write, covered by
  a dedicated missing-core deny test case) for the trap, kill switch,
  JSON parse, path normalize, and `Write`/`Edit`/`MultiEdit`/
  `NotebookEdit` reconstruction. Fires only on writes to
  `docs/issue-<n>/reports/test-authoring.md`. Checks, per paragraph
  (blank-line-delimited): (1) an EP/BVA technique-naming keyword must
  share a paragraph with a test-case-shaped reference (a heading, a
  bullet, or a `test`-prefixed token) — a citation dropped elsewhere in
  the document no longer counts; (2) if a paragraph makes a thoroughness
  claim, a mutation-testing mention must appear in that same paragraph.
  Kill switch: `EP_BVA_TECHNIQUE_GATE_OFF` — only a recognized on-spelling
  (`1`/`true`/`yes`/`on`) disables the gate; empty, a recognized
  off-spelling, or any unrecognized value all keep it active (the
  correctness fix: the pre-issue-10 version disabled on any unrecognized
  value).
- `tests/technique-gate-tests.sh` — real-subprocess allow/deny cases
  against a throwaway git-init'd fixture, including the mandatory `Edit`/
  `MultiEdit`-with-`replace_all`, malformed-JSON, unrecognized-kill-switch-
  stays-active, and absolute/`./`-path cases, plus adjacency-upgrade
  cases (citation present but not paragraph-adjacent to a test reference).

## Scope of evidence

The detection keyword sets and their false-positive/false-negative
tradeoffs are exactly as analyzed in
`docs/issue-7/reports/test-authoring/scout-brief.md` and
`docs/issue-7/proposals/methodology-enforcement-machine.md` §3.3.2 — this
plugin implements that analysis, it does not re-derive it. Presence-based
(`has_any`) keyword checks trade false-deny (unusual phrasing) against
false-allow (phrase present but not meaningfully satisfying the
requirement); that tradeoff is accepted, not hidden, per the same
document's §6.
