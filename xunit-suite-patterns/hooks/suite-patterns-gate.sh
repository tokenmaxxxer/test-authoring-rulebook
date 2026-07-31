#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — xunit-suite-patterns plugin,
# gates test-authoring's phase-2 record for the three Meszaros xUnit Test
# Patterns components this plugin owns (issue-1(b) items 1-3): a suite-
# architecture note, a fixture-strategy statement, and a smell list.
#
# Target: docs/issue-<n>/reports/test-authoring.md (any issue number).
#
# Follows pricing/hooks/methodology-gate.sh's has_any(...) keyword-presence
# pattern on the reconstructed resulting content, fail-closed when the
# resulting content cannot be determined.
#
# Kill switch: export XUNIT_SUITE_PATTERNS_GATE_OFF=1
set -uo pipefail

role="xunit-suite-patterns"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

# Off means off: any non-empty value other than the recognized "not off"
# spellings disables the gate; an unrecognized non-empty value still counts
# as off but warns on stderr, per freelunch.sh's off-means-off pattern —
# here a stuck-open methodology gate is the safer failure to avoid, so an
# unrecognized value is not silently treated as "keep the gate on" either;
# it is honored as off, with a warning.
_off_raw="${XUNIT_SUITE_PATTERNS_GATE_OFF:-}"
_off_norm="$(printf '%s' "$_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_off_norm" in
  ""|0|false|no|off) ;;
  *) echo "${role}: XUNIT_SUITE_PATTERNS_GATE_OFF='${_off_raw}' set — gate disabled" >&2; cat >/dev/null 2>&1; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "suite-patterns-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "empty tool-use payload on stdin; cannot evaluate the suite-patterns gate."

_target="$(printf '%s' "$payload" | python3 -c '
import json,sys
try: e=json.loads(sys.stdin.read())
except Exception: sys.exit(0)
ti=e.get("tool_input") if isinstance(e,dict) else None
if isinstance(ti,dict):
    for k in ("file_path","notebook_path"):
        v=ti.get(k)
        if isinstance(v,str) and v: print(v); break
' 2>/dev/null || true)"

_plausible() { [ -n "$1" ] && [ -d "$1" ] && { [ -e "$1/.git" ] || [ -f "$1/docs/specs/role-handoff-contract.md" ]; }; }
_under() {
  [ -z "$2" ] && return 0
  python3 -c '
import os,posixpath,sys
r,t=sys.argv[1],sys.argv[2]
try: rr=posixpath.normpath(os.path.realpath(r).replace("\\","/"))
except Exception: sys.exit(1)
n=t.replace("\\","/"); a=n if posixpath.isabs(n) else posixpath.join(rr,n)
a=posixpath.normpath(a); real=posixpath.normpath(os.path.realpath(a).replace("\\","/"))
sys.exit(0 if (real==rr or real.startswith(rr+"/")) else 1)
' "$1" "$2"
}

root=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && _plausible "$CLAUDE_PROJECT_DIR" && _under "$CLAUDE_PROJECT_DIR" "$_target"; then
  root="$(cd "$CLAUDE_PROJECT_DIR" 2>/dev/null && pwd -P)"
fi
if [ -z "$root" ]; then
  d="$_target"; [ -n "$d" ] || d="$(pwd -P)"; [ -d "$d" ] || d="$(dirname "$d")"
  root="$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || true)"
fi
[ -z "$root" ] && root="$(git -C "$(pwd -P)" rev-parse --show-toplevel 2>/dev/null || true)"
[ -z "$root" ] && deny "no project root could be determined; failing closed (suite-patterns check cannot run)."

SPG_PAYLOAD="$payload" SPG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("xunit-suite-patterns: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("SPG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge suite-pattern fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on suite-patterns.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (suite-patterns).")

    root = posixpath.normpath(os.environ["SPG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-[0-9]+/reports/test-authoring\.md$')

    def resolve(p):
        n = p.replace("\\", "/")
        a = n if posixpath.isabs(n) else posixpath.join(root, n)
        a = posixpath.normpath(a)
        try:
            return posixpath.normpath(os.path.realpath(a).replace("\\", "/"))
        except OSError:
            return a

    path = None
    if tool in ("Write", "Edit", "MultiEdit"):
        p = ti.get("file_path")
        if isinstance(p, str) and p:
            path = p
    if path is None:
        sys.exit(0)

    r = resolve(path)
    if not r.startswith(root + "/"):
        sys.exit(0)
    rel = r[len(root):].lstrip("/")
    if not RECORD_RE.match(rel):
        sys.exit(0)  # not this plugin's write surface

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on suite-patterns." % rel)

    new_text = None
    if tool == "Write":
        c = ti.get("content")
        if isinstance(c, str):
            new_text = c
    elif tool == "Edit":
        o, n = ti.get("old_string"), ti.get("new_string")
        if isinstance(o, str) and isinstance(n, str) and current is not None and o in current:
            new_text = current.replace(o, n, 1)
    elif tool == "MultiEdit":
        edits = ti.get("edits")
        text = current
        if isinstance(edits, list) and text is not None:
            ok = True
            for e in edits:
                if not isinstance(e, dict):
                    ok = False; break
                o, n = e.get("old_string"), e.get("new_string")
                if not isinstance(o, str) or not isinstance(n, str) or o not in text:
                    ok = False; break
                text = text.replace(o, n, 1)
            if ok:
                new_text = text

    if new_text is None:
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

    # 1. Suite architecture note: at least one pyramid-level word AND a
    #    test-level/pyramid term.
    pyramid_level = has_any("unit", "integration", "e2e")
    pyramid_term = has_any("test-level", "test level", "pyramid")
    if not (pyramid_level and pyramid_term):
        missing.append("suite-architecture-note")

    # 2. Fixture strategy: fresh-fixture or shared-fixture, Meszaros' exact
    #    terms.
    if not has_any("fresh fixture", "shared fixture", "fresh-fixture", "shared-fixture"):
        missing.append("fixture-strategy")

    # 3. Smell list: "smell" combined with a digit or a known Meszaros smell
    #    name, OR an explicit "no smells found" escape valve (exited_early-
    #    style), mirroring pricing gate's exited_early pattern.
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
            "the record must name a pyramid-level (unit/integration/e2e) alongside a "
            "test-level/pyramid term, state a fresh-fixture or shared-fixture strategy, "
            "and either name a real smell from the catalog (with a digit or a known "
            "smell name) or explicitly state no smells were found." % ", ".join(missing)
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
