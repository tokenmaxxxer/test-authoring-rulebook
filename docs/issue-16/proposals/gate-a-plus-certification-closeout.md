# issue-16 proposal — test-authoring A+ certification closeout

## What was asked

Issue #16: resolve the single named 2026-08-01 certification-audit
blocking reason against this role's root `README.md` — scaffolding
residue at lines 5 and 43 — so the rulebook clears A+ certification.
Required: full resolution, tests kept green (shipping-status / clean
clone basis) through any code change, and a record of confirmation
(relevant test/probe run log) once resolved.

## Survey pointer

`docs/issue-16/reports/test-authoring/survey.md` — confirms the
blocker's exact location (`README.md:5` and `README.md:43-45`), quotes
both spots verbatim, and traces why they were never cleaned up by the
issue-7/issue-10/issue-13 rounds (none were scoped to the root README's
own status language). Also confirms requirement 2 ("sales만 해당") does
not apply to this role, so no core #78 landing check gates this
role's work.

## Adopted methodology

This is a documentation-only fix with no gate-script, hook, or test
logic involved, so "tests green" here means: no plugin `tests/*.sh`
suite is touched, and `bash tests/run-all-gate-tests.sh` (the harness
all four gate plugins share) must still pass unchanged before and
after the edit, as the record evidence that the edit had zero
behavioral effect.

1. **Line 5 (part of the opening paragraph, lines 3-5)** — drop
   "and generated as skeleton scaffolding by issue-167" from the
   sentence. Keep the accurate lineage fact (split off per
   `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion);
   remove only the self-describing-as-scaffolding clause, since the
   repo is no longer a skeleton by the time of this closeout (three
   substantive remediation rounds have landed since).

2. **Lines 43-45** — remove the "This is scaffolding, not a finished
   rulebook: fill in doctrine detail, handoff enforcement, and any
   role-specific progress gate before treating it as load-bearing."
   paragraph entirely. Its three named gaps are each already closed on
   `main`: doctrine detail and handoff enforcement are covered by the
   gate scripts and `docs/specs/approvers.md` this same README
   describes a few lines earlier, and the role-specific progress gate
   item is stale in the other direction — `test-authoring/README.md`
   already documents that `test-authoring-progress-gate.sh` was
   deliberately removed under issue-10's gate-house-standard migration
   (a design decision, not an unfilled gap). No replacement paragraph
   is needed; deleting it is not deleting a promise, it is deleting a
   stale disclaimer whose preconditions were satisfied by prior issues.

3. **Verification** — after the edit, run
   `bash tests/run-all-gate-tests.sh` and confirm it exits 0 with the
   same case count as before (a text-only README edit should not change
   any suite's case count). Record the full run output verbatim in
   phase-2's `docs/issue-16/reports/test-authoring.md`, matching the
   evidence shape issue-10 and issue-13's records used.

## Rationale

The issue names exact line numbers for a reason: this is a closeout of
a specific, already-diagnosed defect, not an open design question.
Removing rather than rewriting-in-place is correct because both spots
are purely self-referential meta-commentary about the repo's own
maturity (not user-facing behavior documentation) and their stated
preconditions ("fill in X before treating as load-bearing") are already
met by landed work — rewriting them into new scaffolding language would
just recreate the same stale-disclaimer problem the issue is closing
out. This mirrors issue-13's item 5 principle (doc-follows-code,
delete-only where the survey confirms no live pointer remains) applied
to the root README instead of a plugin README.

## Plugin reflection plan

Touches only the repo-root `README.md`. No plugin directory
(`test-authoring/`, `adr-proposal-shape/`, `ep-bva-technique/`,
`traceability-line/`, `xunit-suite-patterns/`), gate script, hooks.json,
or test file changes — this blocker is scoped entirely to the root
file's own prose, confirmed by the survey. Phase-2 also adds
`docs/issue-16/reports/test-authoring.md` (the final record with the
`run-all-gate-tests.sh` confirmation log) but that is a docs-only
artifact, not a plugin reflection.

## Deliberately out of scope

- **Requirement 2 (sales / core #78)** — not this role's concern; the
  issue itself scopes it to `sales` only. No action taken or needed
  here.
- **Any gate-script, hooks.json, or test-suite change** — issue #16
  names no gate-script defect (unlike issue-10/issue-13); the survey
  found none. Re-auditing the four plugins' gates again here would be
  scope creep beyond what this issue asks.
- **Rewriting other README sections** — the survey found the rest of
  `README.md` (plugin/gate/test-harness description,
  `docs/specs/approvers.md` pointer) current and accurate; only lines
  5 and 43-45 are addressed.

Sources: this repo's `README.md` (current state, read directly);
`docs/issue-16` issue body (`gh issue view 16`);
`docs/issue-13/proposals/gate-a-plus-final-closeout.md` and
`docs/issue-10/proposals/gate-a-plus-remediation.md` (precedent for
proposal shape and record-evidence format);
`docs/issue-16/reports/test-authoring/survey.md`.
