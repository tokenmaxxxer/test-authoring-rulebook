# Record: test-authoring (issue-1, phase 2)

loop_state: landed

## What was done

Reflected the approved proposal
(`docs/issue-1/proposals/test-authoring-methodology-norms.md`) into the
plugin, per its plan (d):

1. `test-authoring/hooks/directive.sh` — extended the existing `PRODUCES`
   heredoc (verbatim otherwise) with two new clauses:
   - `TEST-DESIGN TECHNIQUE: cite EP/BVA at minimum per nontrivial test
     case; name mutation testing only when the record claims suite
     thoroughness`
   - `TRACEABILITY: one line per suite linking it to the issue/
     requirement it covers`
2. `test-authoring/README.md` (new) — documents the six required
   phase-1 proposal sections and the five required phase-2 components,
   as the checkable reference plan item 3 called for.
3. No new gate file added — consistent with issue #63 (warrant-hunter/
   gates stay core-canon-referenced) and issue-2's precedent of not
   reintroducing role-local `record-fields-gate.sh`. The two new PRODUCES
   clauses are enforced advisorily, same mechanism as the three
   pre-existing fields.

## Why

The proposal's rationale (section (c)) ties EP/BVA and traceability to
domain research (EP/BVA as the accessible-middle test-design technique;
traceability as IEEE 829's one transferable principle). This record
reflects that reasoning into the plugin verbatim rather than reinterpret
it, per the phase-2 mandate in issue-1 ("승인된 규범을 이 룰북의
플러그인에 강제로 반영한다").

## Upstream basis

- docs/issue-1/proposals/test-authoring-methodology-norms.md (approved
  phase-1 proposal, plan section (d))
- issue-1 comment, `APPROVE issue-1/test-authoring` (phase-2 gate)
- issue #63 (warrant-hunter/gates stay core-canon-referenced, no local
  copies)

## Open findings

None outstanding. The proposal's own out-of-scope items (hard-gating the
two new PRODUCES clauses; mutation-testing tooling selection) remain
explicitly deferred to a future decision, as the proposal itself states —
not reopened here.
