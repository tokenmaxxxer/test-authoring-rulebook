---
proposal: docs/proposals/2026-08-09-spec-field-alignment.md
---

# Hunt record — spec-field-alignment

## after-proposal — stance 0: assume the gate just touched is bypassable — find the bypass

Verdict: FINDING — the three phase-2 content gates (xunit-suite-patterns, ep-bva-technique, traceability-line) only match `docs/issue-<n>/reports/test-authoring.md`, but this proposal's phase-2 record write target (per its own front-matter `files:` list and step 5) is `docs/issue-19/reports/implementation.md`, a path none of those gates recognize — so the record they exist to check can be written with none of the required content (suite architecture note, fixture strategy, smell list, EP/BVA technique citation, traceability line) and no gate will object.
Kind: composition
Seed: docs/issue-19/proposals/spec-field-alignment.md (HEAD~1..HEAD, 301 lines, two new docs-only files)
cap_seconds: 180
tier: default
diff_stat_lines: 301
started_at: 2026-08-09T05:51:03+09:00
ended_at: 2026-08-09T05:59:00+09:00

### Reproduce
```
export CLAUDE_PROJECT_DIR=/home/jwjung/.tokenmaxxxer/work/test-authoring-rulebook-issue-19-implementation
cd "$CLAUDE_PROJECT_DIR"
P='{"tool_name":"Write","tool_input":{"file_path":"docs/issue-19/reports/implementation.md","content":"no smells no fixtures no pyramid content here"}}'
echo "$P" | bash xunit-suite-patterns/hooks/suite-patterns-gate.sh; echo "exit=$?"
echo "$P" | bash ep-bva-technique/hooks/technique-gate.sh; echo "exit=$?"
echo "$P" | bash traceability-line/hooks/traceability-gate.sh; echo "exit=$?"
```

### Observed
All three gates exit 0 (silently allow) for a Write to `docs/issue-19/reports/implementation.md` whose content contains none of the fields/terms each gate exists to enforce (no pyramid/test-level pairing, no fixture-strategy line, no smell list, no EP/BVA citation, no issue reference for traceability). Every prior issue in this repo (1, 7, 10, 13, 16) recorded its phase-2 test-authoring content at `docs/issue-<n>/reports/test-authoring.md` — the exact path these gates' `RECORD_RE` matches — but issue-19's proposal instead targets `implementation.md` (matching this session's own `implementation` role/board-gate write scope, confirmed separately: a repo-level `board-gate.sh` actively refuses this session writing to `test-authoring.md`, saying "implementation writes only implementation.md, implementation/** — never a foreign record"). So the role now doing this work is structurally barred from ever writing the one path the content gates check, and the path it is required to use instead is invisible to all three gates.

### Expected
Either the three content gates should also recognize `docs/issue-<n>/reports/implementation.md` (or whatever path board-gate actually authorizes for the acting role) as this record's location, or the proposal/gates should be reconciled so the phase-2 record enforcement isn't silently skippable simply by having a different role write the file under a different, unmatched filename.
