# Current-state survey — issue-19

Subject: issue-19. Scope: map `roles/specs/test-authoring.spec.json`
(on-the-record marketplace #521-#525 program) onto this rulebook's
existing docs/hooks.

## Spec read

`roles/specs/test-authoring.spec.json` (read from the marketplace
install, `/home/jwjung/.claude/plugins/marketplaces/tokenmaxxxer/roles/specs/test-authoring.spec.json` —
not present under this repo's own tree, since it is on-the-record's
canonical copy, not this rulebook's):

- `required_fields`: `test_id` (ref, required), `test_items` (string,
  required), `input_spec` (string, required), `output_spec` (string,
  required), `environment` (string, **not** required).
- `reference_resolution`: `test_id` must resolve to a real test file/
  case — no orphan references — checked by
  `on-the-record/hooks/role-spec-reference-guard.sh` (lives in
  on-the-record, not this rulebook).
- `recomputation`: `output_spec` is recomputed by re-running `test_id`
  against `input_spec`, never a standalone asserted field. `checked_by:
  TBD` (explicit follow-up, out of scope per issue-521).
- `write_scope`: `docs/issue-<n>/reports/test-authoring.md` — matches
  this rulebook's existing phase-2 record path exactly.
- `loop_state`: progress `[drafting, running]`, terminal `[landed]`,
  refusal `[items-undeclared]`, error `[test-unreachable]`.

## What this rulebook already has

`test-authoring/README.md` defines the phase-2 deliverable as five
required components, enforced by three composing gate plugins (issue-7
plugin-set architecture):

1. Suite architecture note (test-level classification) — no gate plugin
   of its own; described in README only.
2. Fixture strategy — `xunit-suite-patterns` gate (same-line fixture-
   strategy phrase check).
3. Smell list — `xunit-suite-patterns` gate (smell-word + digit/named
   smell adjacency).
4. Test-design-technique reference (EP/BVA at minimum; mutation testing
   on thoroughness claims) — `ep-bva-technique` gate.
5. Traceability line (issue/requirement link) — `traceability-line`
   gate: requires a line with `traces`/`traceability`/`covers issue`/
   `requirement:` co-occurring with `issue-\d+|#\d+`, and that number
   must match the branch's issue number.

Phase-1 proposal shape (six ADR-derived sections + `Sources:` +
survey-exists ordering) is enforced by `adr-proposal-shape`, targeting
`docs/issue-<n>/proposals/*.md`.

Grepped the whole tree for `loop_state`, `test_id`, `test_items`,
`input_spec`, `output_spec`, `environment` outside of `docs/issue-<n>`
report/proposal bodies (which are per-subject narrative output, not
rulebook methodology): **no hits**. `loop_state` is not currently a
recognized vocabulary anywhere in this rulebook's own docs/hooks —
records under `docs/issue-*/reports/test-authoring.md` write free-text
progress narrative, not a constrained `loop_state:` value. None of the
three composing gates check for a `loop_state:` field at all.

## Sibling mechanism found (not yet present here)

Three other rulebooks in this same marketplace family (`api-design-
rulebook`, `content-design-rulebook`, `release-engineering-rulebook`,
found via filesystem search under `~/.tokenmaxxxer/work/`) each carry a
`docs/specs/record-fields-terminal-states.json` — the override file
role-handoff-contract v3 names ("a repo may override a kind's terminal
states via `docs/specs/record-fields-terminal-states.json`, a `{kind:
[states]}` JSON object"). Example (api-design-rulebook):

```json
{
  "coding-record": {
    "progress": ["linting", "reviewing"],
    "terminal": ["landed"],
    "refusal": ["spec-undeclared"],
    "error": ["ruleset-unreachable"]
  }
}
```

This repo has no such file yet (`docs/specs/` currently holds only
`approvers.md`). `test-authoring` is not one of the core contract's
seven sanctioned kinds (`hypothesis`, `product-record`, `build-
proposal`, `coding-record`, `qa-record`, `feasibility-record`, `ux-
design-record`, `review-record`, `verify-record` — grepped role-
handoff-contract.md directly: no `test-authoring` row exists there).
Its record kind and vocabulary are this rulebook's own to define, and
the override-file mechanism is exactly the doctrine-sanctioned home for
declaring it.

## Field-by-field gap read (what proposal will need to decide)

- `test_id` → closest existing concept: `traceability-line`'s issue/
  requirement link line. Gap: the existing gate checks an issue-number
  match, never that the cited identifier resolves to an actual test
  file — that resolution check is `on-the-record`'s own hook
  (`role-spec-reference-guard.sh`), not this rulebook's to duplicate.
- `test_items` → closest existing concept: the suite-architecture note
  (test-level/scope description), currently prose-only, no gate.
- `input_spec` → closest existing concept: `ep-bva-technique`'s EP/BVA
  citation (equivalence partitioning and boundary-value analysis are
  literally input-domain specification techniques).
- `output_spec` → no existing rulebook concept names expected-output
  content directly; closest adjacent is the smell-list/assertion
  content implied by `xunit-suite-patterns`, but nothing currently
  requires stating expected outputs as their own field. The spec's
  `recomputation` rule (re-run `test_id` against `input_spec` to get
  `output_spec`) also has no analog here yet.
- `environment` → no existing rulebook concept; `required: false` in
  the spec, so a documentation-only mention (no new gate) satisfies it.

## Write surfaces this touches (informs the proposal's frozen set)

- `test-authoring/README.md` — phase-2 deliverable section is the
  natural place to name all five spec fields explicitly (this is what
  the issue's grep-based acceptance check reads).
- `docs/specs/record-fields-terminal-states.json` — new file, declares
  the `test-authoring-record` kind's `loop_state` vocabulary to match
  the spec exactly, replacing free-text progress narrative.
- Possibly `xunit-suite-patterns/README.md` and `ep-bva-technique/
  README.md` — cross-reference the specific field names (`test_items`,
  `input_spec`) they already conceptually cover, so the mapping is
  legible in more than one place without duplicating gate logic.

No gate-script (`.sh`) changes appear necessary: the issue's acceptance
checks are grep-based (field names appear in `docs/`/`README.md`) and a
`loop_state` vocabulary match — both are documentation-shape
requirements, not new enforcement logic. This keeps the candidate write
set doc-only, which the proposal will state as its rationale for not
touching any `hooks/*.sh` file.
