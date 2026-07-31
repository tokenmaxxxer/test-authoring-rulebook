# Current-state survey (issue-7, test-authoring)

Runs before the scout sweep, per the scout-directive's survey-first order.

## What exists today on this branch

- `test-authoring/hooks/directive.sh` — a canon stub (`core_role_directive`
  call, per issue-2's phase-2 switch). `PRODUCES` is a one-line-per-facet
  string: suite architecture note / fixture strategy / smell list, plus the
  two clauses issue-1 phase-2 added (`TEST-DESIGN TECHNIQUE`,
  `TRACEABILITY`), plus `WRITE_SCOPE` and a folded-in `BOUNDARY CASE`
  paragraph. This is exactly the "directive 한 줄(PRODUCES 요약)" issue-7
  calls insufficient — every facet is a single sentence, no stages, no
  judgment criteria, no prohibitions.
- `test-authoring/hooks/hooks.json` — registers `SessionStart` →
  `directive.sh` and one `PreToolUse` (`Bash` matcher) →
  `test-authoring-progress-gate.sh`. **That file does not exist** in
  `test-authoring/hooks/` — confirmed by `ls`; this gap predates issue-7
  (already noted in issue-2's proposal, "pre-existing gap, not one of the
  issue's 5 items"). No `PreToolUse` entry exists for `Write|Edit|MultiEdit`
  at all — nothing gates what actually lands in a proposal or record file
  today.
- `test-authoring/agents/` — does not exist (removed under issue-2's
  canon switch; warrant-hunter is installed via the `warrant` companion
  plugin, reference-only).
- `test-authoring/README.md` — documents the six phase-1 proposal sections
  and five phase-2 components (from `docs/issue-1/proposals/
  test-authoring-methodology-norms.md`), states enforcement is
  **advisory only**: "Hard-gating items 4-5 was left to a future explicit
  decision, not pre-decided by issue-1." Issue-7 is that decision point.
- No `tests/` directory anywhere in this repo (root or under
  `test-authoring/`) — no automated coverage of any gate, because no
  role-owned gate exists yet.
- `docs/specs/approvers.md` — one entry, `JiwonJung94`; single-account mode
  applies (see role-handoff contract v3 s19).

## What issue-1 already decided (methodology, adopted — not reopened here)

Source: `docs/issue-1/proposals/test-authoring-methodology-norms.md`
(approved, reflected in `docs/issue-1/reports/test-authoring.md`).

- **(a) Phase-1 proposal**: ADR-derived, 6 required sections, every
  methodology claim needs a `Sources:` citation.
- **(b) Phase-2 deliverable**: xUnit Test Patterns (Meszaros) vocabulary;
  5 required components — suite architecture note, fixture strategy, smell
  list (Meszaros 18-item catalog), test-design-technique reference (EP/BVA
  minimum, mutation testing only on a thoroughness claim), traceability
  line.
- Issue-1 explicitly declined to hard-gate any of this and named it a
  deferred decision for "the phase-2 approver" (or a future issue) to make
  explicitly — issue-7 is that trigger.

## Gaps issue-7's four asks map onto

1. **Directive depth** — current strings are one-liners; no stage/criteria/
   prohibition breakdown per facet, and stub-check.sh's structural check
   (canon, see below) means `directive.sh` itself cannot grow procedural
   logic — depth has to live in the four strings plus an external reference
   doc the strings point to.
2. **Methodology gate** — no local gate exists at all. Core's
   `record-fields-gate.sh` (canon, inherited via issue-2's switch) checks
   only the generic §20 fields (what-was-done/why/upstream/loop_state/
   open-findings) — it has no concept of this role's produces-shape fields
   (suite architecture note, fixture strategy, etc.) or of the phase-1
   6-section/Sources norm. A role-specific gate layered on top is needed;
   see scout-brief.md for the precedent this pattern already has elsewhere
   in the org.
3. **Order constraint** — issue-1's phase-1 norm requires proposal §2 to be
   "current-state survey pointer (link to the survey file, per the
   scout-directive's survey-first order)". Nothing today verifies the
   linked survey file actually exists before a proposal can be finalized —
   a proposal could claim a survey pointer to a file that was never
   written. This is the "조사→근거→채택" order issue-7 asks about, scoped
   to this role's own concrete instance of it.
4. **Repeated procedure** — the phase-2 five-component procedure (classify
   test level, choose fixture strategy per Meszaros, name smells against
   the 18-item catalog, cite EP/BVA per test case, write a traceability
   line) is currently only prose in README.md, not a checkable working
   document a session works through per suite.

## Constraints reconfirmed for this issue

- `docs/handbooks/canon-scripts.md` (fetched into this session's scratch
  copy at `/tmp/claude-1000/.../core-canon2/docs/handbooks/canon-scripts.md`
  during scouting) states the reference-not-vendor rule: canon files
  (`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`,
  `parse-check.sh`, `stub-check.sh`) are never copied into a rulebook.
  `core/hooks/tests/stub-check.sh` mechanically fails a rulebook that grows
  a local copy of any canon-manifest filename, or a `directive.sh` that
  isn't a pure stub. Any new file this issue adds must be a genuinely new
  filename, not a re-vendor of a canon name, and must not touch
  `directive.sh`'s structural shape.
- `write_scope` for this role remains `['test/**']` (unchanged) — the new
  gate/tests/checklist files this issue proposes live under
  `test-authoring/`, repo-root `tests/`, and `docs/issue-7/`, which are the
  role's proposal/record/plugin write surfaces per contract v3 s19, not
  `test/**` itself (that scope governs the role's phase-2 *test-suite*
  output, a separate write surface from its own plugin machinery).
