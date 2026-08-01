#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — xunit-suite-patterns plugin,
# gates test-authoring's phase-2 record for the three Meszaros xUnit Test
# Patterns components this plugin owns (issue-1(b) items 1-3): a suite-
# architecture note, a fixture-strategy statement, and a smell list.
#
# Target: docs/issue-<n>/reports/test-authoring.md (any issue number).
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit/NotebookEdit reconstruction primitives (issue-10).
#
# Semantic upgrade (issue-10): the pyramid-level/pyramid-term check and
# the fixture-strategy check move from whole-document has_any(...) to
# same-line-or-adjacent-line pairing (pyramid level word and pyramid term
# within the same bullet/line; fixture-strategy phrase as its own line).
# The smell-list check already required local adjacency (smell word near
# a digit or named smell) and is unchanged.
#
# Kill switch: export XUNIT_SUITE_PATTERNS_GATE_OFF=1 — only a recognized
# on-spelling (1/true/yes/on, case-insensitive) disables the gate; empty,
# a recognized off-spelling, or any unrecognized value all keep it active
# (this is the correctness fix: the pre-issue-10 version disabled on ANY
# unrecognized value).
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "suite-patterns-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="xunit-suite-patterns"

# Drain stdin unconditionally first, so an early kill-switch exit never
# leaves the caller's write end of the pipe blocked/SIGPIPEd.
payload="$(cat 2>/dev/null || true)"

gate_kill_switch_active "${XUNIT_SUITE_PATTERNS_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "suite-patterns-gate.sh requires python3, which is not on PATH; denying rather than guessing."

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && gate_deny "$GATE_NAME" "no project root could be determined; failing closed (suite-patterns check cannot run)."

SPG_PAYLOAD="$payload" SPG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("xunit-suite-patterns: refused — %s\n" % m); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("SPG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (suite-patterns).")

    root = posixpath.normpath(os.environ["SPG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/test-authoring\.md$')

    path = None
    if tool in ("Write", "Edit", "MultiEdit", "NotebookEdit"):
        p = ti.get("file_path") or ti.get("notebook_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    rel = gate_lib.gate_normalize_path(root, path)
    if rel is None or not RECORD_RE.match(rel):
        sys.exit(0)  # not this plugin's write surface

    fs_path = os.path.join(root, rel)
    current = None
    if os.path.isfile(fs_path):
        try:
            with open(fs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on suite-patterns." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the suite-pattern fields can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    missing = []

    # 1. Suite architecture note: a pyramid-level word AND a test-level/
    #    pyramid term, adjacent — same line/bullet, or within 1 line of
    #    each other.
    PYRAMID_LEVEL_RE = re.compile(r'\b(unit|integration|e2e)\b', re.I)
    PYRAMID_TERM_RE = re.compile(r'test-level|test level|pyramid', re.I)
    lines = new_text.splitlines()
    level_lines = [i for i, l in enumerate(lines) if PYRAMID_LEVEL_RE.search(l)]
    term_lines = [i for i, l in enumerate(lines) if PYRAMID_TERM_RE.search(l)]
    arch_note = any(abs(i - j) <= 1 for i in level_lines for j in term_lines)
    if not arch_note:
        missing.append("suite-architecture-note (pyramid-level word and test-level/pyramid term must appear on the same or an adjacent line)")

    # 2. Fixture strategy: fresh-fixture or shared-fixture, as its own
    #    line (Meszaros' exact terms), not merely present in the document.
    FIXTURE_RE = re.compile(r'fresh[\s-]fixture|shared[\s-]fixture', re.I)

    def fixture_stated_directly(text):
        # "as its own line": the phrase's own clause (bounded by '.'/';'
        # or the line itself) is short — a direct statement, not a
        # fixture-word citation buried deep inside an unrelated sentence.
        for l in text.splitlines():
            for clause in re.split(r'[.;]', l):
                if FIXTURE_RE.search(clause) and len(clause.split()) <= 10:
                    return True
        return False

    if not fixture_stated_directly(new_text):
        missing.append("fixture-strategy (fresh-fixture/shared-fixture phrase must appear on its own line, not buried inside an unrelated sentence)")

    # 3. Smell list: "smell" combined with a digit or a known Meszaros smell
    #    name, OR an explicit "no smells found" escape valve.
    smell_names = (
        "fixture setup", "general fixture", "test code duplication",
        "conditional test logic", "mystery guest", "resource optimism",
        "test run war", "slow tests",
    )
    smell_word = "smell" in low
    smell_named = smell_word and (re.search(r'smell.{0,40}\d', low) or re.search(r'\d.{0,40}smell', low) or any(sn in low for sn in smell_names))
    exited_early = has_any("no smells found", "no smells", "none found")
    if not (smell_named or exited_early):
        missing.append("smell-list")

    if missing:
        deny(
            "test-authoring phase-2 record is missing required xunit-suite-patterns "
            "element(s): %s. Per issue-1(b) items 1-3 (Meszaros xUnit Test Patterns), "
            "the record must name a pyramid-level (unit/integration/e2e) adjacent to a "
            "test-level/pyramid term, state a fresh-fixture or shared-fixture strategy "
            "on its own line, and either name a real smell from the catalog (with a "
            "digit or a known smell name) or explicitly state no smells were found." % ", ".join(missing)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("suite-patterns-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "xunit-suite-patterns: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
