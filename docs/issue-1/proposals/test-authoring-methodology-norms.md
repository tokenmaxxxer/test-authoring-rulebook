# Proposal: test-authoring methodology & artifact norms (issue-1)

Phase 1 only — this document plus
`docs/issue-1/reports/test-authoring/survey.md` and `scout-brief.md` are
the entire deliverable of this PR. No plugin change ships until a phase-2
Approve lands per contract v3 s19.

## What was asked

Fix, by domain research rather than by intuition, what methodology and
required components govern (a) this role's phase-1 proposals and (b) this
role's phase-2 deliverables — then plan how that gets enforced in the
plugin (directive / record required fields / gates). Warrant-hunter and
other shared canon stay reference-only, no local copies (issue #63).

## (a) Phase-1 proposal norms

**Methodology**: ADR-style — Title / Status / **Context** / **Decision** /
**Rationale** / **Consequences**, adapted to this repo's existing
`docs/*/proposals/` shape (What-was-asked / Constraints / Plan /
Out-of-scope, as issue-2's proposal already does). Chosen over IEEE 829's
8-document hierarchy because this role produces one proposal file per
issue under contract v3 s19, not a document set — IEEE 829's per-stage
document count is structurally incompatible with the one-record-per-role
model this repo already enforces (see survey.md, "gaps").

**Required sections for a test-authoring phase-1 proposal**:
1. What was asked (verbatim issue excerpt or paraphrase, contract v3 s19
   already implies this — restated here as required, not optional)
2. Current-state survey pointer (link to the survey file, per the
   scout-directive's survey-first order)
3. Adopted methodology + required components for phase 2 (section (b)
   below)
4. Rationale — why each adopted item follows from the domain research,
   not preference (section (c) below)
5. Plugin reflection plan (section (d) below)
6. Deliberately-out-of-scope, flagging any real behavior change for the
   approver rather than silently deciding it (pattern taken directly from
   issue-2's proposal, which this repo's approver has already accepted
   once)

**Evidence format**: every adopted methodology claim carries a
`Sources:`-style citation back to the scout brief, exactly as the
scout-directive already requires of the brief itself — a phase-1 proposal
that asserts "X is standard practice" with no traceable source is
downgraded to a labeled assumption, never stated as fact.

## (b) Phase-2 deliverable norms

**Methodology**: xUnit Test Patterns (Meszaros) as the primary vocabulary
for suite design and critique, supplemented by equivalence
partitioning/boundary value analysis (EP/BVA) as the minimum required
test-design technique, with the test pyramid (unit/integration/e2e) as the
required test-level classification.

**Required components of a test-authoring phase-2 deliverable**:
1. **Suite architecture note** — test-level classification (unit /
   integration / e2e, per the test pyramid) and why that level fits the
   code under test. *(already required by current PRODUCES; kept as-is.)*
2. **Fixture strategy** — explicit choice of fresh vs shared fixture per
   Meszaros' fresh-fixture/shared-fixture tradeoff (isolation vs speed),
   stated per suite, not left implicit in test code. *(already required;
   kept as-is.)*
3. **Smell list** — named against Meszaros' 18-item test-smell catalog
   when reviewing or refactoring an existing suite. *(already required;
   kept as-is.)*
4. **Test-design-technique reference** *(new)* — each nontrivial test
   case cites the technique that produced it (EP/BVA at minimum; mutation
   testing named explicitly only when the record makes a thoroughness
   claim about the suite, since mutation testing is comparatively
   expensive and not warranted for every suite).
5. **Traceability line** *(new)* — one line per suite tying it back to the
   issue/requirement it covers, closing the gap survey.md identifies (no
   requirement→test link exists today beyond the ambient branch structure).

Items 1–3 are confirmations of the existing directive, not changes — the
scout brief found them already textbook-grounded. Items 4–5 are the
proposal's actual additions.

## (c) Rationale for each adoption

- **Fixture strategy / smell list / xUnit vocabulary**: Meszaros is the
  most-cited primary source specifically for *test code* design (not
  process methodology) — it is the only reference in the sweep whose unit
  of analysis is "is this individual test well-built," which is exactly
  this role's `YOU_DECIDE` framing ("테스트 코드 자체가 격리성·fixture
  전략 면에서 좋은 설계인가"). Adopting anything else here (e.g. a BDD
  scenario format) would answer a different question than the one the
  role already commits to answering.
- **EP/BVA as minimum, mutation testing as thoroughness-claim-only**: the
  sweep's coverage-technique comparison shows bare line-coverage
  percentage is a repeatedly-criticized weak proxy, while mutation testing
  is the strongest fault-detection evidence available but materially more
  expensive to run. EP/BVA sits at the accessible middle and is the
  textbook minimum technique any nontrivial test case should be
  attributable to — requiring it (not coverage %) as the baseline, and
  reserving mutation testing for suites that explicitly claim thoroughness,
  matches cost to claim instead of mandating the expensive technique
  everywhere or accepting the weak one everywhere.
- **Test pyramid as level classification**: near-universal reference point
  across the sweep's industry-practice sources (2025 guides still treat it
  as foundational even where TDD/BDD blend on top of it); stating a suite's
  level is cheap and makes the fixture-strategy tradeoff (isolation vs
  speed) legible — a unit suite defaulting to shared fixtures is a
  different judgment call than an integration suite doing the same.
- **ADR shape for phase-1 proposals over IEEE 829**: IEEE 829's document
  count structurally conflicts with contract v3 s19's one-proposal-file
  model (survey.md); ADR's lighter Context/Decision/Rationale/Consequences
  shape is both the industry's de facto replacement for heavyweight
  waterfall test-doc standards and already the shape this repo's own
  accepted precedent (issue-2's proposal) approximates.
- **Traceability line as a new required field**: IEEE 829's one
  transferable principle, independent of its document count, is that every
  test artifact should trace back to what it verifies. This role currently
  has no such field; adding it costs one line per suite and closes a gap
  the survey names explicitly.

## (d) Plugin reflection plan (phase 2, once approved)

1. **`directive.sh` PRODUCES string**: extend the existing `PRODUCES`
   value (keep the current fixture-strategy/smell-list/write-scope/
   boundary-case content verbatim) with two new clauses:
   `TEST-DESIGN TECHNIQUE: cite EP/BVA at minimum per nontrivial test case;
   name mutation testing only when the record claims suite thoroughness`
   and `TRACEABILITY: one line per suite linking it to the issue/
   requirement it covers`. No structural rewrite of directive.sh needed —
   this is a string edit inside the existing `PRODUCES=$'...'` heredoc.
2. **Record required fields**: this role has no local
   `record-fields-gate.sh` (canon-referenced per issue-2). The two new
   PRODUCES clauses above are enforced the same way the current three
   already are — advisory via directive text, not a new local gate file,
   consistent with issue-2's decision to rely on core's generic record-
   fields gate rather than reintroducing a role-specific enforcement file.
   If the phase-2 approver wants hard enforcement instead of advisory text,
   that is a new decision to raise explicitly at phase-2 time, not
   pre-decided here.
3. **Phase-1 proposal skeleton**: no gate can mechanically enforce prose
   section presence without a role-specific gate file, which issue-2
   deliberately avoided reintroducing. Recommend documenting the six
   required sections from (a) in this role's future `README.md` (currently
   absent, see survey.md) as the checkable reference for phase-2 work and
   for the next issue's phase-1 proposal to follow — a doc, not a hook.
4. **No new gate files**: consistent with the constraint that
   warrant-hunter/gates stay core-canon-referenced (issue #63) and with
   issue-2's precedent of not reintroducing role-local copies of
   generic-shaped enforcement. This proposal's phase-2 changes are additive
   text in `directive.sh` plus a new `README.md`, not new hook scripts.

## Deliberately out of scope

- Whether the two new PRODUCES clauses should be hard-gated (a real local
  `record-fields-gate.sh` reintroduced just for this role) versus
  advisory-only, as in plan item 2 above. Flagged for the phase-2 approver:
  hard-gating is a real behavior change (a new local file, diverging from
  issue-2's canon-only direction) and this proposal does not silently
  decide it.
- Mutation-testing tooling selection (which mutation framework, if any) —
  out of scope for a methodology/norms proposal; a tooling choice belongs
  to whichever future phase-2 session actually authors a thoroughness-
  claiming suite.
- `test-authoring/README.md` authorship itself — named as a phase-2 to-do
  in plan item 3, not written in this phase-1 PR.
