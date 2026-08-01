# issue-10 proposal — test-authoring gate A+ remediation

## What was asked

Issue #10: raise this role's gates from the 2026-08-01 code-audit grade
(B-) to A+ across all axes, fixing four named defect classes — a
`hooks.json` reference to a nonexistent script (base plugin broken), a
kill-switch typo that silently disables enforcement, unreconstructed
`Edit`/`MultiEdit`/`replace_all` handling, and substring-only
"technique-gate" semantic checks — plus mandatory test cases for each and
a README that matches the shipped reality. Precondition: implement
against `tokenmaxxxer-core`'s now-landed gate-house standard
(`core/hooks/lib/gate-lib.sh`/`gate-lib.py`), never re-derive it.

## Survey pointer

`docs/issue-10/reports/test-authoring/survey.md` — confirms core issue
#72 landed, inventories this role's five gates, and maps each named
defect (plus two more the sweep found: hand-rolled path-normalize and
hand-rolled JSON-parse/trap logic that already behave correctly but
duplicate `gate-lib`) to the exact `gate_*` function that replaces it.

## Adopted methodology + required phase-2 components

Migrate all four `Write|Edit|MultiEdit` gates
(`adr-proposal-shape/hooks/proposal-shape-gate.sh`,
`ep-bva-technique/hooks/technique-gate.sh`,
`traceability-line/hooks/traceability-gate.sh`,
`xunit-suite-patterns/hooks/suite-patterns-gate.sh`) plus the base
plugin's `Bash` gate, to source/load `gate-lib.sh`/`gate-lib.py` per
`gate-house-standard.md`'s migration checklist, function-by-function:

1. **Fail-closed trap** — replace each script's hand-rolled `__fc`/`trap`
   pair with `. ".../core/hooks/lib/gate-lib.sh"` then
   `gate_trap_fail_closed`, called as the first statement (before
   `set -uo pipefail`), per the handbook's usage comment.

2. **Kill switch** — replace all four gates' hand-rolled
   `case "$_off_norm" in ...` blocks with
   `gate_kill_switch_active "${<ROLE>_GATE_OFF:-}" || { trap - EXIT; exit 0; }`.
   This is the correctness fix for the three gates currently fail-open on
   an unrecognized value (`technique-gate.sh`, `suite-patterns-gate.sh`,
   `traceability-gate.sh`) and a behavior-preserving cleanup for
   `proposal-shape-gate.sh` (already stays-active on unrecognized, now
   via the canon function instead of divergent hand-rolled logic).

3. **Malformed-JSON deny** — replace each Python payload's
   `try: json.loads(...) except ValueError: deny(...)` +
   `isinstance(ev, dict)` pair with
   `ev = gate_lib.gate_parse_json_or_deny(raw, deny)`, loaded via the
   `importlib`/`GATE_LIB_PY` pattern in the handbook's usage comment.

4. **Path normalization** — replace each gate's ~25-line hand-rolled
   `resolve()`/`_under()` pair with `gate_lib.gate_normalize_path(root,
   path)`; a `None` return (path resolves outside root) becomes the
   existing "not this gate's write surface" early-exit, a non-`None`
   return is the root-relative tail used for the existing `RECORD_RE`/
   `PROPOSAL_RE` match.

5. **`Edit`/`MultiEdit`/`replace_all` reconstruction** — replace each
   gate's inline `new_text = current.replace(o, n, 1)` /
   hand-rolled `MultiEdit` loop with a single
   `new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)`
   call; `ok is False` becomes the existing "cannot determine resulting
   content" deny path. This is the fix for defect 3 (per-edit
   `replace_all` now honored) and adds `NotebookEdit` coverage none of
   the four gates has today.

6. **Semantic checks: substring → structural** — for each gate's own
   domain check, keep the existing keyword vocabularies (they encode
   real domain knowledge — EP/BVA terms, Meszaros fixture terms, the six
   ADR section names, the traceability keyword set) but change the test
   from "substring anywhere in the lower-cased whole document" to a
   heading-scoped or line-scoped match:
   - `proposal-shape-gate.sh`: each of the six required items must be
     found as a markdown heading line (`^#{1,3}\s+`) matching the
     section name, not merely present anywhere in body text — a
     document that mentions "rationale" in passing no longer satisfies
     the "Rationale" section requirement.
   - `technique-gate.sh`: the EP/BVA citation must appear within the
     same paragraph/line as an actual test-case reference (a line
     containing both a technique keyword and a test-identifier-shaped
     token, e.g. a heading, bullet, or `test_`/`Test`-prefixed name) —
     not merely anywhere in the file. Same adjacency rule for the
     mutation-testing-mention escalation relative to the thoroughness
     claim it backs (same paragraph, not same document).
   - `traceability-gate.sh`: already line-scoped (`keyword_present` and
     `ISSUE_REF_RE` both operate correctly per-requirement) — no change
     needed beyond items 1-5 above; kept as an explicit
     deliberately-out-of-scope item below.
   - `suite-patterns-gate.sh`: the smell-list check's `smell.{0,40}\d`/
     named-smell match already requires local adjacency; the pyramid-
     level/pyramid-term and fixture-strategy checks move from
     whole-document `has_any` to same-line-or-adjacent-line pairing
     (pyramid level word and pyramid term within the same bullet/line;
     fixture-strategy phrase as its own line), closing the same
     drop-it-anywhere gap `proposal-shape-gate.sh`/`technique-gate.sh`
     have.

7. **Ghost script (base plugin)** — `test-authoring/hooks/hooks.json`'s
   `Bash`-matched `test-authoring-progress-gate.sh` does not exist and
   has no recorded semantic requirement anywhere in this repo's specs
   (the five real methodology checks all live in the four composing
   plugins already, matched on `Write|Edit|MultiEdit`, not `Bash`).
   Remove the dangling `PreToolUse`/`Bash` hook entry from
   `test-authoring/hooks.json` rather than inventing new
   `Bash`-write-target semantics with no specified requirement behind
   them; `gate_bash_write_targets` stays unadopted per the survey's
   coverage-gap finding (none of the four real gates need it).

8. **Tests** — for each of the four migrated gates, extend its existing
   `tests/*-gate-tests.sh` with the six mandatory case groups
   `run-gate-lib-tests.sh` requires, adapted to that gate's own write
   surface and semantic checks: `Edit` with `replace_all: true` against
   a multiply-occurring string, `MultiEdit` with mixed `replace_all`
   flags, malformed JSON (truncated/non-object/empty), kill-switch set
   to an unrecognized value (must assert **active**, i.e. still denies a
   noncompliant write), absolute-path and `./`-prefixed path parity
   against the same relative-path fixture, and — only where relevant —
   the new structural-check cases (keyword present but not in a heading/
   adjacent line ⇒ still denied). Full suite green at delivery, plus
   `core/hooks/tests/compliance-check.sh` run clean against this
   repo's `hooks/` trees as delivery evidence
   (`gate-house-standard.md` step 4-5).

## Rationale

Every item above traces to `gate-house-standard.md`'s already-approved
canon (core issue #72, landed) rather than a fresh design choice: the
handbook is explicit that a rulebook's own A+ remediation issue's job is
migration to the shared library, not re-deriving equivalent logic
(`docs/handbooks/gate-house-standard.md` §"Per-repo migration
checklist"). Item 6 (structural over substring) is the one piece the
gate-house standard does not itself prescribe — `gate-lib` fixes the
mechanical defect classes (trap, kill-switch, JSON, path, reconstruct)
but not a given gate's own semantic keyword logic — so it is derived
directly from issue #10's own requirement #2 ("시맨틱 검사를
부분문자열에서 섹션/인접성/구조 검사로 상향") applied per-gate against
each gate's existing vocabulary, changing only the match's positional
constraint, not the domain terms themselves (no invented new
methodology).

## Plugin reflection plan

Phase 2 touches exactly the five existing plugins' `hooks/` scripts (no
new plugin, no new matcher) plus each plugin's `tests/` file and
`README.md`, and `test-authoring/hooks/hooks.json` (defect 7) and
`test-authoring/README.md` (drift). No `.claude-plugin/plugin.json`
changes — plugin identity/registration is unaffected, only the gates'
internals and the base plugin's dangling hook entry.

## Deliberately out of scope

- Re-deriving `gate-lib.sh`/`gate-lib.py` logic locally instead of
  sourcing/loading core's copy — forbidden by the issue's own
  precondition.
- Restoring `test-authoring-progress-gate.sh` as a real script with new
  `Bash`-tool semantic checks — no requirement in this repo's specs
  currently calls for a `Bash`-matched check distinct from the four
  `Write|Edit|MultiEdit` gates; removing the dangling reference (item 7)
  resolves the "미존재 스크립트 참조" defect without inventing new scope.
  If a future issue wants `Bash`-tool coverage for this role, it can
  adopt `gate_bash_write_targets` then.
- Adopting `gate_bash_write_targets` for the four existing gates — the
  survey found no coverage gap it would close (item 8 of the survey).
- `traceability-gate.sh`'s own semantic check — already line/reference-
  scoped, not substring theater; only its trap/kill-switch/JSON/path/
  reconstruct internals migrate (items 1-5).
- Auditing or migrating any gate outside this role's five plugins (other
  roles' gates are each role's own A+ remediation issue, per the
  handbook's per-repo checklist — not retroactively fixed here).
- Adding new methodology requirements beyond the five phase-2 components
  and six phase-1 sections already adopted in issue-1/issue-7 — this
  issue raises enforcement rigor of the existing norms, not the norms
  themselves.

Sources: `tokenmaxxxer/tokenmaxxxer-core` `docs/handbooks/gate-house-standard.md`
and `core/hooks/lib/gate-lib.sh`/`gate-lib.py` (commit `22a7cad`, cloned
read this session); `docs/issue-10/reports/test-authoring/survey.md`
(this session); issue #10 body (`gh issue view 10`); this repo's current
`adr-proposal-shape/`, `ep-bva-technique/`, `traceability-line/`,
`xunit-suite-patterns/`, `test-authoring/` trees (cloned read, this
session).
