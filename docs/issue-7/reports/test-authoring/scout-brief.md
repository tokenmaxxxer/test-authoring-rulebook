# Scout brief (issue-7, test-authoring)

Mode: batched-sequential (single session, no parallel subagent/tool fan-out
available for local-filesystem reads in this turn — reads were run one at a
time against sibling rulebook checkouts already present on disk). Stated
explicitly per the scout-directive's fallback-disclosure requirement.
Stages used: 1 (sweep only — the four sibling artifacts below were read in
one continuous pass and converged immediately, so no separate deepening
round changed any build decision; judge point 1 = judge point 2 = stop).

Angle covered: **by-comparable-system** — this is plugin-engineering work,
not a product-facing methodology question, so the relevant "field" is
sibling role rulebooks in the same `tokenmaxxxer` org that have already
built a hook-machine of the kind issue-7 asks for, rather than external web
sources.

## Must-bes (what every comparable gate does)

- A role-specific gate is layered **on top of**, never instead of, core
  canon's generic record-fields-gate — it targets the role's own
  proposal/record write surfaces by filename pattern and checks
  role-specific content the generic gate cannot know about.
  Sources: `/home/jwjung/tokenmaxxxer/rulebooks/pricing-rulebook/pricing/hooks/methodology-gate.sh` (header comment, lines 4-6); `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/record-fields-gate.sh`.
- Fail-closed on internal error, with an explicit kill-switch env var and a
  `trap` at the top of the file — every gate in the org follows this exact
  shape.
  Sources: `.../pricing-rulebook/pricing/hooks/methodology-gate.sh` (lines 1-3, 25-28); `.../tokenmaxxxer-core/core/hooks/record-fields-gate.sh` (lines 1-3, 37-40).
- Root resolution and Write/Edit/MultiEdit resulting-content reconstruction
  is copy-identical boilerplate across every gate examined (the
  `_plausible`/`_under`/`resolve()`/new_text-from-tool_input block) —
  reused verbatim as a pattern, not a canon file, since it isn't on
  `core/hooks/tests/canon-manifest.txt`.
  Sources: both gate files above, lines ~30-70 and ~95-175 respectively (near-identical).
- Order/sequence constraints are enforced by reading a **sibling record
  file's actual on-disk state** at the moment of the gate-relevant write —
  not by a separately maintained state file — when the constraint is
  "does X exist/say Y", not "how many times has X happened".
  Sources: `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/coding/hooks/coding-progress-gate.sh` (reads `docs/issue-<n>/reports/verify.md` before allowing coding's own commit).
- Gate tests run each gate as a **real subprocess** against a throwaway
  git-init'd fixture directory, piping the JSON PreToolUse payload on
  stdin and asserting exit code 0=allow / 2=deny; one small `run()`/named
  helper per gate, aggregated pass/fail count, colocated at repo-root
  `tests/`.
  Sources: `/home/jwjung/tokenmaxxxer/rulebooks/implementation-rulebook/tests/run-gate-tests.sh` (entire file, esp. lines 1-17, 47-67).
- Canon files are reference-only; a mechanical detector
  (`stub-check.sh`) fails a rulebook that reintroduces a local copy of a
  promoted canon filename, and separately fails a `directive.sh` that
  isn't the four-line stub shape (source + assignments + one call, nothing
  else).
  Sources: `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core/hooks/tests/stub-check.sh` (lines 40-108); `/tmp/claude-1000/core-canon2/docs/handbooks/canon-scripts.md`.

## Performance axes the strong examples compete on

1. **Layering discipline** — pricing's gate never re-checks what core's
   generic gate already covers (no duplicate §20 field checks); it only
   adds role-specific elements.
2. **Fail-closed correctness** — every example treats "cannot determine
   resulting content" and "internal error" as denials, not silent passes.
3. **Testability** — implementation-rulebook's tests exercise gates as
   black-box subprocesses (real bash, real git, real stdin), not by
   importing internals — this is what makes `tests/run-gate-tests.sh`
   trustworthy as a merge gate itself.

## Adopt / skip

- **Adopt**: pricing's `methodology-gate.sh` structure (root resolution +
  resulting-content reconstruction + keyword-presence checks via
  `has_any`) as the direct template for a new `test-authoring/hooks/
  methodology-gate.sh`.
- **Adopt**: implementation-rulebook's `coding-progress-gate.sh` pattern of
  reading a sibling on-disk file's state, applied narrowly to check that
  `docs/issue-<n>/reports/test-authoring/survey.md` exists before a
  proposal write is allowed to finalize — the concrete order constraint
  issue-7 asks about for this role (survey → proposal), rather than
  building a general persisted-state machine (`state.sh`/`hunt-guard.sh`)
  this role's methodology doesn't actually need (no multi-step hunt cadence
  exists for test-authoring the way it does for coding).
- **Skip**: `state.sh`/`hunt-state.sh`-style persisted JSON state. Overkill
  for a single existence check; adds a new failure mode (stale/corrupt
  state file) the simpler filesystem-existence check doesn't have.
- **Skip**: mutation-testing tooling selection — issue-1 already scoped
  this out of the methodology norms themselves; nothing in issue-7 reopens
  it.

## Gap line

The field's must-be is "role gate layered on canon, tested as real
subprocesses, order constraints read off sibling files, canon
reference-only." Today's test-authoring plugin meets **none** of these —
it has zero local gates and zero tests. The gap issue-7 closes is the
entire enforcement layer, not a partial one; this is why the proposal below
adds one new gate file, one new test file, and one checklist, rather than
patching an existing gate.

Stages/mode: 1 stage, batched-sequential fallback (no parallel dispatch
used for this local-file sweep).
