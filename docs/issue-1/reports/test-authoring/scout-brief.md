# Scout brief — test-authoring domain norms (issue-1)

Mode: parallel WebSearch fan-out, 4 angles, 1 sweep round + 1 deepening round
(2 stages total, well under the 5-stage/3min budget — clear saturation after
round 2, no further deepening needed).

## Category must-bes (what strong test-design references converge on)

- A named **fixture strategy** per test, distinguishing fresh vs shared
  fixtures and their tradeoff (isolation speed vs setup cost) — xUnit Test
  Patterns' core organizing concept.
- A **test-smell vocabulary** used to critique suites, not just write them
  (Meszaros catalogs 18) — smell-naming is how a reviewer communicates
  "this test is bad" precisely instead of vaguely.
- Explicit **test design technique(s)** behind each test case, not ad hoc
  inputs — equivalence partitioning / boundary value analysis is the
  textbook minimum; branch/mutation coverage as a stronger technique class.
- A stated position on **test level** (unit/integration/e2e — "test
  pyramid") so suite architecture decisions are traceable to a rationale,
  not vibes.
- Traceability from test artifact back to the requirement/feature it
  covers — IEEE 829's core discipline (test design spec references the
  test plan; test case spec references the test design spec).

## Performance axes strong references compete on

1. **Isolation vs speed** — fresh-fixture-per-test (safe, slow) vs
   shared-fixture (fast, coupling risk). Meszaros' explicit tradeoff.
2. **Precision of defect-detection claim** — EP/BVA (cheap, moderate) vs
   mutation testing (expensive, strongest fault-detection evidence) vs bare
   line coverage (cheap, weak signal, widely criticized as a false proxy).
3. **Documentation weight** — IEEE 829's 8-stage full doc set (heavy,
   waterfall-shaped) vs lightweight ADR-style single-decision records
   (light, agile-shaped, adopted industry-wide over IEEE 829's full stack).

## Adopt

- Meszaros' fixture-strategy naming + test-smell catalog as the vocabulary
  a test-authoring `PRODUCES` record must speak in — it already appears in
  this role's directive.sh (`suite architecture note, fixture strategy,
  smell list (Meszaros catalog refs)`), so this is confirmation, not a
  change: the existing PRODUCES field is textbook-grounded, not invented.
- ADR's 5-section shape (Title/Status/Context/Decision/Consequences, plus
  the widely-added **Rationale** section that Nygard's original template
  lacks) as the phase-1 proposal's required-section skeleton — lighter than
  IEEE 829's full document hierarchy, matches this repo's own
  `docs/*/proposals/` precedent (issue-2's proposal already follows a
  What-was-asked / Constraints / Plan / Out-of-scope shape close to this).
- EP/BVA as the required minimum test-design technique reference for
  phase-2 test cases; mutation testing named as the technique to justify
  *coverage claims* when the suite claims thoroughness, not as a blanket
  requirement (expensive; not always warranted).

## Skip

- IEEE 829's full 8-document hierarchy (test plan / design spec / case
  spec / procedure spec / item transmittal / log / incident report /
  summary report) — this role produces one record file per contract v3
  s19, not eight; adopting the full standard would conflict with the
  role-handoff contract's single-record-file structure. Take its
  *traceability principle* (test → requirement) without its document count.
- Bare code-coverage-percentage as a required metric — repeatedly flagged
  in the test-design literature as a weak, gameable proxy next to
  EP/BVA/mutation-based claims; not adopted as a required PRODUCES field.

## Gap line (field must-bes vs this rulebook's current state)

Already met: fixture-strategy naming, smell-list vocabulary (both already
named in `test-authoring/hooks/directive.sh`'s PRODUCES string).
Missing: no required test-design-technique reference (EP/BVA/mutation)
anywhere in directive or record fields; no requirement to state test level
(unit/integration/e2e) per suite; no traceability field tying a suite back
to the requirement/issue it covers; phase-1 proposal has no fixed required-section
skeleton (relies on convention from issue-2's proposal alone, not a stated
norm).

## Segment fit

test-authoring here is a single-role rulebook plugin producing one record
per issue (not a QA org running full IEEE 829 doc suites) — so the fit is
toward lightweight, textbook-grounded vocabulary embedded in existing
gate/record fields, not toward standing up a new document hierarchy.

## Sources

- [xUnit Test Patterns (Meszaros) — Agile Alliance](https://agilealliance.org/resources/books/xunit-test-patterns-refactoring-test-code/)
- [xunitpatterns.com](http://xunitpatterns.com/)
- [Test Fixture Strategies — John Sanda](http://johnsanda.blogspot.com/2008/03/in-his-book-xunit-test-patterns-gerard.html)
- [Software Testing Pyramid Guide 2025 — Devzery](https://www.devzery.com/post/software-testing-pyramid-guide-2025)
- [Modern Test Pyramid Guide — Full Scale](https://fullscale.io/blog/modern-test-pyramid-guide/)
- [TDD vs BDD vs DDD in 2025 — Medium](https://medium.com/@sharmapraveen91/tdd-vs-bdd-vs-ddd-in-2025-choosing-the-right-approach-for-modern-software-development-6b0d3286601e)
- [IEEE 829 Tutorial — ZetCode](https://zetcode.com/terms-testing/ieee-829/)
- [How to Write a Test Plan with IEEE 829 — Reqtest](https://reqtest.com/en/knowledgebase/how-to-write-a-test-plan-2/)
- [ADR GitHub template — pmerson](https://github.com/pmerson/ADR-template)
- [Architectural Decision Records — adr.github.io](https://adr.github.io/)
- [ADR Template & Guide — em-tools.io](https://www.em-tools.io/frameworks/architecture-decision-records)
- [Boundary Value Analysis and Equivalence Partitioning — Guru99](https://www.guru99.com/equivalence-partitioning-boundary-value-analysis.html)
- [Comparing EP/BVA/Branch Coverage via Mutation Analysis — academia.edu](https://www.academia.edu/7783094/Comparing_the_effectiveness_of_Equivalence_Partitioning_Boundary_Value_Analysis_and_Branch_Coverage_Testing_using_Mutation_Analysis)
