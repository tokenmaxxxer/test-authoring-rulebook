# traceability-line

Gates test-authoring's phase-2 record (`docs/issue-<n>/reports/
test-authoring.md`) for a one-line requirement-to-suite traceability
statement per suite section — the single methodology this plugin owns
(issue-1(b) item 5, IEEE 829's transferable requirement-to-test-case
traceability principle). A record that never states which requirement or
issue each suite section covers is denied; a record whose traceability
line cites a different issue number than the branch it's written on is
also denied, since a mismatched cross-reference is worse than a missing
one — it looks traced but points at the wrong requirement.

## How it works

- `.claude-plugin/plugin.json` — plugin identity: name, description
  (methodology owned + `use_when`), author.
- `hooks/hooks.json` — registers `hooks/traceability-gate.sh` under
  `PreToolUse` for `Write|Edit|MultiEdit`, scoped to
  `${CLAUDE_PLUGIN_ROOT}`.
- `hooks/traceability-gate.sh` — fail-closed `PreToolUse` gate. Fires only
  on writes to `docs/issue-<n>/reports/test-authoring.md`. Reconstructs the
  resulting content for `Write`/`Edit`/`MultiEdit` and denies (exit 2) when:
  (a) no traceability-keyword line is present at all, or (b) a
  traceability line is present but cites an issue number that does not
  match the issue number in the current git branch name
  (`issue-<n>/...`). Fails closed (denies) whenever the resulting content
  cannot be determined, or when no project root can be resolved. Kill
  switch: `TRACEABILITY_LINE_GATE_OFF` (off-means-off; only
  `""|0|false|no|off` count as not-off, any other non-empty value
  disables the gate, with a warning on unrecognized values).
- `tests/traceability-gate-tests.sh` — real-bash-subprocess allow/deny
  test cases exercising the gate against a throwaway git-init'd fixture,
  per proposal §3.3.3's four enumerated cases.

## Scope of evidence

This plugin's keyword sets and heuristics were derived from
`docs/issue-7/reports/test-authoring/scout-brief.md`'s "Must-bes" and
"Adopt / skip" sections and from the same-org
`pricing/hooks/methodology-gate.sh` and `freelunch`/`scout` plugin shapes,
not from independent measurement on this role's own record corpus —
presence-based keyword checks trade false-deny (unusual phrasing) against
false-allow (phrase present but not meaningfully satisfying the
requirement), a tradeoff accepted here, not hidden.
