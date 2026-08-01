#!/usr/bin/env bash
# PreToolUse gate (Write|Edit|MultiEdit) — ep-bva-technique plugin.
#
# Target: docs/issue-<n>/reports/test-authoring.md (this role's phase-2
# record) — one of the three plugins whose gates AND-compose the
# phase-2 deliverable norm (issue-1(b)), per
# docs/issue-7/proposals/methodology-enforcement-machine.md §3.2/§3.3.2.
#
# Requires:
#   1. A test-design-technique citation (EP/BVA family keyword) appearing
#      in the same line/bullet/heading as a test-case-shaped reference —
#      not merely anywhere in the document.
#   2. If the record's language makes a thoroughness claim, a mutation-
#      testing mention must appear in the same paragraph backing that
#      claim, or the write is denied (escalation).
#
# Migrated to the gate-house standard (core issue #72): sources
# core/hooks/lib/gate-lib.sh / loads gate-lib.py for the fail-closed trap,
# kill-switch convention, JSON parse, path normalize and Write/Edit/
# MultiEdit/NotebookEdit reconstruction primitives (issue-10).
#
# Semantic upgrade (issue-10): both checks move from whole-document
# substring presence to line/paragraph-adjacency — a citation or mutation
# mention dropped anywhere in the file (a stray comment, an unrelated
# paragraph, inside a quoted negative example) no longer satisfies either
# requirement.
#
# Kill switch: export EP_BVA_TECHNIQUE_GATE_OFF=1 — only a recognized
# on-spelling (1/true/yes/on, case-insensitive) disables the gate; empty,
# a recognized off-spelling, or any unrecognized value all keep it
# active (this is the correctness fix: the pre-issue-10 version disabled
# on ANY unrecognized value).
CORE_HOOKS_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks"
. "$CORE_HOOKS_ROOT/lib/gate-lib.sh" || { echo "technique-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="ep-bva-technique"

# Drain stdin unconditionally first, so an early kill-switch exit never
# leaves the caller's write end of the pipe blocked/SIGPIPEd.
payload="$(cat 2>/dev/null || true)"

gate_kill_switch_active "${EP_BVA_TECHNIQUE_GATE_OFF:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "technique-gate.sh requires python3, which is not on PATH; denying rather than guessing."

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && gate_deny "$GATE_NAME" "no project root could be determined; failing closed (technique check cannot run)."

TG_PAYLOAD="$payload" TG_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("ep-bva-technique: refused — %s\n" % m); sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    raw = os.environ.get("TG_PAYLOAD", "")
    ev = gate_lib.gate_parse_json_or_deny(raw, deny)

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (technique).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not the test-authoring phase-2 record — not this gate's business

    fs_path = os.path.join(root, rel)
    current = None
    if os.path.isfile(fs_path):
        try:
            with open(fs_path, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on technique gate." % rel)

    new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
    if not ok:
        deny(
            "this write targets %s but the gate cannot determine the resulting content "
            "from the tool input (tool=%r). Write the full document with Write, or use an "
            "Edit/MultiEdit whose old_string matches, so the technique fields can be "
            "checked." % (rel, tool)
        )

    TECHNIQUE_RE = re.compile(
        r'equivalence partitioning|ep/bva|boundary value|ep-bva|boundary case', re.I
    )

    def has_test_id(paragraph):
        if any(re.match(r'^#{1,6}\s', l) or re.match(r'^\s*[-*]\s', l)
               for l in paragraph.splitlines()):
            return True
        return bool(re.search(r'\btest[_a-zA-Z0-9]*\b', paragraph, re.I))

    THOROUGH_RE = re.compile(
        r'thorough|comprehensive coverage|fully covers|exhaustive', re.I
    )
    MUTATION_RE = re.compile(r'mutation test|mutation testing|mutant', re.I)

    # 1. Technique named within the same paragraph as a test-case-shaped
    #    reference (a heading, a bullet, or a test-prefixed token) — a
    #    citation dropped in an unrelated paragraph no longer qualifies.
    paragraphs = re.split(r'\n\s*\n', new_text)
    technique_named = any(
        TECHNIQUE_RE.search(p) and has_test_id(p) for p in paragraphs
    )

    missing = []
    if not technique_named:
        missing.append("technique-named (must share a paragraph/line with a test-case reference — heading, bullet, or test-prefixed token — not merely appear anywhere in the document)")

    # 2. Thoroughness-claim escalation: mutation-testing mention must be
    #    in the same paragraph as the thoroughness claim.
    thorough_paragraphs = [p for p in paragraphs if THOROUGH_RE.search(p)]
    if thorough_paragraphs and not any(MUTATION_RE.search(p) for p in thorough_paragraphs):
        missing.append("mutation-testing-mention (thoroughness claim made without a mutation-testing mention in the same paragraph)")

    if missing:
        deny(
            "test-authoring record is missing required element(s): %s. Per "
            "docs/issue-7/proposals/methodology-enforcement-machine.md §3.3.2, every "
            "phase-2 record must cite an EP/BVA test-design technique adjacent to an "
            "actual test-case reference, and any thoroughness claim (comprehensive/"
            "exhaustive/fully covers/thorough) must be backed by a mutation-testing "
            "mention in the same paragraph." % ", ".join(missing)
        )

    sys.exit(0)
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("technique-gate.sh: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
_fc_rc=$?  # fail-closed-on-internal-error
if [ "$_fc_rc" -ne 0 ] && [ "$_fc_rc" -ne 2 ]; then
  echo "ep-bva-technique: refused — fail-closed: internal error (judge exited $_fc_rc)" >&2
  exit 2
fi
exit "$_fc_rc"
