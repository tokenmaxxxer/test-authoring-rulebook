# issue-16 phase-1 current-state survey — test-authoring A+ certification closeout

## Scope

Issue #16 names exactly one blocking reason for A+ certification of this
role: "README 5·43행 scaffolding 잔재 제거" (remove scaffolding residue
at README.md lines 5 and 43). This follows the issue-13 re-audit
closeout (`docs/issue-13/proposals/gate-a-plus-final-closeout.md`,
merged via PR #15) — that round closed the four gate-script defects
(source guard, matcher/code parity, missing-core test case,
README/manifest residue check) but did not touch the root `README.md`'s
own opening scaffolding language, which is what issue-16 now flags.

## Evidence

`cat -n README.md` (this repo's root file, not a plugin README):

```
1  # test-authoring-rulebook
2
3  Rulebook for the `test-authoring` role (contract v3 role-handoff protocol), split off
4  per `docs/issue-160/proposals/role-taxonomy.md`'s round-4 promotion and
5  generated as skeleton scaffolding by issue-167.
...
43  This is scaffolding, not a finished rulebook: fill in doctrine detail,
44  handoff enforcement, and any role-specific progress gate before treating
45  it as load-bearing.
```

Line 5 (continuing the sentence begun at line 3) states the file was
"generated as skeleton scaffolding by issue-167." Lines 43-45 state
"This is scaffolding, not a finished rulebook: fill in doctrine detail,
handoff enforcement, and any role-specific progress gate before treating
it as load-bearing."

Both are leftover self-description from the repo's initial scaffold
commit. They predate all substantive work since done under issue-7
(methodology-enforcement plugin set), issue-10 (gate A+ remediation /
gate-lib migration), and issue-13 (gate A+ final closeout re-audit) —
none of which updated this framing, because none of them were scoped to
touch the root README's own status language. The rest of the README
(sections describing the plugin set, gate scripts, test harness,
`docs/specs/approvers.md`) is current and accurate; only these two
spots read as an unfinished-scaffold disclaimer that is no longer true
given the landed gate work.

## Requirement 2 applicability check

Issue #16's requirement 2 ("sales만 해당: core #78 랜딩 후 착수") is
scoped explicitly to the `sales` role, not `test-authoring`. Confirmed
by re-reading the issue body: the constraint is prefixed "sales만
해당" (applies to sales only). Not applicable here; no core #78
dependency check needed for this role's phase-1 or phase-2 work.

## Skip record — scout

Skip condition: no external design decision to scout. The blocking
reason is a single, fully-specified textual defect (named line numbers,
named file) inside this repo, not a technology or pattern choice with
alternatives to compare. The fix is "remove/rewrite two spots of stale
self-description," verifiable by direct file read, not requiring any
web or product research. No scout-brief.md produced.
