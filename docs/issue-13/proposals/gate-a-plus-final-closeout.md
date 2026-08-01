# issue-13 proposal — test-authoring gate A+ final closeout

## What was asked

Issue #13: close out the 2026-08-01 re-audit's remaining defects against
this role's four `Write|Edit|MultiEdit` gates so the rulebook clears
gate A+ finally — applying `tokenmaxxxer-core` issue #75's now-landed
fixes (source-guard mandate, `gate_bash_write_targets` py parity) and
`on-the-record` issue #182's `CLAUDE_PLUGIN_ROOT_CORE` spawn injection as
the reference implementation, never re-deriving equivalent logic.
Required: matcher/code coverage parity, a missing-core test case per
gate, full-suite green including that case, a clean
`compliance-check.sh` record, and README/manifest with zero
old-role-name or ghost-file residue.

## Survey pointer

`docs/issue-13/reports/test-authoring/survey.md` — confirms both
preconditions landed on `main`, and pins the four common defects with
direct evidence: `compliance-check.sh` FAIL output for all four gates
(unguarded source), a matcher/code diff (`hooks.json`'s
`Write|Edit|MultiEdit` vs. each gate's own `NotebookEdit`-inclusive
Python branch), an empty grep for any missing-core test case, and a
README/manifest sweep that found no live ghost references (the one
`test-authoring-progress-gate.sh` mention left in
`test-authoring/README.md` is accurate past-tense history of its already
-landed issue-10 removal, not a residual pointer). The survey also
traces the issue body's separate `has_test_id`/"technique 단독 불릿"
finding to zero matches anywhere in this repo or its handbooks, and
proposes leaving that specific term unaddressed here (see Deliberately
out of scope).

## Adopted methodology + required phase-2 components

Four gate-scripts to touch — `adr-proposal-shape/hooks/proposal-shape-gate.sh`,
`ep-bva-technique/hooks/technique-gate.sh`,
`traceability-line/hooks/traceability-gate.sh`,
`xunit-suite-patterns/hooks/suite-patterns-gate.sh` — plus each plugin's
`hooks/hooks.json`, `tests/*-gate-tests.sh`, and `README.md`:

1. **Source guard (defect 1)** — replace each gate's
   `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` with core #75's landed form,
   substituting each gate's own name for `<gate-name>`:
   `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }`
   — copied verbatim from `gate-lib.sh`'s own updated usage comment and
   from core's landed `record-fields-gate.sh`/6-other-core-gate diffs,
   not re-derived. This closes the fail-open path
   (`gate_kill_switch_active` reading a 127-from-undefined-function as
   "off") and matches the exact guard shape `compliance-check.sh`'s new
   rule checks for (`gate-lib\.sh"[[:space:]]*\|\|`).

2. **Matcher/code parity (defect 2)** — extend each of the four plugins'
   `hooks/hooks.json` `PreToolUse` matcher from `"Write|Edit|MultiEdit"`
   to `"Write|Edit|MultiEdit|NotebookEdit"`. Direction: widen the
   matcher to the code, not narrow the code to the matcher — each gate's
   Python judge already branches on `NotebookEdit` correctly (via
   `gate_lib.gate_reconstruct_write`, which has real `NotebookEdit`
   handling per the gate-house standard), and every plugin's `README.md`
   already advertises this coverage as delivered (issue-10's stated
   scope). Removing the dead branch instead would silently roll back
   issue-10's own advertised NotebookEdit coverage without an issue
   asking for that; widening the matcher is the fix that makes the
   already-shipped code path reachable, matching what was actually
   promised.

3. **Missing-core test case (defect 3)** — add one case per plugin's
   `tests/*-gate-tests.sh`, mirroring core issue #75's own
   `run-gate-lib-tests.sh` missing-core case: invoke the gate with
   `CLAUDE_PLUGIN_ROOT_CORE` set to a nonexistent path (and unset, with
   the script relocated so its relative fallback also fails to resolve),
   assert exit code 2 (deny) and a stderr message identifying the
   sourcing failure — never exit 0. This is the direct regression guard
   for defect 1's fix: without it, a future edit could silently drop the
   `||` guard again and no test would catch it.

4. **Full-suite + compliance-check green (issue requirement 3)** — after
   1-3, run `bash tests/run-all-gate-tests.sh` (must stay green, case
   count grows by exactly 4 — one missing-core case per plugin) and
   `tokenmaxxxer-core`'s `core/hooks/tests/compliance-check.sh` against
   all four plugins' `hooks/` dirs (must flip from the FAIL evidenced in
   the survey to `compliance-check: ok` for all four, `overall rc=0`),
   and record both outputs verbatim in the phase-2 record as delivery
   evidence, matching the shape issue-10's own record used.

5. **README/manifest doc-follows-code update (defect 4)** — no
   deletions needed (survey found no live ghost references), but each of
   the four plugin `README.md`'s "How it works" section gets one line
   added noting the `||`-guarded source and the missing-core deny case,
   so the doc stops being stale-by-omission against items 1 and 3 once
   those land. `test-authoring/README.md`'s existing past-tense
   `test-authoring-progress-gate.sh` history paragraph is left as-is —
   confirmed accurate, not residue. `marketplace.json` and all five
   `plugin.json`s are confirmed already 1:1 with disk; no manifest edit
   required, recorded as a no-op finding rather than skipped silently.

## Rationale

Items 1, 3, and part of 4 trace directly to `tokenmaxxxer-core` issue
#75's landed fix (commit `52bdc15`) — the gate-house standard's own
canon, applied here rather than re-derived, per the same "migration, not
re-derivation" principle issue-10's proposal already established for
this rulebook. Item 2 traces directly to issue-13's own wording ("hooks.json
matcher와 코드의 도구 커버리지 완전 정합") and to issue-10's own stated
intent (NotebookEdit coverage was an explicit, not incidental, scope
item) — widening the matcher is the change that fulfills what issue-10
already promised rather than reopening that decision. Item 4's
no-deletion finding is evidence-based (the survey's grep found nothing
live to remove), not an assumption that nothing was needed — the
`||`-guard/missing-core doc lines are added because those two facts
change under items 1/3, not because a ghost was found.

## Plugin reflection plan

Touches exactly the same four existing plugins issue-10 touched
(`adr-proposal-shape`, `ep-bva-technique`, `traceability-line`,
`xunit-suite-patterns`) — their `hooks/*.sh`, `hooks/hooks.json`,
`tests/*.sh`, `README.md` — plus `docs/issue-13/reports/test-authoring.md`
for phase-2 record. No new plugin, no `.claude-plugin/plugin.json`
change (manifest confirmed already correct), no change to
`test-authoring/` base plugin (its own `hooks.json`/`README.md` carry no
defect this issue names).

## Deliberately out of scope

- **`has_test_id` / "technique 단독 불릿 통과" finding** — the survey
  found zero matches for `has_test_id` anywhere in this repo's code,
  tests, or handbooks, and it does not correspond to any existing
  predicate name. Acting on it now would mean inventing new gate
  semantics the issue never actually specified a form for — the same
  trap issue-10's proposal explicitly declined for `gate_bash_write_targets`
  ("무단 벤더링·재정의 없이"). Recommend a clarifying comment on
  issue-13 (which specific bullet/gate is meant, and what "true"/"pass"
  means concretely) before this item gets a phase-1 proposal of its own;
  not silently dropped, but not guessed at either.
- **`gate_bash_write_targets` adoption** — still unadopted here per
  issue-10's own standing finding: none of the four real gates write-scan
  `Bash` commands (their surfaces are markdown paths, not shell targets).
  Core #75's py-parity port doesn't change that scoping; noted only so
  the closeout doesn't read as having silently reopened it.
- **`test-authoring` base plugin** — has no `Write|Edit|MultiEdit` gate
  and its `hooks.json`/`README.md` carry no defect named in issue-13 or
  found in the survey; left untouched.
- **Core-repo changes** — none; issue #75 and on-the-record #182 are
  both already landed and merely referenced/applied here, per the
  issue's own "선행 조건은 이미 랜딩됨" framing.

Sources: `tokenmaxxxer-core` commit `52bdc15` (issue #75, PR #77) and its
`docs/handbooks/gate-house-standard.md` transition-note diff; `on-the-record`
issue #182; this repo's `docs/issue-10/proposals/gate-a-plus-remediation.md`
and `docs/issue-10/reports/test-authoring.md` (precedent for record shape
and compliance-check evidence format); `docs/issue-13/reports/test-authoring/survey.md`.
