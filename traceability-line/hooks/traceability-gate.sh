#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
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
# (issue-<n>/...) — a cross-reference mismatch. Fails closed when the
# resulting content cannot be determined, mirroring
# pricing/hooks/methodology-gate.sh's fail-closed pattern.
#
# Kill switch: export TRACEABILITY_LINE_GATE_OFF=1 (off-means-off per
# freelunch.sh lines ~17-30: only ""|0|false|no|off count as not-off; any
# other non-empty value disables the gate; an unrecognized non-empty
# value still disables it, with a warning on stderr).
set -uo pipefail

role="${CLAUDE_ROLE:-test-authoring}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

# Drain stdin unconditionally first, so an early kill-switch exit never
# leaves the caller's write end of the pipe blocked/SIGPIPEd.
payload="$(cat 2>/dev/null || true)"

_tlg_off_raw="${TRACEABILITY_LINE_GATE_OFF:-}"
_tlg_off_norm="$(printf '%s' "$_tlg_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_tlg_off_norm" in
  ""|0|false|no|off) ;;
  *) echo "traceability-line: TRACEABILITY_LINE_GATE_OFF='${_tlg_off_raw}' — gate disabled" >&2; exit 0 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "traceability-gate.sh requires python3, which is not on PATH; denying rather than guessing."

[ -n "$payload" ] || deny "traceability-gate: empty tool-use payload on stdin; cannot evaluate the traceability gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (traceability check cannot run)."

_branch="$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

TG_PAYLOAD="$payload" TG_ROOT="$root" TG_BRANCH="$_branch" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("test-authoring: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("TG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge traceability on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on traceability.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (traceability).")

    root = posixpath.normpath(os.environ["TG_ROOT"].replace("\\", "/"))
    RECORD_RE = re.compile(r'^docs/issue-([0-9]+)/reports/test-authoring\.md$')

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
    m = RECORD_RE.match(rel)
    if not m:
        sys.exit(0)  # not this gate's write surface
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on traceability." % rel)

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
