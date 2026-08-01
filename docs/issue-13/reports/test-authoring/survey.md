# issue-13 phase-1 current-state survey — test-authoring gate A+ final closeout

## Scope

Issue #13 lists four re-audit residual defects against this rulebook's
four `Write|Edit|MultiEdit` gates (`adr-proposal-shape`, `ep-bva-technique`,
`traceability-line`, `xunit-suite-patterns`), to be fixed by applying
core's now-landed gate-house-standard fixes rather than re-deriving them.

## Precondition check (both landed on `tokenmaxxxer-core`/`on-the-record` main)

- `tokenmaxxxer-core` issue #75 (PR #77, commit `52bdc15`): mandates an
  `||`-guarded `gate-lib.sh` source line
  (`. ".../gate-lib.sh" || { echo "<gate>: cannot source gate-lib.sh" >&2; exit 2; }`),
  adds a `compliance-check.sh` rule that FAILs any gate sourcing
  `gate-lib.sh` without an `||` guard on the same line, adds a
  missing-core deny test case to `run-gate-lib-tests.sh`, and ports
  `gate_bash_write_targets` to `gate-lib.py`. `docs/handbooks/gate-house-standard.md`
  carries the transition note this batch is meant to follow.
- `on-the-record` issue #182: `spawn.py` now injects `CLAUDE_PLUGIN_ROOT_CORE`
  at role-session spawn time — confirms the guard's failure branch is
  reachable only in deploy topologies core cannot resolve (the scenario
  the guard exists for), not a routine path.

Both confirmed landed on `main` via `git log`. This role's gates predate
both fixes (last touched by issue-10, before core #75 existed) and were
never revisited — that is the origin of every defect below.

## Defect 1 — unguarded `gate-lib.sh` source (all four gates, common item)

`grep -n 'gate-lib.sh"' <gate>` on each of:

- `adr-proposal-shape/hooks/proposal-shape-gate.sh:28`
- `ep-bva-technique/hooks/technique-gate.sh:34`
- `traceability-line/hooks/traceability-gate.sh:29`
- `xunit-suite-patterns/hooks/suite-patterns-gate.sh:27`

all read `. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"` — no `||` guard. Ran
core's own `core/hooks/tests/compliance-check.sh` (the issue-75-landed
detector) against each plugin's `hooks/` dir directly; all four FAIL:

```
compliance-check: FAIL — adr-proposal-shape/hooks/proposal-shape-gate.sh:
  - sources gate-lib.sh with no || guard on the same line — fail-open when core is unreachable (missing CLAUDE_PLUGIN_ROOT_CORE)
```//identical FAIL for the other three, path substituted

Consequence confirmed by reading `gate-lib.sh`: a failed unguarded source
runs no code, so `gate_kill_switch_active` is undefined afterward — the
following `gate_kill_switch_active ... || { trap - EXIT; exit 0; }` line
reads the resulting 127 as "kill switch off" and **silently allows every
write**, no trap installed either. It also compounds: `GATE_LIB_PY` is
only ever set by a *successful* `gate-lib.sh` source
(`export GATE_LIB_PY="$GATE_LIB_SH_DIR/gate-lib.py"`), so the Python
judge these gates hand off to would itself fail to load with the export
missing — moot here because the shell side already exits 0 first.

## Defect 2 — `hooks.json` matcher / gate-code coverage mismatch (all four, common item)

Each plugin's `hooks/hooks.json` registers its gate only on
`"matcher": "Write|Edit|MultiEdit"`. But each gate's own Python judge
checks `if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):`
(`proposal-shape-gate.sh:76`, `technique-gate.sh:82`,
`traceability-gate.sh:79`, `suite-patterns-gate.sh:75`) — and each
README's "How it works" section advertises
"`Write`/`Edit`/`MultiEdit`/`NotebookEdit` reconstruction" as delivered
behavior (issue-10's stated scope explicitly added NotebookEdit
coverage "none of the four gates has today"). Since Claude Code's
`PreToolUse` hook dispatch is matcher-gated before the script ever runs,
a `NotebookEdit` write to a governed path (e.g.
`docs/issue-<n>/reports/test-authoring.md` via NotebookEdit — unusual
but not impossible for a `.ipynb`-shaped record) never reaches any of
these four scripts at all. The `NotebookEdit` branch in every gate's
Python judge is dead code, and the README's advertised coverage is not
actually wired. This is the literal "matcher-코드 정합" defect named in
the issue.

## Defect 3 — no missing-core test case (all four, common item)

`grep -rl 'missing.core\|CLAUDE_PLUGIN_ROOT_CORE' */tests/*.sh` returns
nothing under any of the four plugins' `tests/` dirs. Core issue #75's
own landed fix (`run-gate-lib-tests.sh` diff, `+43` lines) added exactly
this case — a deny assertion when `CLAUDE_PLUGIN_ROOT_CORE` points
nowhere resolvable — as one of the mandatory case groups. Issue-10's
"six mandatory case groups" list (this repo's own last remediation) predates
that addition and does not include it; none of the four gate test files
picked it up since.

## Defect 4 — README / manifest ghost-name residue

Checked `README.md`, `test-authoring/README.md`, all four plugin
`README.md`s, `.claude-plugin/marketplace.json`, and all five
`.claude-plugin/plugin.json`s for stale references.

- **No live ghost references found.** `test-authoring-progress-gate.sh`
  appears in `test-authoring/README.md`'s "Gate-house standard migration
  (issue-10)" section only in past tense, describing the already-removed
  dangling `hooks.json` entry ("previously registered ... That dangling
  entry is removed") — this is accurate history, not a live pointer, and
  `find . -name hooks.json` confirms no `hooks.json` in this repo
  references it anymore.
- **Manifest is current.** `marketplace.json`'s five `source` paths and
  plugin `name`s match the five directories on disk 1:1; no orphaned or
  renamed entries.
- **No stale role names.** None of the five `plugin.json`s or `README.md`s
  carry an old plugin/role name inconsistent with the current
  `test-authoring` / `adr-proposal-shape` / `ep-bva-technique` /
  `traceability-line` / `xunit-suite-patterns` naming.
- **Gap, not a ghost:** none of the four gate `README.md`s' "How it
  works" sections mention the `||`-guard requirement or a missing-core
  test case (both did not exist in this repo when those READMEs were
  last written) — this is stale-by-omission against defects 1 and 3
  above, addressed together with the code fix rather than as a separate
  ghost-file item, since it is a doc-follows-code update, not a name/file
  removal.

## `has_test_id` / lone-`technique` bullet finding (issue body's "공통 외" item)

The issue body separately flags, outside the four common defects: "공통
외: has_test_id가 아무 불릿에 참(공개된 약점 — 보강), technique 단독
불릿 통과". Searched this repo for `has_test_id`:

```
grep -rn has_test_id .
```

— zero matches anywhere in this repo (gates, tests, docs, handbooks).
This finding does not correspond to any variable, function, or check
name that exists in this rulebook's code. Cross-referenced
`docs/handbooks/gate-tests.md` and `docs/handbooks/gate-house-standard.md`
(the two handbooks this role's gates draw checks from) — neither
defines a `has_test_id` predicate either; it is not a core-canon term
this repo failed to adopt. Left as an open question for the proposal's
deliberately-out-of-scope section rather than guessed at, since acting
on an unverifiable term risks inventing new gate semantics the issue
never actually specified (the same anti-pattern issue-10's proposal
explicitly avoided for `gate_bash_write_targets`).

## Skip record — scout

Skip condition: "spec 자체가 설계 결정의 여지를 남기지 않음." Issue-13's
four common items are each a direct "apply core's landed fix to this
repo's copy" migration (core #75 for defects 1/3, the issue's own
literal wording for defect 2, a doc-follows-code note for defect 4) with
the reference implementation already fully specified and landed in
`tokenmaxxxer-core`. There is no external best-in-class product/pattern
question open here — the only research surface is "what did core commit
for #75," which this survey already read directly from
`tokenmaxxxer-core`'s git history rather than a web sweep. No
scout-brief.md produced.
