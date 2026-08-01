#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — test-authoring-role-specific,
# owning exactly one methodology: IEEE 829's transferable
# requirement-to-test-case traceability principle (issue-1(b) item 5).
#
# Target: docs/issue-<n>/reports/test-authoring.md (phase-2 record) — this
# role's own write surface per docs/issue-1/proposals/
# test-authoring-methodology-norms.md (b).
#
# Requires at least one traceability line: a line containing one of
# "traces"/"traceability"/"covers issue"/"requirement:" AND matching
# issue-\d+|#\d+. Additionally denies when the traceability line's issue
# number does not match the issue number in the current branch name
# (issue-<n>/...) — a cross-reference mismatch. Already line-scoped
# (not substring theater), so no semantic change from issue-10 — only
# the trap/kill-switch/JSON/path/reconstruct internals migrate below.
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit/NotebookEdit reconstruction primitives (issue-10). This is
# also the correctness fix: the pre-issue-10 version disabled on ANY
# unrecognized kill-switch value.
#
# Kill switch: export TRACEABILITY_LINE_GATE_OFF=1 — only a recognized
# on-spelling (1/true/yes/on, case-insensitive) disables the gate; empty,
# a recognized off-spelling, or any unrecognized value all keep it active.
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "traceability-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="test-authoring"

# Drain stdin unconditionally first, so an early kill-switch exit never
# leaves the caller's write end of the pipe blocked/SIGPIPEd.
payload="$(cat 2>/dev/null || true)"

gate_kill_switch_active "${TRACEABILITY_LINE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "traceability-gate.sh requires python3, which is not on PATH; denying rather than guessing."

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && gate_deny "$GATE_NAME" "no project root could be determined; failing closed (traceability check cannot run)."

_branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

TG_PAYLOAD="$payload" TG_ROOT="$root" TG_BRANCH="$_branch" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("test-authoring: refused — %s\n" % m); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("TG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (traceability).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/test-authoring\.md$')

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
    m = RECORD_RE.match(rel)
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
            deny("%s exists but cannot be read; failing closed on traceability." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the traceability line can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()
    ISSUE_REF_RE = re.compile(r'issue-(\d+)|#(\d+)')

    def has_any(*needles):
        return any(nd in low for nd in needles)

    # 1. Traceability keyword line present.
    keyword_present = has_any("traces", "traceability", "covers issue", "requirement:")

    # 2. A traceability-relevant issue reference exists in the text.
    refs = ISSUE_REF_RE.findall(new_text)
    ref_numbers = [a or b for (a, b) in refs]

    if not (keyword_present and ref_numbers):
        deny(
            "test-authoring phase-2 record %s is missing a traceability line. Per "
            "docs/issue-1/proposals/test-authoring-methodology-norms.md (b) item 5 "
            "(IEEE 829's transferable traceability principle), each suite section "
            "needs a one-line statement — containing one of "
            "\"traces\"/\"traceability\"/\"covers issue\"/\"requirement:\" combined "
            "with an issue-<n> or #<n> reference — tying it back to the requirement "
            "it covers." % rel
        )

    branch = os.environ.get("TG_BRANCH", "")
    bm = re.match(r'^issue-(\d+)/', branch)
    if bm:
        branch_issue = bm.group(1)
        if branch_issue not in ref_numbers:
            deny(
                "test-authoring phase-2 record %s carries a traceability reference "
                "to issue(s) %s, but the current branch (%r) is scoped to issue-%s. "
                "A traceability line must cite the issue it actually traces — a "
                "cross-reference to a different issue number is a mismatch, not a "
                "valid traceability line." % (rel, ", ".join(sorted(set(ref_numbers))), branch, branch_issue)
            )
    # else: branch name doesn't match issue-<n>/... shape — cannot check
    # cross-reference, but keyword+ref presence already passed, so allow.

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("traceability-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "test-authoring: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
