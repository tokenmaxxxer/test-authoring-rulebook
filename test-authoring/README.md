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

Enforcement: advisory via `hooks/directive.sh` PRODUCES text; no local
`record-fields-gate.sh` (canon-referenced per issue #63 / issue-2
precedent). Hard-gating items 4-5 was left to a future explicit decision,
not pre-decided by issue-1.
