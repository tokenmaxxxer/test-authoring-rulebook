# Proposal: enforce test-authoring's adopted methodology as a hook machine (issue-7)

Phase 1 only — this document, the survey, and the scout brief are the
entire deliverable of this PR. No plugin change ships until a phase-2
Approve lands per contract v3 s19. Follows this role's own adopted phase-1
proposal norm (`docs/issue-1/proposals/test-authoring-methodology-norms.md`
(a)): the six required sections below, every methodology claim carrying a
`Sources:` citation back to `scout-brief.md`.

## 1. What was asked

> 성숙화 라운드(직전 이슈)에서 채택한 도메인 방법론이 directive 한 줄
> (PRODUCES 요약)과 문서로만 남았다. […] 이 룰북은 강제 장치가 없다.
>
> 1. directive 심화 (단계·판단 기준·금지사항, facet별 실행 가능한 수준)
> 2. 방법론 게이트 (produces 필수 요소 기계 검증, 순서 제약은 상태 추적)
> 3. 게이트 테스트 (레포 루트 tests에 통과/거부 케이스)
> 4. 필요 시 agents/체크리스트
>
> 캐논 스크립트는 참조만·복사 금지. 역할 경계·write_scope 불변. 직전
> 성숙화 이슈(issue-1)의 채택 근거 문서를 규범 소스로 사용.

## 2. Current-state survey pointer

`docs/issue-7/reports/test-authoring/survey.md` — confirms: no local gate
exists today, `test-authoring-progress-gate.sh` referenced in `hooks.json`
is a pre-existing missing file (not this issue's scope), `directive.sh` is
already a canon stub (issue-2) whose four strings are one-liners, and
issue-1's phase-2 hard-gating decision was explicitly deferred, not
pre-decided.

## 3. Adopted methodology + required components for phase 2

**Methodology**: mirror the precedent already established elsewhere in the
org for exactly this shape of problem — a role-specific `methodology-gate.sh`
layered on top of (never replacing) core canon's generic
`record-fields-gate.sh`, tested as a real subprocess against throwaway git
fixtures, colocated at repo-root `tests/`. Order constraints are enforced
by reading a sibling on-disk file's actual state at gate time, not by a
separately maintained state machine. `Sources:` scout-brief.md,
"Must-bes" and "Adopt / skip".

**Required components for the phase-2 reflection**:

1. **Directive deepening** — extend `directive.sh`'s four strings
   (`YOU_DECIDE`/`USE_WHEN`/`PRODUCES`/`HAND_OFF`) with per-facet
   stage/criteria/prohibition content, without breaking `stub-check.sh`'s
   structural check (source line + plain assignments + one
   `core_role_directive` call, nothing else — `Sources:` survey.md,
   "Gaps… 1", citing `stub-check.sh` lines 90-100). Procedural depth that
   would bloat the strings past a single-paragraph-per-facet size moves to
   a new checklist file the strings reference by path, not inline.
2. **`test-authoring/hooks/methodology-gate.sh`** (new) — a
   `PreToolUse` (`Write|Edit|MultiEdit`) gate, structurally templated on
   `pricing/hooks/methodology-gate.sh` (`Sources:` scout-brief.md,
   "Adopt / skip"), checking two write surfaces:
   - `docs/issue-<n>/proposals/*.md` authored by this role: the six
     section headers from issue-1's phase-1 norm, at least one `Sources:`
     line, **and** (the order constraint) that
     `docs/issue-<n>/reports/test-authoring/survey.md` exists on disk
     before the write is allowed to land — enforcing "survey pointer" to
     actually point at a written file, not an aspirational one.
   - `docs/issue-<n>/reports/test-authoring.md`: the five produces
     components from issue-1(b) — suite architecture note, fixture
     strategy, smell list, test-design-technique reference, traceability
     line — as keyword-presence checks (`has_any`), the same technique
     `pricing`'s gate already uses and that core's `record-fields-gate.sh`
     already uses for the generic §20 fields.
3. **`tests/methodology-gate-tests.sh`** (new, repo root) — real-subprocess
   allow/deny cases for both write surfaces (proposal missing a section →
   deny; proposal with all six sections but no `survey.md` on disk → deny;
   proposal with all sections and an existing survey file → allow; record
   missing traceability line → deny; complete record → allow; a write
   outside either surface → allow/pass-through), following
   `run-gate-tests.sh`'s `run()` helper shape (`Sources:` scout-brief.md,
   "Must-bes", the gate-tests bullet).
4. **`test-authoring/checklists/phase-2-suite-review.md`** (new) — the
   repeated per-suite procedure issue-7 item 4 asks for: classify test
   level against the pyramid, state fresh-vs-shared fixture choice, walk
   the Meszaros 18-item smell catalog, cite EP/BVA (or mutation testing on
   a thoroughness claim) per nontrivial test case, write the traceability
   line. A checklist, not an `agents/` file — no autonomous multi-turn hunt
   cadence exists for this role the way `warrant-hunter` does for another;
   this is a working document a single session fills in per suite.
5. **`test-authoring/hooks/hooks.json`** (edit) — register the new
   `PreToolUse` `Write|Edit|MultiEdit` entry for `methodology-gate.sh`,
   alongside the existing `SessionStart` and (unmodified, pre-existing gap)
   `Bash` entries.
6. **`README.md`** (edit) — flip the "Enforcement: advisory…" line to
   describe the hard gate, and add a Checklists section pointing at item 4.

## 4. Rationale — why each adopted item follows from the domain research

- **Layer on canon, don't re-implement it**: `record-fields-gate.sh`
  checks generic §20 fields; it structurally cannot know this role's
  produces-shape vocabulary (a generic gate parameterized per-role would
  be a core-repo change, out of this issue's write set, same reasoning
  issue-1 already used for the traceability/test-design-technique fields).
  `Sources:` scout-brief.md, "Must-bes", bullet 1.
- **Existence-check over persisted state**: the only order constraint this
  role's adopted methodology actually states (survey pointer in proposal
  §2) is a single existence check, not a multi-step cadence. Building a
  `state.sh`-equivalent for one boolean is the over-engineering
  `implementation-rulebook` itself only reaches for when a role has an
  actual multi-stage hunt (coding does; test-authoring does not).
  `Sources:` scout-brief.md, "Adopt / skip".
- **Real-subprocess tests at repo-root `tests/`**: this is the literal
  precedent issue-7 names ("implementation-rulebook 수준"); reusing its
  `run()` pattern is not a canon-copy (it is not on
  `canon-manifest.txt`, and outcome-equivalent gate test harnesses already
  exist per-rulebook, not centrally) — no reference-not-vendor conflict.
  `Sources:` scout-brief.md, "Must-bes", gate-tests bullet;
  `docs/handbooks/canon-scripts.md` (scoped to canon *hooks*, not test
  harnesses).
- **Checklist over agents/**: the scouted precedent for `agents/` in this
  org (`warrant-hunter`) is an autonomous cross-session hunt cadence,
  which is now canon-referenced, not role-owned. This role's repeated
  procedure is a single-session review checklist with no hunt/handoff
  shape — a checklist file is the components-that-fit match, not an
  under-build.

## 5. Plugin reflection plan (phase 2, once approved)

Write set (frozen on approval):

- `test-authoring/hooks/directive.sh` (edit — deepen the four strings,
  keep stub-check.sh-compliant)
- `test-authoring/hooks/methodology-gate.sh` (new)
- `test-authoring/hooks/hooks.json` (edit — add `Write|Edit|MultiEdit`
  `PreToolUse` entry)
- `test-authoring/checklists/phase-2-suite-review.md` (new)
- `tests/methodology-gate-tests.sh` (new, repo root)
- `README.md` (edit — Enforcement + Checklists sections)
- `docs/issue-7/reports/test-authoring.md` (create — phase-2 record,
  including the test run's pass/fail output)

Steps: write `methodology-gate.sh` from the pricing template with
test-authoring's own section/field vocabulary → write the checklist →
deepen `directive.sh`'s four strings and point `PRODUCES`/`HAND_OFF` at the
checklist path → register the gate in `hooks.json` → write
`tests/methodology-gate-tests.sh` and run it (`bash tests/
methodology-gate-tests.sh`), pasting its pass/fail summary into the
phase-2 record → run `core/hooks/tests/stub-check.sh test-authoring/hooks`
(canon-referenced, not vendored) and paste its output too, confirming the
deepened `directive.sh` still passes the structural stub check.

## 6. Deliberately out of scope

- `test-authoring-progress-gate.sh` (referenced in `hooks.json`, file
  missing) — pre-existing gap flagged in issue-2's survey, not one of
  issue-7's four items. Not touched here.
- Any change to core canon (`record-fields-gate.sh`, `stub-check.sh`,
  `role-directive.sh`) — this proposal only reads them as reference,
  per the constraint.
- Mutation-testing tooling selection — out of scope since issue-1, not
  reopened.
- Hard-gating the exact keyword list in `methodology-gate.sh` is a
  judgment call (which phrases count as "traceability line present," etc.)
  made in phase 2 following `pricing`'s `has_any` precedent; flagged here
  because a keyword-presence check can both false-deny (unusual phrasing)
  and false-allow (phrase present but not meaningfully satisfying the
  component) — the same tradeoff `pricing`'s and core's own gates already
  accept, not a new risk this proposal introduces silently.
- `write_scope` (`['test/**']`) is unchanged; the new gate/tests/checklist
  files govern this role's own plugin and proposal/record surfaces, a
  distinct write surface from the test-suite output `write_scope` covers.

## loop_state

proposed
