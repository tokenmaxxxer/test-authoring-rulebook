# Current-state survey — test-authoring rulebook (issue-1)

## Write surfaces in this plugin

- `test-authoring/hooks/directive.sh` — already stubbed onto core canon
  (`core_role_directive`, per issue-2 phase 2, merged in 9377f98). Carries
  four role-unique strings: `YOU_DECIDE`, `USE_WHEN`, `PRODUCES`,
  `HAND_OFF`. `PRODUCES` currently reads:
  `"suite architecture note, fixture strategy, smell list (Meszaros catalog
  refs)\nWRITE_SCOPE: ['test/**']\nBOUNDARY CASE: ..."`.
- `test-authoring/hooks/hooks.json` — `SessionStart` → `directive.sh`;
  `PreToolUse` (`Bash` matcher) → `test-authoring-progress-gate.sh`, a file
  that does not exist in the tree yet (gap predates this issue, noted in
  issue-2's proposal).
- No `record-fields-gate.sh`, `trailer-gate.sh`, `handbook-trigger-gate.sh`,
  or `warrant-hunter.md` locally — all switched to core canon reference in
  issue-2 phase 2. This issue must not reintroduce local copies; any new
  gate this proposal calls for goes into a role-owned file, or as a
  `RECORD_FIELDS_TERMINAL_STATES`/env override on the existing hooks.json
  entries, consistent with issue-2's stated pattern.
- No `test-authoring/README.md` exists yet.
- No prior `docs/issue-1/` tree existed before this session.

## Unknowns / thin surfaces this scout sweep must aim at

- `PRODUCES` names "smell list (Meszaros catalog refs)" and "fixture
  strategy" but the rulebook has never stated *why* these specific
  vocabulary items were chosen over alternatives (coverage %, BDD
  scenarios, IEEE 829 style docs) — no documented methodology rationale.
- No required section skeleton exists for this role's own phase-1
  proposals — the only local precedent is issue-2's proposal, written
  under contract v3 s19 generically, not under a test-authoring-specific
  proposal norm.
- No test-design-technique requirement (EP/BVA/mutation) or test-level
  statement (unit/integration/e2e) anywhere in directive or record fields.
- No traceability field connecting a produced suite back to the issue/
  requirement it covers, beyond the ambient one-branch-per-issue structure.

These four gaps are what the scout brief's sweep (textbook test-design
patterns, test-pyramid/BDD/TDD industry practice, IEEE 829 documentation
norms, ADR/RFC proposal-writing norms) was aimed at. See
`scout-brief.md` in this directory for findings and the adopt/skip
decisions built on them.
