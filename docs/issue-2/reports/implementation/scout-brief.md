# issue-2 scout brief (implementation, phase 1)

Mode: batched-sequential fallback, not concurrent — angles were run as
sequential `gh api`/`curl` calls in this session, not parallel tool calls or
subagents. Stated per scout-directive's explicit-fallback rule. 2 stages used
(sweep + one deepening round), well under the 5-stage/3min budget.

Angles swept: (1) core canon repo tree (tokenmaxxxer-core) for the exact
promoted files issue #63/#66 describe, (2) the `warrant` plugin's own README
for how a role rulebook is meant to *consume* it, (3) `stub-check.sh`'s own
source for the pass/fail shape a stub must satisfy, (4) one sibling rulebook
(implementation-rulebook, the repo our local warrant-hunter.md cites as its
origin) to check whether a landed reference migration already exists.

## Must-bes (what a correct migration is required to do, per canon)

- `directive.sh` must be a **structural stub**: source
  `core/hooks/lib/role-directive.sh`, call `core_role_directive` with this
  role's 4 values, no other non-blank/non-comment/non-assignment line.
  `stub-check.sh` enforces this mechanically, line by line.
- `trailer-gate.sh` / `record-fields-gate.sh` / `handbook-trigger-gate.sh`
  copies **must not exist anywhere under hooks/** (any depth <=3) —
  absence-based check, not a "keep a thin wrapper" allowance.
- `hooks.json` must drop the PreToolUse entries for those three filenames
  (core's own `core/hooks/hooks.json` already fires them for every plugin
  install via a `.*` matcher — a role's own hooks.json entry is a *second*,
  redundant registration, not the only one).
- `agents/warrant-hunter.md` must not exist; the canon copy lives at
  `core/warrant/agents/warrant-hunter.md` and is installed via the `warrant`
  plugin entry in this org's marketplace, which every role installs alongside
  its own rulebook plugin (confirmed from `warrant`'s marketplace.json
  description: "role rulebooks reference it rather than vendoring a copy").
- Role-unique content is preserved, not dropped: the `you_decide` /
  `use_when` / `produces` / `hand_off` strings this role's directive already
  states, and — if this role's terminal `loop_state` set differs from core's
  default (`landed`) — an explicit `RECORD_FIELDS_TERMINAL_STATES` env var in
  this role's own `hooks.json`. Survey found no role-specific terminal state
  for `test-authoring` beyond `landed`, so no override is needed (see
  proposal).

## Adopt / skip

- **Adopt**: absence-based removal of the three gate copies + hooks.json
  entries — every promoted-canon rulebook is expected to converge on exactly
  this shape (`stub-check.sh` treats a re-added copy as drift, not a stub).
- **Adopt**: `directive.sh` as a pure stub calling `core_role_directive`,
  matching the shape `core/hooks/lib/role-directive.sh`'s own header
  docstring specifies verbatim.
- **Skip**: writing a local wrapper/adapter script around any of the three
  gates "just in case" core's version differs slightly from ours — the one
  real semantic difference found (role-specific `produces`-field enforcement
  in our local `record-fields-gate.sh`, which core's canon does not check at
  all) is a genuine gap, not a reason to keep a shadow copy; flagged as an
  open question in the proposal instead of silently forking behavior.

## Gap line

Already meets the field's must-bes: this role's `trailer-gate.sh` is
already logic-identical to canon (only the role-token prefix differs) and its
`directive.sh` already states the 4 role-unique values core's stub format
needs verbatim — the rewrite is closer to relabeling than to new design.
Missing: the produces-field check (`suite-architecture-note`,
`fixture-strategy`, `smell-list`) that our local `record-fields-gate.sh`
enforces has no canon equivalent — adopting core canon as specified drops
that enforcement rather than replacing it.

## Segment fit

`test-authoring` is a 5-item mechanical rollout of an already-merged core
promotion (core issues #63/#66), not a product build — the "exemplars" here
are the canon files themselves and the one sibling repo checked, not
market products. One line suffices.

Sources:
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/hooks.json
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/lib/role-directive.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/tests/stub-check.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/trailer-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/record-fields-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/core/hooks/handbook-trigger-gate.sh
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/warrant/README.md
- https://github.com/tokenmaxxxer/tokenmaxxxer-core/blob/main/.claude-plugin/marketplace.json
- https://github.com/tokenmaxxxer/implementation-rulebook/blob/main/coding/hooks/directive.sh

## loop_state

scouted
