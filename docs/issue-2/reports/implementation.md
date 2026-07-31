# Record: implementation — issue-2 (phase 2)

## What was done

Executed the phase-1 proposal (`docs/issue-2/proposals/core-canon-reference-switch.md`)
verbatim, all 5 items in one batch:

1. Deleted `test-authoring/agents/warrant-hunter.md` (and the now-empty
   `test-authoring/agents/` directory). No replacement file — canon's copy
   installs via the `warrant` plugin.
2. Deleted `test-authoring/hooks/trailer-gate.sh`,
   `test-authoring/hooks/record-fields-gate.sh`,
   `test-authoring/hooks/handbook-trigger-gate.sh`. Removed their
   `PreToolUse` entries from `test-authoring/hooks/hooks.json`. Left
   `test-authoring-progress-gate.sh`'s entry and the `SessionStart`
   `directive.sh` entry untouched.
3. Rewrote `test-authoring/hooks/directive.sh` as a structural stub sourcing
   `core/hooks/lib/role-directive.sh` and calling `core_role_directive` with
   the four role-unique values (folding the old `BOUNDARY CASE` paragraph
   into `PRODUCES`, per the proposal's stated default). Verified the stub's
   printed output still contains every line the old directive printed
   (`YOU DECIDE`/`USE_WHEN`/`PRODUCES`/`WRITE_SCOPE`/`BOUNDARY CASE`/
   `HAND-OFF`) by running it with `CLAUDE_ROLE=test-authoring` against a
   local checkout of `tokenmaxxxer-core`.
4. No `RECORD_FIELDS_TERMINAL_STATES` override added — no evidence of a
   non-default terminal state, per the proposal's analysis.
5. Ran `core/hooks/tests/stub-check.sh test-authoring/hooks` (core's copy,
   from a local `tokenmaxxxer-core` checkout) against the post-switch tree.
   Output:

   ```
   stub-check: ok — no vendored 'trailer-gate.sh' under test-authoring/hooks
   stub-check: ok — no vendored 'record-fields-gate.sh' under test-authoring/hooks
   stub-check: ok — no vendored 'handbook-trigger-gate.sh' under test-authoring/hooks
   stub-check: ok — no vendored 'parse-check.sh' under test-authoring/hooks
   stub-check: ok — test-authoring/hooks/directive.sh is a role-directive stub
   ```

   Exit code 0.

Also updated `README.md`'s Install section (names `core`, `warrant`,
`scout`, `terse`, `freelunch` as companion plugins) and its Layout list
(drops the four removed files' lines, notes `directive.sh` is now a stub).

## Why

Approved phase-2 execution of the core-canon reference switch proposed in
phase 1, per issue #2 — rolls this rulebook onto core issue #63 (warrant
plugin) and #66 (role-agnostic gates + `role-directive.sh`) canon instead
of vendored copies.

## Upstream basis

- Issue #2 (this repo).
- `docs/issue-2/proposals/core-canon-reference-switch.md` (phase-1
  proposal, this repo).
- `tokenmaxxxer-core` `core/hooks/lib/role-directive.sh` and
  `core/hooks/tests/stub-check.sh` (core issue #66 canon).

## loop_state

loop_state: landed

## Open findings

None. The proposal's "deliberately out of scope" items (dropped
role-specific `produces`-field enforcement, becoming advisory-only; the
pre-existing `test-authoring-progress-gate.sh` file gap) stand as noted in
the phase-1 proposal — not addressed by this issue.
