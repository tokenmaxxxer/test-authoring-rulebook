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

### 3.3 REVISION 2 (승인자 FEEDBACK, WEAK 판정) — completeness baseline, concrete heuristics, enumerated tests

> 승인자 FEEDBACK (PR #8, 도메인 전수 심사 WEAK): "플러그인 완결성을
> 기준선으로: README/hooks.json/킬스위치/fail-closed 명세 및 marketplace
> 초안. 게이트 휴리스틱을 구체화(검출 키워드 셋·오탐/미탐 분석)하고
> 게이트별 테스트 케이스 열거. 이 브랜치에 이어서 proposal을 개정하라."

The three subsections below close this gap. Grounded directly in the two
concrete same-org gate implementations read during this revision:
`pricing/hooks/methodology-gate.sh` (fail-closed trap, kill-switch,
`has_any` keyword-presence pattern) and `core`'s `freelunch`/`scout`
plugins (per-plugin `README.md`, `hooks/hooks.json`, `.claude-plugin/
plugin.json` as the completeness baseline the approver is pointing at).
`Sources:` `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh` (whole file); `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/freelunch/{README.md,hooks/hooks.json,hooks/freelunch.sh}`; `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/scout/{README.md,hooks/hooks.json,hooks/directive.sh}`.

#### 3.3.1 Plugin completeness baseline (applies identically to all four plugins)

Every plugin in §3.1 ships, at minimum, the same five files `freelunch`
and `scout` each ship — this is the literal "freelunch 완성도" bar the
approver named:

| File | Requirement |
|---|---|
| `<plugin>/.claude-plugin/plugin.json` | `name`, `description` (states the one methodology owned + `use_when`), `author` — mirrors `test-authoring/.claude-plugin/plugin.json`'s existing shape |
| `<plugin>/README.md` | Following `freelunch/README.md`'s shape: one-paragraph purpose, "How it works" file-by-file listing, and a "Scope of evidence" line citing `scout-brief.md` rather than claiming untested authority |
| `<plugin>/hooks/hooks.json` | Registers this plugin's own gate under `PreToolUse` (`matcher: "Write\|Edit\|MultiEdit"`), scoped to `${CLAUDE_PLUGIN_ROOT}` — never reuses `test-authoring/hooks/hooks.json` |
| `<plugin>/hooks/<name>-gate.sh` | Fail-closed: `trap __fc EXIT` calling a handler that denies (exit 2) on any non-{0,2} exit, exactly `pricing/hooks/methodology-gate.sh` lines 1-3's shape, reproduced verbatim as boilerplate per the scout brief's "Must-bes" bullet 3 |
| `<plugin>/tests/<name>-gate-tests.sh` | Real-subprocess allow/deny cases, enumerated in §3.5 below |

**Kill switch, one per plugin, named after the plugin (not shared)**:
`ADR_PROPOSAL_SHAPE_GATE_OFF`, `XUNIT_SUITE_PATTERNS_GATE_OFF`,
`EP_BVA_TECHNIQUE_GATE_OFF`, `TRACEABILITY_LINE_GATE_OFF`. Each follows
`freelunch.sh`'s off-means-off case statement verbatim (`""|0|false|no|off`
→ not off; any other non-empty value → off; an unrecognized-but-non-empty
value logs a warning to stderr and still treats it as off) — the org's
own documented reason (`freelunch.sh` lines 19-23) is that a
half-typed kill-switch value must not silently keep the gate alive, which
matters more here than convenience, since a stuck-open methodology gate
is invisible until a bad write already lands.

**`marketplace.json` draft** (four new entries, `test-authoring`'s
existing entry unchanged):

```json
{
  "name": "adr-proposal-shape",
  "source": "./adr-proposal-shape",
  "description": "Gates test-authoring's phase-1 proposals against the six required ADR-derived sections (issue-1(a)). use_when: any Write/Edit/MultiEdit to docs/issue-<n>/proposals/*.md under this role."
},
{
  "name": "xunit-suite-patterns",
  "source": "./xunit-suite-patterns",
  "description": "Gates test-authoring's phase-2 record for suite-architecture-note, fixture-strategy, and smell-list presence (issue-1(b) items 1-3, Meszaros). use_when: any write to docs/issue-<n>/reports/test-authoring.md."
},
{
  "name": "ep-bva-technique",
  "source": "./ep-bva-technique",
  "description": "Gates test-authoring's phase-2 record for a test-design-technique citation, escalating to a mutation-testing mention on thoroughness claims (issue-1(b) item 4). use_when: any write to docs/issue-<n>/reports/test-authoring.md."
},
{
  "name": "traceability-line",
  "source": "./traceability-line",
  "description": "Gates test-authoring's phase-2 record for a one-line requirement-to-suite traceability statement per suite section (issue-1(b) item 5). use_when: any write to docs/issue-<n>/reports/test-authoring.md."
}
```

#### 3.3.2 Gate detection heuristics — keyword sets + false-positive/false-negative analysis

Each gate follows `pricing/hooks/methodology-gate.sh`'s `has_any(...)`
substring-presence pattern (lower-cased reconstructed new-text, per
§3.3.1's resulting-content-reconstruction boilerplate). Presence-based
`has_any` checks are used, not absence-based, per §6's existing
keyword-tradeoff note — restated here per-gate instead of as one blanket
disclaimer.

**`adr-proposal-shape` gate** — six required-section headers, checked as
markdown `##`-level heading text (case-insensitive substring on the
reconstructed content, one `has_any` call per required section, all six
required):

| Section | Detection keywords | False-negative risk | False-positive risk |
|---|---|---|---|
| What was asked | `what was asked` | Author uses a synonym heading (`## Ask`, `## Request`) → wrongly denied | Low — phrase is specific enough not to appear incidentally |
| Survey pointer | `survey pointer`, `current-state survey` | Heading text drifts (`## Survey`) → denied | A proposal body mentioning "survey" in prose without it being the actual pointer section still passes if it's a `##` heading — accepted, since the order-constraint check (existence of `survey.md`) is the substantive gate, this is only the section-presence half |
| Adopted methodology | `adopted methodology`, `required components` | Author titles it just `## Methodology` → denied | None material |
| Rationale | `rationale` | None expected — this word is standard | A stray `## Rationale` sub-heading inside another section would false-positive-pass; accepted since it still means the content exists somewhere |
| Plugin reflection plan | `plugin reflection plan` | Author writes `## Reflection Plan` → denied | None material |
| Deliberately out of scope | `deliberately out of scope`, `deliberately-out-of-scope` | Author writes `## Out of scope` alone (no "deliberately") → denied per current keyword set — **flagged as the one heuristic likely to need a follow-up keyword addition in phase 2**, since issue-2's own accepted-precedent proposal uses varying phrasing | None material |

Plus one `Sources:` check (`has_any("sources:")`) applied once across the
whole document — false-negative if every citation instead uses a bare
URL/footnote style with no literal `Sources:` label; false-positive
essentially impossible since the string is distinctive enough not to
appear by accident. And the order constraint: `adr-proposal-shape`'s gate
additionally denies (independent of the six headers) when
`docs/issue-<n>/reports/test-authoring/survey.md` does not exist on disk
at write time, reading the issue number from the target path per the
scout brief's adopted `coding-progress-gate.sh` pattern — this is a
filesystem-existence check, not a keyword check, so it carries no
false-positive/negative profile of its own.

**`xunit-suite-patterns` gate** — three required components on
`docs/issue-<n>/reports/test-authoring.md`:

| Component | Detection keywords | False-negative risk | False-positive risk |
|---|---|---|---|
| Suite architecture note | `unit`, `integration`, `e2e` (any one, since a real note names at least one pyramid level) combined with `test-level`, `test level`, `pyramid` | A suite note that only ever says "component test" without naming pyramid vocabulary → denied | A record that mentions "e2e" once in an unrelated sentence (e.g. referencing another role's e2e suite) still passes; accepted since it's a presence check, not a semantic one |
| Fixture strategy | `fresh fixture`, `shared fixture`, `fresh-fixture`, `shared-fixture` | An author who states the choice without Meszaros' exact terms (e.g. "each test gets its own setup") → denied | None material — phrase is specific |
| Smell list | `smell` combined with a digit or a known Meszaros smell name (`fixture setup`, `general fixture`, `test code duplication`, `conditional test logic`, `mystery guest`, `resource optimism`, `test run war`, `slow tests`) | A suite with genuinely zero smells found and a record saying only "no smells" → **false-deny**; the gate must also accept an explicit `has_any("no smells", "no smells found", "none found")` exit, mirroring pricing gate's `exited_early` pattern | Mentioning "smell" once in prose without a real catalog reference still passes |

**`ep-bva-technique` gate** — technique citation, escalating on
thoroughness claims:

| Check | Detection keywords | False-negative risk | False-positive risk |
|---|---|---|---|
| Technique named | `equivalence partitioning`, `ep/bva`, `boundary value`, `ep-bva` | Author writes only "boundary case" without "value analysis" → denied under strict match; **adopt `boundary case` as an additional keyword** to close this at phase 2 | None material |
| Thoroughness-claim escalation trigger | `thorough`, `comprehensive coverage`, `fully covers`, `exhaustive` | A record making a thoroughness claim in different words (e.g. "we're confident this catches everything") does not trigger escalation → **the gate under-escalates rather than over-escalates by design**, since a missed escalation only means EP/BVA-level rigor is accepted where mutation testing would have been asked for — a false-negative on the stricter check, not a false-deny of the record | A record casually using "thorough" in an unrelated sentence (e.g. "a thorough survey") wrongly triggers the mutation-testing requirement; accepted as the safer failure direction (asks for more evidence, not less) |
| Mutation-testing mention (only checked when escalation triggers) | `mutation test`, `mutation testing`, `mutant` | N/A once triggered — if absent, correctly denied | N/A |

**`traceability-line` gate** — one line per suite section tying back to
the issue:

| Check | Detection keywords | False-negative risk | False-positive risk |
|---|---|---|---|
| Traceability line present per suite section | `traces`, `traceability`, `covers issue`, `requirement:` combined with a `#<digit>` or `issue-<digit>` pattern (regex `issue-\d+|#\d+`) | An author who links to the issue via a bare URL with no traceability keyword → denied; accepted, since a bare link doesn't state the *relationship*, which is the actual required content | A line citing an unrelated issue number in passing (e.g. "similar to issue-3's approach") could false-positive-pass if it also contains "traces"; low real-world likelihood since both terms co-occurring is itself close to the intended usage |

Every "false-negative risk" entry above where a same-meaning phrasing
variant is a known, likely occurrence is flagged as a phase-2 keyword-set
follow-up rather than silently shipped — consistent with §6's existing
disclosure that keyword-presence checks trade false-deny against
false-allow and that tradeoff is accepted, not hidden. `Sources:`
`pricing/hooks/methodology-gate.sh` lines 161-207 (the `has_any` pattern
and its `exited_early`-style escape valve, adapted here per-gate).

#### 3.3.3 Gate test cases (per plugin, real-subprocess allow/deny, per `run-gate-tests.sh`'s pattern)

Each `<plugin>/tests/<name>-gate-tests.sh` runs the gate as a real bash
subprocess in a throwaway git-init'd fixture, piping a JSON PreToolUse
payload on stdin, asserting exit 0 (allow) or 2 (deny):

**`adr-proposal-shape-gate-tests.sh`**
1. ALLOW — `Write` to `docs/issue-9/proposals/foo.md` with all six
   section headers, a `Sources:` line, and `docs/issue-9/reports/
   test-authoring/survey.md` present on disk.
2. DENY — same content, but `survey.md` absent (order constraint).
3. DENY — all six headers present, `survey.md` present, but no
   `Sources:` line anywhere.
4. DENY — five of six headers present (missing "Deliberately out of
   scope").
5. ALLOW — `Write` to a path outside `docs/issue-<n>/proposals/*.md`
   (e.g. `README.md`) — gate is a no-op regardless of content.
6. DENY — `Edit` whose `old_string` does not match current file content
   (resulting content indeterminate → fail-closed per §3.3.1).
7. ALLOW — `ADR_PROPOSAL_SHAPE_GATE_OFF=1` set, content missing all six
   headers (kill switch honored).
8. DENY — `ADR_PROPOSAL_SHAPE_GATE_OFF=banana` (unrecognized non-empty
   value; case 4's content) — off-means-off: a garbled kill-switch value
   must not accidentally disable the gate.

**`suite-patterns-gate-tests.sh`**
1. ALLOW — record with a pyramid-level word, `fresh fixture` (or
   `shared fixture`), and a named Meszaros smell.
2. ALLOW — record explicitly stating `"no smells found"` (smell-exit
   valve).
3. DENY — record missing fixture-strategy language entirely.
4. DENY — record with a smell list but no pyramid-level word and no
   `test-level`/`pyramid` term.
5. ALLOW — write to an unrelated path — no-op.
6. ALLOW — kill switch set, content missing all three components.

**`technique-gate-tests.sh`**
1. ALLOW — record citing `EP/BVA` per nontrivial test case, no
   thoroughness claim present.
2. DENY — record with test cases but zero technique citation.
3. DENY — record claiming `"comprehensive coverage"` with no mutation-
   testing mention (escalation triggered, not satisfied).
4. ALLOW — record claiming `"comprehensive coverage"` AND mentioning
   `mutation testing` (escalation satisfied).
5. ALLOW — kill switch set, record with zero citations.

**`traceability-gate-tests.sh`**
1. ALLOW — suite section with a line matching `traces issue-9` (issue
   number cross-referenced against the branch name).
2. DENY — suite section with no traceability-keyword line at all.
3. DENY — traceability line present but referencing a different issue
   number than the branch's (`issue-3` on branch `issue-9/test-authoring`)
   — cross-reference mismatch.
4. ALLOW — kill switch set, no traceability line present.

All four test files aggregate a pass/fail count using
`run-gate-tests.sh`'s `run()` helper shape (scout brief, "Must-bes",
gate-tests bullet) and their combined output is pasted into the phase-2
record per §5's steps.

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
  entries per §3.3.1's draft, alongside the existing `test-authoring`
  entry)
- `adr-proposal-shape/.claude-plugin/plugin.json`, `adr-proposal-shape/
  README.md`, `adr-proposal-shape/hooks/hooks.json`,
  `adr-proposal-shape/hooks/proposal-shape-gate.sh`,
  `adr-proposal-shape/tests/proposal-shape-gate-tests.sh` (new, 8 cases
  per §3.3.3)
- `xunit-suite-patterns/.claude-plugin/plugin.json`, `xunit-suite-patterns/
  README.md`, `xunit-suite-patterns/hooks/hooks.json`,
  `xunit-suite-patterns/hooks/suite-patterns-gate.sh`,
  `xunit-suite-patterns/checklists/smell-catalog.md`,
  `xunit-suite-patterns/tests/suite-patterns-gate-tests.sh` (new, 6 cases
  per §3.3.3)
- `ep-bva-technique/.claude-plugin/plugin.json`, `ep-bva-technique/
  README.md`, `ep-bva-technique/hooks/hooks.json`,
  `ep-bva-technique/hooks/technique-gate.sh`,
  `ep-bva-technique/tests/technique-gate-tests.sh` (new, 5 cases per
  §3.3.3)
- `traceability-line/.claude-plugin/plugin.json`, `traceability-line/
  README.md`, `traceability-line/hooks/hooks.json`,
  `traceability-line/hooks/traceability-gate.sh`,
  `traceability-line/tests/traceability-gate-tests.sh` (new, 4 cases per
  §3.3.3)
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
