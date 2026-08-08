---
status: proposed
files:
  - test-authoring/README.md
  - xunit-suite-patterns/README.md
  - ep-bva-technique/README.md
  - docs/specs/record-fields-terminal-states.json
  - docs/issue-19/reports/implementation.md
---

# Align rulebook with `test-authoring.spec.json` (issue-19)

## Request

Align this rulebook's vocabulary and rules with the realized marketplace
spec `roles/specs/test-authoring.spec.json` (on-the-record). Layer the
spec's required deliverable fields (`test_id`, `test_items`,
`input_spec`, `output_spec`, `environment`) and its `loop_state`
vocabulary (`drafting`, `items-undeclared`, `landed`, `running`,
`test-unreachable`) onto the rulebook's existing methodology docs and
hooks — strengthening what exists, deleting nothing.

## Constraints

- Every spec required-field name (`test_id`, `test_items`, `input_spec`,
  `output_spec`, `environment`) must appear in `docs/` or `README.md`
  after phase 2 (grep-checked by the issue's acceptance criteria).
- The rulebook's `loop_state` vocabulary must match the spec set
  exactly — no stale or extra states.
- A spec field with no natural home must be stated explicitly, with
  reasoning, not silently dropped (issue's empty-state rule).
- No methodology content gets deleted; the five existing phase-2
  components (suite architecture note, fixture strategy, smell list,
  technique reference, traceability line) all stay intact.
- `test-authoring` is not one of role-handoff-contract v3 §2's
  sanctioned kinds, so its `loop_state` vocabulary is this rulebook's
  own to declare, via the contract's own override mechanism
  (`docs/specs/record-fields-terminal-states.json`, a `{kind: [states]}`
  object — contract v3 §2 note).

## Rationale

**Alternative considered: add a new gate script per new field
(`output_spec`, `environment`) instead of documentation-only mapping.**
Rejected: the issue's acceptance checks are entirely grep- and
vocabulary-based (`grep -ri <field> docs/ README.md`, loop_state set
equality, test-suite run) — none require new enforcement logic. Adding
gate scripts for fields the spec itself marks `required: false`
(`environment`) or whose recomputation check is explicitly `TBD` in the
spec (`output_spec`) would invent enforcement the spec does not yet
ask for, and would touch `hooks/*.sh` write surfaces this proposal has
no reason to open. Doc-only changes fully satisfy every stated
acceptance check while leaving all four existing gates' semantics
alone — least write surface for the stated bar.

**Alternative considered: force-fit every field onto one of the three
existing composing plugins (`xunit-suite-patterns`, `ep-bva-technique`,
`traceability-line`) with no new record component.** Rejected for
`output_spec`: the closest existing concept (`xunit-suite-patterns`'
smell list) covers naming test smells, not stating expected outputs,
and the spec's `recomputation` rule (`output_spec` is re-run, never
asserted standalone) has no existing analog to attach to without
misrepresenting what the current gates check. Force-fitting it would
make the mapping doc claim a check exists that does not — dishonest
about the current state. Naming `output_spec` as a new, currently
gate-less phase-2 record item (documented expectation, not yet
enforced) is more honest than bending an unrelated existing check to
cover it.

**Alternative considered: invent this rulebook's own `loop_state`
vocabulary from scratch, independent of the spec's five states.**
Rejected: the issue asks for an exact match to the spec's set, and
three sibling rulebooks in the same marketplace family (`api-design-
rulebook`, `content-design-rulebook`, `release-engineering-rulebook` —
found during survey under `~/.tokenmaxxxer/work/`) already use
`docs/specs/record-fields-terminal-states.json` as the contract-
sanctioned override file for declaring a non-core-contract record
kind's `loop_state` set. Following that established sibling pattern
(Sources: the three sibling repos' own `docs/specs/record-fields-
terminal-states.json` files, e.g. api-design-rulebook's `coding-record`
entry) is more consistent with the family's doctrine than a bespoke
mechanism invented only for this repo.

## What will be done

1. **`docs/specs/record-fields-terminal-states.json`** (new file):
   declare a `test-authoring-record` kind entry matching the spec's
   `loop_state` object exactly:
   `progress: [drafting, running]`, `terminal: [landed]`,
   `refusal: [items-undeclared]`, `error: [test-unreachable]`. This
   supersedes the current free-text progress narrative in
   `docs/issue-<n>/reports/test-authoring.md` records with the
   constrained vocabulary role-handoff-contract v3 expects records to
   carry.
2. **`test-authoring/README.md`**: add a field-mapping section naming
   all five spec fields explicitly and stating each one's rulebook home:
   - `test_id` → the existing traceability line (`traceability-line`
     plugin), with an explicit note that `test_id`'s reference-
     resolution check (must resolve to a real test file, no orphans) is
     `on-the-record`'s own hook, not duplicated here.
   - `test_items` → the existing suite-architecture note (test-level
     classification / scope description).
   - `input_spec` → the existing EP/BVA technique citation
     (`ep-bva-technique` plugin) — equivalence partitioning and
     boundary-value analysis are input-domain specification techniques.
   - `output_spec` → named as a new, currently gate-less phase-2 record
     item: each nontrivial test case states its expected output
     alongside its EP/BVA-cited input, with an explicit note that the
     spec's `recomputation` rule (`output_spec` is re-run, never
     asserted standalone) is out of scope per the spec's own
     `checked_by: TBD` marker (issue-521 follow-up), stated per the
     issue's empty-state rule rather than silently skipped.
   - `environment` → named as an optional phase-2 record item
     (environmental/runtime needs for running the suite), documented
     only — no gate, matching the spec's `required: false`.
   - a `loop_state:` line pointing at the new `record-fields-terminal-
     states.json` entry, replacing the implicit free-text progress
     narrative.
3. **`xunit-suite-patterns/README.md`**: add one cross-reference line
   naming `test_items` next to the existing suite-architecture-note
   description, so the mapping is legible from the owning plugin's own
   doc, not only from `test-authoring/README.md`.
4. **`ep-bva-technique/README.md`**: add one cross-reference line naming
   `input_spec` next to the existing EP/BVA description, same reason.
5. **`docs/issue-19/reports/implementation.md`**: phase-2 record,
   written after approval, documenting what actually landed.

No `hooks/*.sh` file changes — see Rationale.

## Out of scope

- New gate scripts enforcing `output_spec` or `environment` presence —
  the spec itself defers `output_spec`'s enforcement (`checked_by:
  TBD`) and marks `environment` non-required; inventing enforcement here
  would exceed both the issue's acceptance bar and the spec's own
  stated maturity.
- `test_id`'s reference-resolution check (real test file must exist,
  no orphan references) — the spec assigns this to `on-the-record/
  hooks/role-spec-reference-guard.sh`, outside this rulebook's tree.
- Any change to `adr-proposal-shape`'s phase-1 six-section shape — the
  spec's fields and loop_state vocabulary are phase-2/record concerns,
  not phase-1 proposal-shape concerns.
- Migrating existing `docs/issue-<n>/reports/test-authoring.md` records
  (issue-1, 7, 10, 13, 16) to the new `loop_state:` vocabulary
  retroactively — those are closed, landed records; only the rulebook's
  forward-looking guidance changes.
- Fixing the record-path mismatch a warrant hunt surfaced on this PR
  (`docs/reports/2026-08-09-hunt-spec-field-alignment.md`): the three
  phase-2 content gates only fire on writes to
  `docs/issue-<n>/reports/test-authoring.md`, but this session (role
  `implementation`, per contract v3's own role-directed path) writes its
  own record to `docs/issue-19/reports/implementation.md`, which none of
  those gates match. Pre-existing role/path mismatch, not introduced by
  this proposal; flagged here rather than silently absorbed into this
  issue's scope.

## How you'll know it worked

- `grep -ri 'test_id\|test_items\|input_spec\|output_spec\|environment' docs/ README.md`
  (and per-plugin `README.md` files) finds every one of the five field
  names.
- `grep -ri loop_state docs/specs/record-fields-terminal-states.json`
  shows exactly the five spec states (`drafting`, `items-undeclared`,
  `landed`, `running`, `test-unreachable`) — no stale or extra state.
- `bash tests/run-all-gate-tests.sh` still passes unchanged (no gate
  script touched by this proposal).
- The phase-2 record states the `output_spec`/`environment` empty-state
  reasoning explicitly, satisfying the issue's empty-state rule.

Sources: `roles/specs/test-authoring.spec.json` (marketplace install,
read directly); `test-authoring/README.md`, `xunit-suite-patterns/
hooks/suite-patterns-gate.sh`, `ep-bva-technique/hooks/technique-
gate.sh`, `traceability-line/hooks/traceability-gate.sh`,
`adr-proposal-shape/hooks/proposal-shape-gate.sh` (this repo, read
directly); `/home/jwjung/tokenmaxxxer-core/core/contract/role-handoff-
contract.md` §2 (override-file mechanism); sibling rulebooks'
`docs/specs/record-fields-terminal-states.json` (api-design-rulebook,
content-design-rulebook, release-engineering-rulebook, under
`~/.tokenmaxxxer/work/`).
