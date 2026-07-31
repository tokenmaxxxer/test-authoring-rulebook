# issue-2 current-state survey (implementation, phase 1)

## This repo's tree (as of main, commit 2c90c03)

```
test-authoring/
  .claude-plugin/plugin.json
  agents/warrant-hunter.md          <- local warrant-hunter copy
  hooks/hooks.json
  hooks/directive.sh                <- local, hand-written SessionStart directive
  hooks/trailer-gate.sh             <- byte-identical logic to core canon, role token substituted
  hooks/record-fields-gate.sh       <- role-specific produces-field check (NOT the same check as core canon)
  hooks/handbook-trigger-gate.sh    <- placeholder verdict (exit 0), never implemented
docs/specs/approvers.md             <- empty, no approvers listed yet
```

## core canon, confirmed present on tokenmaxxxer/tokenmaxxxer-core@main

- `core/hooks/hooks.json` — `core` plugin's own PreToolUse block matches `.*`
  (every tool call, every plugin install) and fires `board-gate.sh`,
  `approval-gate.sh`, `gh-guard.sh`, `trailer-gate.sh`, `record-fields-gate.sh`,
  `handbook-trigger-gate.sh`. Installing the `core` plugin (marketplace entry,
  every role installs it) already runs all three role-agnostic gates globally —
  a rulebook's own copies and hooks.json entries for these three are pure
  duplication, not a second source of enforcement.
- `core/hooks/trailer-gate.sh` — role-blind, reads `CLAUDE_ROLE` from env for
  its message prefix. Our local copy differs only in the hardcoded
  `test-authoring` prefix; logic is otherwise identical.
- `core/hooks/handbook-trigger-gate.sh` — a real implementation (operational
  surface heuristics: package manifests, Dockerfiles, .env, migrations, CI
  workflows, deploy scripts). Our local copy is a stub that always exits 0 —
  core's version is strictly more capable, not a downgrade.
- `core/hooks/record-fields-gate.sh` — enforces contract §20's *generic*
  record fields (what-was-done, why, upstream-basis, loop_state,
  open-findings) on writes to `docs/issue-<n>/reports/<role>.md`, reading
  `CLAUDE_ROLE` for the filename to match and `RECORD_FIELDS_TERMINAL_STATES`
  (space-separated, default `landed`) for which `loop_state` values count as
  terminal (skip the next-steps/resolution-path requirement).
  **This is not the same check as our local copy.** Our local
  `record-fields-gate.sh` enforces *this role's* `produces` fields
  (`suite-architecture-note`, `fixture-strategy`, `smell-list` — issue-167's
  role-specific set) on the same file path. Core canon has no equivalent for
  role-specific `produces` fields; adopting core canon drops that check
  entirely rather than replacing it with something equivalent. See the
  proposal's open-question section.
- `core/hooks/lib/role-directive.sh` — sourceable `core_role_directive()`
  taking four args (`you_decide`, `use_when`, `produces`, `hand_off`), reading
  `CLAUDE_ROLE` and a per-role `<ROLE>_CYCLE_OFF` kill switch, printing the
  same directive shape our local `directive.sh` prints by hand plus the
  `RECORD:` trailer line.
- `core/hooks/tests/stub-check.sh` — drift-recurrence check. Fails if any of
  `trailer-gate.sh` / `record-fields-gate.sh` / `handbook-trigger-gate.sh` /
  `parse-check.sh` exist anywhere under a rulebook's `hooks/` tree (any depth
  <=3), and structurally validates that `directive.sh` is a stub: sources
  `role-directive.sh`, calls `core_role_directive`, and contains no other
  non-blank/non-comment line beyond variable assignments.
- `tokenmaxxxer-core/.claude-plugin/marketplace.json` — the `warrant` plugin
  entry's description states directly: "Canonical source for this plugin;
  role rulebooks reference it rather than vendoring a copy." `warrant` is
  installed as its own plugin (`source: ./warrant`) alongside `core`, `terse`,
  `scout`, and each role's own rulebook plugin — not embedded inside a role's
  agents/ directory.
- `warrant/agents/warrant-hunter.md` on core is the canon hunt agent (rotating
  stances, diff-proportional budget, miss-streak backoff — see
  `warrant/README.md`). Our local `agents/warrant-hunter.md` explicitly says
  it is "adapted from implementation-rulebook's agents/warrant-hunter.md" and
  is an unfinished skeleton (stance set "TBD, enumerate before shipping").

## Sibling repos (board state — main branch only, per contract's "board is
what is merged" rule)

- `tokenmaxxxer/implementation-rulebook@main` (the repo our local
  warrant-hunter.md says it was adapted from) **has not migrated either**:
  `coding/hooks/` still carries its own `trailer-gate.sh`,
  `record-fields-gate.sh`, `handbook-trigger-gate.sh`, `directive.sh` (a
  hand-written, non-stub SessionStart directive), and `coding/agents/` a full
  local warrant-hunter copy. There is no landed reference implementation of
  this migration anywhere in the org yet — this repo is not copying an
  existing sibling's phase-2 landing, it is working from core canon directly.

## Gaps found, not in the issue's 5 items but relevant

- `hooks/hooks.json`'s Bash matcher also wires
  `${CLAUDE_PLUGIN_ROOT}/hooks/test-authoring-progress-gate.sh` — **this file
  does not exist anywhere in the repo.** Pre-existing broken reference,
  unrelated to the canon-reference switch; noted here, left alone (out of
  this issue's 5-item scope) unless the approver wants it folded in.
- `docs/specs/approvers.md` is still empty (comment-only). Not this issue's
  concern, but phase 2 cannot open here via single-account APPROVE until an
  account is listed.

## loop_state

surveyed
