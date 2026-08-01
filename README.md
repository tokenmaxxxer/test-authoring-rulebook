# test-authoring-rulebook

Rulebook for the `test-authoring` role (contract v3 role-handoff protocol), split off
per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
generated as skeleton scaffolding by issue-167.

- **decides**: 테스트 코드 자체가 격리성·fixture 전략 면에서 좋은 설계인가
- **use_when**: 신규/기존 테스트 스위트를 설계·리뷰할 때
- **produces**: suite architecture note, fixture strategy, smell list (Meszaros catalog refs)
- **write_scope**: ['test/**']
- **hand-off**: 실제 실행 결과 관찰은 → execution-observation

## Install

This rulebook expects the following companion plugins installed alongside it:
`core`, `warrant`, `scout`, `terse`, `freelunch`.

```
claude plugin marketplace add tokenmaxxxer/test-authoring-rulebook
claude plugin install test-authoring
claude plugin install core
claude plugin install warrant
claude plugin install scout
claude plugin install terse
claude plugin install freelunch
```

## Layout

- `test-authoring/.claude-plugin/plugin.json` — plugin manifest
- `test-authoring/hooks/hooks.json` — SessionStart wiring
- `test-authoring/hooks/directive.sh` — SessionStart role directive (stub over core's `role-directive.sh`)
- `adr-proposal-shape/`, `ep-bva-technique/`, `traceability-line/`,
  `xunit-suite-patterns/` — the four composing plugins that enforce this
  role's methodology norms (issue-7), each with its own
  `PreToolUse`/`Write|Edit|MultiEdit` gate migrated to
  `tokenmaxxxer-core`'s gate-house standard (issue-72/issue-10)
- `tests/resolve-core.sh`, `tests/run-all-gate-tests.sh` — shared test
  harness resolving `CLAUDE_PLUGIN_ROOT_CORE` and aggregating each
  plugin's gate test suite
- `docs/specs/approvers.md` — Approve-authority allowlist (see below)

This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing.
