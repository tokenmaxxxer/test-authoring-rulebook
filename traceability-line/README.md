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
- `hooks/traceability-gate.sh` — fail-closed `PreToolUse` gate, sourcing
  `tokenmaxxxer-core`'s `core/hooks/lib/gate-lib.sh`/`gate-lib.py` (the
  gate-house standard, core issue #72, reference only) for the trap,
  kill switch, JSON parse, path normalize, and `Write`/`Edit`/`MultiEdit`/
  `NotebookEdit` reconstruction. Fires only on writes to
  `docs/issue-<n>/reports/test-authoring.md`. Denies (exit 2) when: (a) no
  traceability-keyword line is present at all, or (b) a traceability line
  is present but cites an issue number that does not match the issue
  number in the current git branch name (`issue-<n>/...`). Already
  line-scoped (not substring theater), so issue-10's semantic upgrade
  requirement applies no change here beyond the gate-lib migration. Kill
  switch: `TRACEABILITY_LINE_GATE_OFF` — only a recognized on-spelling
  (`1`/`true`/`yes`/`on`) disables the gate; empty, a recognized
  off-spelling, or any unrecognized value all keep it active (the
  correctness fix: the pre-issue-10 version disabled on any unrecognized
  value).
- `tests/traceability-gate-tests.sh` — real-bash-subprocess allow/deny
  test cases exercising the gate against a throwaway git-init'd fixture,
  including the mandatory `Edit`/`MultiEdit`-with-`replace_all`,
  malformed-JSON, unrecognized-kill-switch-stays-active, and
  absolute/`./`-path cases.

## Scope of evidence

This plugin's keyword sets and heuristics were derived from
`docs/issue-7/reports/test-authoring/scout-brief.md`'s "Must-bes" and
"Adopt / skip" sections and from the same-org
`pricing/hooks/methodology-gate.sh` and `freelunch`/`scout` plugin shapes,
not from independent measurement on this role's own record corpus —
presence-based keyword checks trade false-deny (unusual phrasing) against
false-allow (phrase present but not meaningfully satisfying the
requirement), a tradeoff accepted here, not hidden.
