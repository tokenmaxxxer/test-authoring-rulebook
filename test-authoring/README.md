# test-authoring role

Adopted per issue-1 (approved phase-2, `docs/issue-1/proposals/test-authoring-methodology-norms.md`).

## Phase-1 proposal — required sections (ADR-derived)

1. What was asked
2. Current-state survey pointer
3. Adopted methodology + required phase-2 components
4. Rationale — each adopted item traced to domain research, not preference
5. Plugin reflection plan
6. Deliberately-out-of-scope

Every methodology claim carries a `Sources:` citation back to the scout
brief; unsourced claims are stated as labeled assumptions, never fact.

## Phase-2 deliverable — required components

1. Suite architecture note — test-level classification (unit / integration
   / e2e, test pyramid) and why that level fits the code under test.
2. Fixture strategy — fresh vs shared fixture choice per suite (Meszaros).
3. Smell list — named against Meszaros' test-smell catalog when
   reviewing/refactoring an existing suite.
4. Test-design-technique reference — each nontrivial test case cites the
   technique that produced it (EP/BVA at minimum; mutation testing named
   only when the record claims suite thoroughness).
5. Traceability line — one line per suite linking it to the issue/
   requirement it covers.

Enforcement (issue-7): a plugin-set, not one combined gate — each adopted
methodology is its own independently-registered plugin, mirroring how
core registers `freelunch` and `scout` separately rather than folding both
into one:

- **Phase-1 proposal norm** = `adr-proposal-shape` alone (six required
  sections + `Sources:` + survey-exists order constraint on
  `docs/issue-<n>/proposals/*.md`).
- **Phase-2 deliverable norm** = `xunit-suite-patterns` + `ep-bva-technique`
  + `traceability-line`, composed by all three gates firing on the same
  `docs/issue-<n>/reports/test-authoring.md` write — the record is
  well-formed only when all three independently pass (the norm is the
  conjunction, not a fourth combined gate).

`hooks/directive.sh`'s PRODUCES text now points at these composing
plugins by name instead of inlining the requirements; each plugin ships
its own `README.md`/`hooks.json`/kill switch/tests
(`docs/issue-7/proposals/methodology-enforcement-machine.md` §3.3.1).

## Gate-house standard migration (issue-10)

All four composing plugins' `Write|Edit|MultiEdit` gates
(`adr-proposal-shape`, `ep-bva-technique`, `traceability-line`,
`xunit-suite-patterns`) source `tokenmaxxxer-core`'s
`core/hooks/lib/gate-lib.sh`/`gate-lib.py` (the gate-house standard, core
issue #72) for their fail-closed trap, kill-switch check, JSON parsing,
path normalization, and `Write`/`Edit`/`MultiEdit`/`NotebookEdit`
reconstruction, replacing former hand-rolled copies — reference only,
never vendored. This base plugin has no `Write|Edit|MultiEdit` gate of
its own to migrate.

This plugin's own `hooks.json` previously registered a `PreToolUse`/
`Bash` hook pointing at `test-authoring-progress-gate.sh`, a script that
never existed in this repo — every `Bash` tool call in this role's
session failed the hook launch. That dangling entry is removed; the
role's five real methodology checks all live in the four composing
plugins, matched on `Write|Edit|MultiEdit`. `gate_bash_write_targets`
(gate-lib.sh) stays unadopted here — none of the four real gates need
`Bash`-write detection (their write surfaces are role-authored markdown
under `docs/`, not shell-command targets).
