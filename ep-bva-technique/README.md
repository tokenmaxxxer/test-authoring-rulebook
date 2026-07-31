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
  `PreToolUse` (`matcher: "Write|Edit|MultiEdit"`), scoped to
  `${CLAUDE_PLUGIN_ROOT}`.
- `hooks/technique-gate.sh` — fail-closed `PreToolUse` gate. Fires only on
  writes to `docs/issue-<n>/reports/test-authoring.md`. Reconstructs the
  resulting content for `Write`/`Edit`/`MultiEdit` (denying when it cannot
  be determined) and checks, on the lower-cased text: (1) at least one
  EP/BVA technique-naming keyword is present, denying otherwise; (2) if a
  thoroughness-claim keyword is present, at least one mutation-testing
  keyword must also be present, denying otherwise. Kill switch:
  `EP_BVA_TECHNIQUE_GATE_OFF` (off-means-off; an unrecognized non-empty
  value disables the gate and logs a warning, mirroring `freelunch.sh`).
- `tests/technique-gate-tests.sh` — five real-subprocess allow/deny cases
  against a throwaway git-init'd fixture, per
  `implementation-rulebook/tests/run-gate-tests.sh`'s pattern.

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
