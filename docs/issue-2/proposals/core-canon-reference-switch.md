# Proposal: switch `test-authoring` onto core canon (issue-2)

Phase 1 only — this document, the survey, and the scout brief are the entire
deliverable of this PR. No code changes ship until a phase-2 Approve lands
per contract v3 s19.

## What was asked

> 1. warrant-hunter 복사본(agents/warrant-hunter.md 및 관련 hunt cadence 지시)
>    제거 → core canon 참조로 교체
> 2. trailer-gate.sh / record-fields-gate.sh / handbook-trigger-gate.sh
>    복사본과 그 훅 등록 제거 (core 쪽 등록이 대체)
> 3. directive.sh를 스텁 형식으로 교체 — 역할 고유부는 보존
> 4. 역할별 실차이가 있으면 RECORD_FIELDS_TERMINAL_STATES로 명시적 보존
> 5. core/hooks/tests/stub-check.sh 통과 확인을 record에 기록

## Constraints gathered

- Order constraint from the issue: this switch must land before this repo's
  "룰북 성숙화" phase-2 issue.
- Role-unique content (the `you_decide`/`use_when`/`produces`/`hand_off`
  strings, and this role's own record path) must survive the switch —
  the issue is explicit that only the *shared boilerplate* moves to canon,
  not the role's identity.
- `test-authoring`'s `write_scope` is `['test/**']`, called out in the
  existing `handbook-trigger-gate.sh` comment as "does have a write_scope, so
  the heuristic below matters" — worth naming so phase 2 doesn't quietly drop
  that fact along with the file.

## Plan (phase 2, once approved)

1. Delete `test-authoring/agents/warrant-hunter.md`. No replacement file:
   canon's copy is installed via the `warrant` plugin entry in
   `tokenmaxxxer-core`'s marketplace, which every role plugin installs
   alongside its own (confirmed from `warrant`'s own marketplace
   description: "role rulebooks reference it rather than vendoring a copy").
   Update `README.md`'s Install section to name `warrant` (and `core`,
   `scout`, `terse`, `freelunch`) as companion plugins this rulebook expects
   installed, and drop the `agents/warrant-hunter.md` line from the Layout
   list.
2. Delete `test-authoring/hooks/trailer-gate.sh`,
   `test-authoring/hooks/record-fields-gate.sh`,
   `test-authoring/hooks/handbook-trigger-gate.sh`. Remove their three
   `PreToolUse` entries from `test-authoring/hooks/hooks.json` (the `Write|
   Edit|MultiEdit` matcher's `record-fields-gate.sh` entry, and the `Bash`
   matcher's `handbook-trigger-gate.sh` + `trailer-gate.sh` entries). Leave
   the `Bash` matcher's `test-authoring-progress-gate.sh` entry as-is — it is
   a separate, role-owned progress gate, not one of the three canon files,
   and its "file doesn't exist yet" gap predates this issue (see survey).
   `SessionStart` entry for `directive.sh` is untouched (still role-owned,
   see item 3).
3. Rewrite `test-authoring/hooks/directive.sh` as a structural stub:

   ```sh
   #!/usr/bin/env bash
   . "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"
   core_role_directive \
     "YOU DECIDE: 테스트 코드 자체가 격리성·fixture 전략 면에서 좋은 설계인가" \
     "USE_WHEN: 신규/기존 테스트 스위트를 설계·리뷰할 때" \
     "PRODUCES (required record fields): suite architecture note, fixture strategy, smell list (Meszaros catalog refs)\nWRITE_SCOPE: ['test/**']" \
     "HAND-OFF: 실제 실행 결과 관찰은 → execution-observation"
   ```

   This keeps every one of the current directive's role-unique lines
   (`YOU DECIDE`, `USE_WHEN`, `PRODUCES`, `WRITE_SCOPE`, `HAND-OFF`); the
   `RECORD:` line and the kill-switch/guard/trap boilerplate now come from
   `core_role_directive` itself, so they are not retyped here. The current
   directive's extra `BOUNDARY CASE` paragraph is prose the four-argument
   canon function does not have a slot for; carrying it forward means folding
   it into one of the four strings (shown above, folded into `PRODUCES` next
   to `WRITE_SCOPE`) rather than dropping it — open to the approver's
   preference on which of the four fields it belongs under.
4. Terminal `loop_state` check: this role's directive and hooks carry no
   evidence of a terminal state other than core's default (`landed`) — no
   `RECORD_FIELDS_TERMINAL_STATES` override is proposed. If phase-2 work
   surfaces one (e.g. a proposal-shaped intermediate state this role treats
   as done), add `"RECORD_FIELDS_TERMINAL_STATES": "landed <other-state>"` to
   the relevant `hooks.json` entry's `env`, not as a new gate file.
5. Run `core/hooks/tests/stub-check.sh test-authoring/hooks` (core's copy,
   fetched at build time or vendored per its own "distributed to every
   rulebook the way parse-check.sh already is" note) against the post-switch
   tree and record the pass/fail output in
   `docs/issue-2/reports/implementation.md`, per contract v3 s19's phase-2
   record requirement.

## Deliberately out of scope

- The role-specific `produces`-field check (`suite-architecture-note`,
  `fixture-strategy`, `smell-list`) that today's local
  `record-fields-gate.sh` enforces on `docs/issue-<n>/reports/
  test-authoring.md` writes. Core's canon `record-fields-gate.sh` checks a
  different, generic §20 field set (what-was-done/why/upstream-basis/
  loop_state/open-findings) and has no hook for role-specific `produces`
  fields at all — adopting canon as specified **drops** the produces-field
  enforcement, it does not replace it with an equivalent. This is a real
  behavior change, not a wash. Flagged for the approver rather than silently
  decided:
  - Option A (this proposal's default if not overridden): accept the drop —
    the `produces` fields are still named in `directive.sh`'s `PRODUCES`
    string and in this role's own record template guidance; enforcement
    becomes advisory instead of a hard PreToolUse gate.
  - Option B: file a follow-up core issue proposing a
    `RECORD_FIELDS_PRODUCES` env var (parallel to
    `RECORD_FIELDS_TERMINAL_STATES`) so canon's gate can check role-specific
    produces fields without a per-role file. Not built here — phase 1 is
    proposal-only and this would be a core-repo change, outside this issue's
    write set.
- `test-authoring-progress-gate.sh` (referenced in `hooks.json`, file
  missing). Pre-existing gap, not one of the issue's 5 items.
- Populating `docs/specs/approvers.md`. Needed before phase 2 can open in
  single-account mode, but not part of this issue's scope.

## How you will know it worked

- `test-authoring/agents/` no longer exists (or is empty of
  `warrant-hunter.md`); `test-authoring/hooks/` contains no `trailer-gate.sh`,
  `record-fields-gate.sh`, or `handbook-trigger-gate.sh`.
- `core/hooks/tests/stub-check.sh test-authoring/hooks` exits 0 and its
  output is pasted into `docs/issue-2/reports/implementation.md`.
- `test-authoring/hooks/hooks.json` no longer registers the three removed
  gates; `directive.sh` still prints the same `YOU DECIDE`/`USE_WHEN`/
  `PRODUCES`/`WRITE_SCOPE`/`HAND-OFF` content it does today (content
  preserved, source relocated).

## Write set (phase 2, frozen on approval)

- `test-authoring/agents/warrant-hunter.md` (delete)
- `test-authoring/hooks/trailer-gate.sh` (delete)
- `test-authoring/hooks/record-fields-gate.sh` (delete)
- `test-authoring/hooks/handbook-trigger-gate.sh` (delete)
- `test-authoring/hooks/hooks.json` (edit)
- `test-authoring/hooks/directive.sh` (rewrite)
- `README.md` (edit — Install section, Layout list)
- `docs/issue-2/reports/implementation.md` (create — phase-2 record, incl.
  stub-check.sh output)

## loop_state

proposed
