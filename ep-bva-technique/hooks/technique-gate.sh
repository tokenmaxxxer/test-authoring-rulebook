#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — ep-bva-technique plugin.
#
# Target: docs/issue-<n>/reports/test-authoring.md (this role's phase-2
# record) — one of the three plugins whose gates AND-compose the
# phase-2 deliverable norm (issue-1(b)), per
# docs/issue-7/proposals/methodology-enforcement-machine.md §3.2/§3.3.2.
#
# Requires:
#   1. A test-design-technique citation (EP/BVA family keyword) be present
#      somewhere in the resulting record content.
#   2. If the record's language makes a thoroughness claim (e.g.
#      "comprehensive coverage"), a mutation-testing mention must also be
#      present, or the write is denied (escalation).
#
# Fails closed when the resulting content of a Write/Edit/MultiEdit cannot
# be determined, mirroring pricing/hooks/methodology-gate.sh.
#
# Kill switch: export EP_BVA_TECHNIQUE_GATE_OFF=1 (off-means-off; an
# unrecognized non-empty value disables the gate and logs a warning,
# mirroring freelunch.sh's off-means-off case statement).
set -uo pipefail

role="${CLAUDE_ROLE:-ep-bva-technique}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

_off_raw="${EP_BVA_TECHNIQUE_GATE_OFF:-}"
_off_norm="$(printf '%s' "$_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_off_norm" in
  ""|0|false|no|off) ;;
  1|true|yes|on) exit 0 ;;
  *) echo "${role}: unrecognized EP_BVA_TECHNIQUE_GATE_OFF value '${_off_raw}' — treating as OFF (off-means-off)" >&2; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "technique-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "technique-gate: empty tool-use payload on stdin; cannot evaluate the technique gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (technique check cannot run)."

TG_PAYLOAD="$payload" TG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("ep-bva-technique: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("TG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge technique fields on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on technique gate.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (technique).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
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
        sys.exit(0)  # not the test-authoring phase-2 record — not this gate's business

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on technique gate." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the technique fields can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    missing = []

    # 1. Technique named — EP/BVA family keyword.
    technique_named = has_any(
        "equivalence partitioning", "ep/bva", "boundary value", "ep-bva",
        "boundary case",
    )
    if not technique_named:
        missing.append("technique-named")

    # 2. Thoroughness-claim escalation: if a thoroughness claim is made,
    #    a mutation-testing mention must also be present.
    thoroughness_claim = has_any(
        "thorough", "comprehensive coverage", "fully covers", "exhaustive",
    )
    mutation_mentioned = has_any("mutation test", "mutation testing", "mutant")
    if thoroughness_claim and not mutation_mentioned:
        missing.append("mutation-testing-mention (thoroughness claim made)")

    if missing:
        deny(
            "test-authoring record is missing required element(s): %s. Per "
            "docs/issue-7/proposals/methodology-enforcement-machine.md §3.3.2, every "
            "phase-2 record must cite an EP/BVA test-design technique, and any "
            "thoroughness claim (comprehensive/exhaustive/fully covers/thorough) must "
            "be backed by a mutation-testing mention." % ", ".join(missing)
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
