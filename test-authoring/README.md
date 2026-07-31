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
`test-authoring-progress-gate.sh` (referenced in `hooks.json`) remains a
pre-existing missing file, out of this issue's scope.
