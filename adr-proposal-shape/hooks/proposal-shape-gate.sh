#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — test-authoring role's
# adr-proposal-shape plugin (issue-7 §3.3, plugin #1 of the plugin set).
#
# Targets: docs/issue-<n>/proposals/*.md — this role's phase-1 proposal
# write surface per docs/issue-1/proposals/test-authoring-methodology-norms.md
# (a). Requires the six ADR-derived required-section headers as markdown
# headings (not merely mentioned in prose), at least one `Sources:` line,
# and — as an independent filesystem order constraint — that
# docs/issue-<n>/reports/test-authoring/survey.md already exists on disk
# for that issue number. Fails closed when the resulting content of a
# write cannot be determined.
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit/NotebookEdit reconstruction primitives, replacing this gate's
# former hand-rolled copies (issue-10). Referenced only, never vendored.
#
# Semantic upgrade (issue-10): each of the six required items must be
# found as a markdown heading line matching the section name, not merely
# present anywhere in the document's prose.
#
# Kill switch: export ADR_PROPOSAL_SHAPE_GATE_OFF=1 — only a recognized
# on-spelling (1/true/yes/on, case-insensitive) disables the gate; empty,
# a recognized off-spelling, or any unrecognized value all keep it active.
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="adr-proposal-shape"

# Drain stdin unconditionally first, so an early kill-switch exit never
# leaves the caller's write end of the pipe blocked/SIGPIPEd.
payload="$(cat 2>/dev/null || true)"

gate_kill_switch_active "${ADR_PROPOSAL_SHAPE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "proposal-shape-gate.sh requires python3, which is not on PATH; denying rather than guessing."

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && gate_deny "$GATE_NAME" "no project root could be determined; failing closed (proposal-shape check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("adr-proposal-shape: refused — %s\n" % m); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("PG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (proposal shape).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$', re.I)

    path = None
    if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        p = ti.get("file_path") or ti.get("notebook_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None:
        sys.exit(0)
    m = PROPOSAL_RE.match(rel)
    if not m:
        sys.exit(0)  # not this gate's write surface
    issue_n = m.group(1)

    fs_path = os.path.join(root, rel)
    current = None
    if os.path.isfile(fs_path):
        try:
            with open(fs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on proposal shape." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the six required sections can be "
            "checked." % (rel, tool)
        )

    lines = new_text.splitlines()

    SECTION_PATTERNS = {
        "what-was-asked": r'what\s+was\s+asked',
        "survey-pointer": r'survey\s+pointer',
        "adopted-methodology": r'adopted\s+methodology',
        "rationale": r'rationale',
        "plugin-reflection-plan": r'plugin\s+reflection\s+plan',
        "deliberately-out-of-scope": r'deliberately[\s-]out[\s-]of[\s-]scope',
    }

    def heading_present(phrase_re):
        pat = re.compile(r'^#{1,3}\s+.*' + phrase_re, re.I)
        return any(pat.match(l) for l in lines)

    missing = [name for name, pat in SECTION_PATTERNS.items() if not heading_present(pat)]

    if "sources:" not in new_text.lower():
        missing.append("sources-citation")

    survey_path = posixpath.join(root, "docs", "issue-%s" % issue_n, "reports", "test-authoring", "survey.md")
    if not os.path.isfile(survey_path):
        missing.append("survey.md-not-found-at-docs/issue-%s/reports/test-authoring/survey.md" % issue_n)

    if missing:
        deny(
            "proposal write to %s is missing required element(s): %s. Per "
            "docs/issue-1/proposals/test-authoring-methodology-norms.md (a), every "
            "phase-1 proposal must carry all six required section headers as markdown "
            "headings (What was asked / Survey pointer / Adopted methodology / "
            "Rationale / Plugin reflection plan / Deliberately out of scope) — a "
            "section name mentioned only in prose does not satisfy the requirement — "
            "at least one `Sources:` citation line, and the issue's survey.md must "
            "already exist on disk before the proposal lands." % (rel, ", ".join(missing))
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("proposal-shape-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "adr-proposal-shape: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
