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

## 3. REVISION (issue-7 요구 정정, 승인자 FEEDBACK) — plugin-set structure

> 승인자 FEEDBACK (PR #8): "단일 게이트/디렉티브 심화가 아니라
> **플러그인 세트**로 체계화한다: 채택 방법론 각각을 독립 플러그인으로
> (core의 freelunch/scout처럼 — 룰북당 여러 개, freelunch 수준의
> 완성도). 기획서(phase 1) 규범과 산출물(phase 2) 규범도 각각을 플러그인
> 조합으로 풀어낸다 — 어떤 플러그인들이 조합되어 그 규범이 성립하는지가
> 설계의 본체. 각 플러그인 = 자기 완결(디렉티브/게이트/에이전트/테스트
> 포함 가능), marketplace.json 등록, 명확한 단일 방법론 담당. proposal에는
> 플러그인 목록(이름·담당 방법론·구성요소·조합 관계) 필수."

The below supersedes the single `methodology-gate.sh` design from the
prior revision of this proposal. §1's four items (directive deepening /
methodology gate / gate tests / checklist) are still delivered, but as
components distributed **across independently-registered plugins**, one
per adopted methodology from issue-1(a)/(b) — never as one combined gate
file checking every methodology's fields at once.

### 3.1 Plugin list (name · methodology owned · components · composition)

Each plugin below is self-contained (own `hooks/`, own gate script, own
tests, own `.claude-plugin/plugin.json`), registered as its own entry in
`.claude-plugin/marketplace.json` alongside the existing `test-authoring`
role plugin — mirroring how core registers `freelunch` and `scout` as
separate plugins rather than folding both into one. `Sources:`
scout-brief.md, "Must-bes" (plugin self-containment), "Adopt / skip".

| # | Plugin name | Methodology owned | Components |
|---|---|---|---|
| 1 | `adr-proposal-shape` | ADR-style phase-1 proposal shape (issue-1(a)) | `hooks/proposal-shape-gate.sh` (`PreToolUse`, checks the six required section headers + ≥1 `Sources:` line + survey-file-exists order constraint on `docs/issue-<n>/proposals/*.md`); `tests/proposal-shape-gate-tests.sh` |
| 2 | `xunit-suite-patterns` | Meszaros xUnit Test Patterns: test-level classification, fixture strategy, smell catalog (issue-1(b) items 1–3) | `hooks/suite-patterns-gate.sh` (checks suite-architecture-note + fixture-strategy + smell-list presence on `docs/issue-<n>/reports/test-authoring.md`); `checklists/smell-catalog.md` (Meszaros 18-item reference); `tests/suite-patterns-gate-tests.sh` |
| 3 | `ep-bva-technique` | EP/BVA test-design-technique citation, mutation-testing-on-thoroughness-claim rule (issue-1(b) item 4) | `hooks/technique-gate.sh` (checks a technique citation exists per nontrivial test case reference in the record; escalates to requiring a mutation-testing mention only when the record's language claims thoroughness); `tests/technique-gate-tests.sh` |
| 4 | `traceability-line` | One-line requirement↔suite traceability (issue-1(b) item 5, IEEE 829's transferable principle) | `hooks/traceability-gate.sh` (checks one traceability line per suite section, cross-referencing the issue number in the branch name); `tests/traceability-gate-tests.sh` |

Each plugin owns exactly one methodology, so each plugin's gate touches
only the record fields that methodology defines — a suite-patterns
violation and a traceability violation surface as two independent gate
failures, not one combined gate's single pass/fail. `Sources:`
scout-brief.md, "Adopt / skip" (methodology-per-plugin granularity).

### 3.2 Composition: how phase-1 and phase-2 norms are built from the set

- **Phase-1 proposal norm (issue-1(a))** = `adr-proposal-shape` alone.
  One methodology, one plugin; no composition needed.
- **Phase-2 deliverable norm (issue-1(b))** = `xunit-suite-patterns` +
  `ep-bva-technique` + `traceability-line`, composed by all three gates
  firing on the same `PreToolUse` write to
  `docs/issue-<n>/reports/test-authoring.md`. The record is well-formed
  only when all three independently pass — the norm is the conjunction,
  not a fourth combined gate re-checking the same file. This composition
  relation (which plugins, ANDed on which write surface, make up which
  norm) is the design artifact the approver asked for, not implementation
  detail buried in a single gate script.
- The existing `test-authoring` role plugin keeps `directive.sh`'s four
  strings and `hooks.json`, but each string's `PRODUCES`/`HAND_OFF`
  content now *points at* the composing plugins' checklists/gates by name
  instead of inlining the requirements — the role plugin orchestrates
  which methodology-plugins apply; it does not itself encode any single
  methodology's rules.

## 4. Rationale — why plugin-set over single-gate

- **Matches the org's own precedent literally**: `freelunch` and `scout`
  are core's two separate plugins for two separate methodologies
  (parallel-decomposition dispatch vs. pre-generation field scouting);
  neither folds into the other despite both firing on similar lifecycle
  points. A single `methodology-gate.sh` checking five unrelated
  methodologies at once is the shape the org's own precedent already
  rejects. `Sources:` scout-brief.md, "Must-bes", bullet 1.
- **One methodology, one plugin, keeps ownership legible**: when EP/BVA
  citation practice changes independently of the smell-catalog checklist
  (a realistic future edit — the two evolve on different cadences), a
  single combined gate forces touching one file for either change; four
  independent plugins let each evolve, version, and even be
  disabled/enabled independently, which is the actual reason core keeps
  `freelunch` and `scout` separate rather than merged.
- **Existence-check over persisted state (unchanged from prior revision)**:
  the one order constraint this role's methodology states (survey pointer)
  is still a single existence check inside `adr-proposal-shape`'s gate,
  not a separately maintained state machine — no methodology here has an
  actual multi-stage hunt cadence the way `implementation-rulebook`'s
  progress gate does. `Sources:` scout-brief.md, "Adopt / skip".
- **Real-subprocess tests per plugin, not one shared harness**: each
  plugin's `tests/*-gate-tests.sh` is scoped to its own gate's allow/deny
  cases, following `run-gate-tests.sh`'s `run()` helper shape per plugin
  rather than one repo-root file enumerating every methodology's cases —
  consistent with "freelunch 완성도" (each plugin ships its own tests, not
  a shared central one). `Sources:` scout-brief.md, "Must-bes", gate-tests
  bullet.
- **No `agents/` needed**: none of the four methodologies has an
  autonomous cross-session hunt cadence the way `warrant-hunter` does;
  `xunit-suite-patterns` ships a checklist file instead, which is still a
  self-contained plugin component, just not an agent.

## 5. Plugin reflection plan (phase 2, once approved)

Write set (frozen on approval):

- `.claude-plugin/marketplace.json` (edit — register the four new plugin
  entries alongside the existing `test-authoring` entry)
- `adr-proposal-shape/.claude-plugin/plugin.json`,
  `adr-proposal-shape/hooks/proposal-shape-gate.sh`,
  `adr-proposal-shape/tests/proposal-shape-gate-tests.sh` (new)
- `xunit-suite-patterns/.claude-plugin/plugin.json`,
  `xunit-suite-patterns/hooks/suite-patterns-gate.sh`,
  `xunit-suite-patterns/checklists/smell-catalog.md`,
  `xunit-suite-patterns/tests/suite-patterns-gate-tests.sh` (new)
- `ep-bva-technique/.claude-plugin/plugin.json`,
  `ep-bva-technique/hooks/technique-gate.sh`,
  `ep-bva-technique/tests/technique-gate-tests.sh` (new)
- `traceability-line/.claude-plugin/plugin.json`,
  `traceability-line/hooks/traceability-gate.sh`,
  `traceability-line/tests/traceability-gate-tests.sh` (new)
- `test-authoring/hooks/directive.sh` (edit — deepen the four strings to
  reference the composing plugins by name/path, keep
  stub-check.sh-compliant)
- `test-authoring/hooks/hooks.json` (unchanged — each new plugin registers
  its own gate under its own `hooks.json`, not this role's)
- `README.md` (edit — Enforcement section names the plugin set and the
  composition relation from §3.2)
- `docs/issue-7/reports/test-authoring.md` (create — phase-2 record,
  including each plugin's own test run's pass/fail output)

Steps: scaffold each plugin's `.claude-plugin/plugin.json` → write each
gate script scoped to its one methodology's fields → write each plugin's
own gate-tests file and run it, pasting all four pass/fail summaries into
the phase-2 record → write `xunit-suite-patterns`'s smell-catalog
checklist → deepen `test-authoring/hooks/directive.sh`'s four strings to
point at the composing plugins → register all four plugins in
`.claude-plugin/marketplace.json` → run
`core/hooks/tests/stub-check.sh test-authoring/hooks` (canon-referenced,
not vendored) and paste its output, confirming the deepened `directive.sh`
still passes the structural stub check.

## 6. Deliberately out of scope

- `test-authoring-progress-gate.sh` (referenced in `hooks.json`, file
  missing) — pre-existing gap flagged in issue-2's survey, not one of
  issue-7's four items. Not touched here.
- Any change to core canon (`record-fields-gate.sh`, `stub-check.sh`,
  `role-directive.sh`) — this proposal only reads them as reference,
  per the constraint.
- Mutation-testing tooling selection — out of scope since issue-1, not
  reopened.
- Hard-gating the exact keyword list in each plugin's gate (e.g. what
  phrases count as "traceability line present") is a judgment call made in
  phase 2 following `pricing`'s `has_any` precedent; flagged here because a
  keyword-presence check can both false-deny (unusual phrasing) and
  false-allow (phrase present but not meaningfully satisfying the
  component) — the same tradeoff `pricing`'s and core's own gates already
  accept, not a new risk this proposal introduces silently.
- `write_scope` (`['test/**']`) is unchanged; the new plugins' gate/tests/
  checklist files govern this role's proposal/record surfaces, a distinct
  write surface from the test-suite output `write_scope` covers.
- Whether the four new plugins ship in this rulebook's repo or a shared
  location is a phase-2 judgment call following whatever precedent
  `core`'s own multi-plugin layout sets; this proposal assumes same-repo
  (`./adr-proposal-shape`, etc., siblings of `./test-authoring`) since
  no cross-repo plugin-sharing mechanism was found in the scout pass.

## loop_state

proposed
