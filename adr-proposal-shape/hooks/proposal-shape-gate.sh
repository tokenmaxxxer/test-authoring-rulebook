#!/usr/bin/env bash
__fc(){ rc=$?; if [ "$rc" != 0 ] && [ "$rc" != 2 ]; then echo "fail-closed: gate aborted (rc=$rc)" >&2; exit 2; fi; }
trap __fc EXIT
# PreToolUse gate (Write|Edit|MultiEdit) — test-authoring role's
# adr-proposal-shape plugin (issue-7 §3.3, plugin #1 of the plugin set).
#
# Targets: docs/issue-<n>/proposals/*.md — this role's phase-1 proposal
# write surface per docs/issue-1/proposals/test-authoring-methodology-norms.md
# (a). Requires the six ADR-derived required-section headers, at least
# one `Sources:` line, and — as an independent filesystem order
# constraint — that docs/issue-<n>/reports/test-authoring/survey.md
# already exists on disk for that issue number. Fails closed when the
# resulting content of a write cannot be determined, mirroring
# pricing/hooks/methodology-gate.sh's pattern.
#
# Kill switch: export ADR_PROPOSAL_SHAPE_GATE_OFF=1
#
# Off means off: `X_OFF=0` and `X_OFF=false` read as "not off" to a user
# and to most tooling, but any non-empty value used to disable the hook —
# the kill switch would silently kill it on exactly the spelling meant to
# keep it alive. Normalize (lowercase, trim whitespace) before matching so
# common spelling variants resolve the same as their canonical form. An
# unrecognized value is never silently treated as off: it warns on stderr
# and falls through to running the gate — fail-open to the gate itself,
# never silent suppression of enforcement.
set -uo pipefail

role="${CLAUDE_ROLE:-test-authoring}"
deny() { echo "${role}: refused — $1" >&2; exit 2; }

_adr_off_raw="${ADR_PROPOSAL_SHAPE_GATE_OFF:-}"
_adr_off_norm="$(printf '%s' "$_adr_off_raw" | tr '[:upper:]' '[:lower:]' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
case "$_adr_off_norm" in
  ""|0|false|no|off) ;;
  1|true|yes|on) exit 0 ;;
  *) echo "adr-proposal-shape: unrecognized ADR_PROPOSAL_SHAPE_GATE_OFF value '${_adr_off_raw}' — treating as not-off, gate still runs" >&2 ;;
esac

command -v python3 >/dev/null 2>&1 || deny "proposal-shape-gate.sh requires python3, which is not on PATH; denying rather than guessing."

payload="$(cat 2>/dev/null || true)"
[ -n "$payload" ] || deny "proposal-shape-gate: empty tool-use payload on stdin; cannot evaluate the gate."

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
[ -z "$root" ] && deny "no project root could be determined; failing closed (proposal-shape check cannot run)."

PG_PAYLOAD="$payload" PG_ROOT="$root" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import json, os, posixpath, re, sys

    def deny(m):
        sys.stderr.write("adr-proposal-shape: refused — %s\n" % m); sys.exit(2)

    raw = os.environ.get("PG_PAYLOAD", "")
    try:
        ev = json.loads(raw) if raw else {}
    except ValueError:
        deny("the tool-call payload is not valid JSON; the gate cannot judge proposal shape on an unparseable write.")
    if not isinstance(ev, dict):
        deny("the tool-call payload is not a JSON object; failing closed on proposal shape.")

    tool = ev.get("tool_name")
    ti = ev.get("tool_input")
    if not isinstance(ti, dict):
        deny("tool_input is missing or not a JSON object; the gate cannot judge a write it cannot parse (proposal shape).")

    root = posixpath.normpath(os.environ["PG_ROOT"].replace("\\", "/"))
    PROPOSAL_RE = re.compile(r'^docs/issue-([0-9]+)/proposals/.*\.md$', re.I)

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
    m = PROPOSAL_RE.match(rel)
    if not m:
        sys.exit(0)  # not this gate's write surface
    issue_n = m.group(1)

    current = None
    if os.path.isfile(r):
        try:
            with open(r, encoding="utf-8-sig") as fh:
                current = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed on proposal shape." % rel)

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
            "Edit/MultiEdit whose old_string matches, so the six required sections can be "
            "checked." % (rel, tool)
        )

    low = new_text.lower()

    def has_any(*needles):
        return any(nd in low for nd in needles)

    missing = []

    if not has_any("what was asked"):
        missing.append("what-was-asked")
    if not has_any("survey pointer", "current-state survey"):
        missing.append("survey-pointer")
    if not has_any("adopted methodology", "required components"):
        missing.append("adopted-methodology")
    if not has_any("rationale"):
        missing.append("rationale")
    if not has_any("plugin reflection plan"):
        missing.append("plugin-reflection-plan")
    if not has_any("deliberately out of scope", "deliberately-out-of-scope"):
        missing.append("deliberately-out-of-scope")
    if not has_any("sources:"):
        missing.append("sources-citation")

    survey_path = posixpath.join(root, "docs", "issue-%s" % issue_n, "reports", "test-authoring", "survey.md")
    if not os.path.isfile(survey_path):
        missing.append("survey.md-not-found-at-docs/issue-%s/reports/test-authoring/survey.md" % issue_n)

    if missing:
        deny(
            "proposal write to %s is missing required element(s): %s. Per "
            "docs/issue-1/proposals/test-authoring-methodology-norms.md (a), every "
            "phase-1 proposal must carry all six required section headers (What was "
            "asked / Survey pointer / Adopted methodology / Rationale / Plugin "
            "reflection plan / Deliberately out of scope), at least one `Sources:` "
            "citation line, and the issue's survey.md must already exist on disk "
            "before the proposal lands." % (rel, ", ".join(missing))
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
