# Running this role's gate tests

`test-authoring-rulebook` ships five plugins whose `Write|Edit|MultiEdit`
gates source `tokenmaxxxer-core`'s gate-house standard
(`core/hooks/lib/gate-lib.sh`/`gate-lib.py`, core issue #72) — reference
only, never vendored into this repo.

## Running the full suite

```
bash tests/run-all-gate-tests.sh
```

Runs each plugin's own test suite in turn:

- `adr-proposal-shape/tests/proposal-shape-gate-tests.sh`
- `ep-bva-technique/tests/technique-gate-tests.sh`
- `traceability-line/tests/traceability-gate-tests.sh`
- `xunit-suite-patterns/tests/suite-patterns-gate-tests.sh`

Each test spawns its gate script as a real subprocess against a
throwaway `mktemp -d` + `git init` fixture, feeding a synthetic
`PreToolUse` JSON payload on stdin and asserting the gate's exit code
(0=allow, 2=deny). Every suite covers the gate-house standard's six
mandatory case groups (`Edit`+`replace_all`, `MultiEdit` mixed
`replace_all`, malformed JSON, kill-switch-unrecognized-value-stays-
active, absolute-path and `./`-prefixed path parity) plus that gate's
own semantic-upgrade adjacency cases.

## Resolving core's gate-lib outside a plugin install

A real Claude Code plugin install sets `CLAUDE_PLUGIN_ROOT_CORE`
automatically. Running these test suites standalone (this repo cloned on
its own, no marketplace install) needs it resolved another way —
`tests/resolve-core.sh` (sourced by every test suite and by
`run-all-gate-tests.sh`) does this in order: an already-exported
`CLAUDE_PLUGIN_ROOT_CORE`, a local `tokenmaxxxer-core` checkout at
`~/tokenmaxxxer/tokenmaxxxer-core/core`, a prior shallow-clone cache
under `$TMPDIR`, or a fresh one-time shallow clone of
`tokenmaxxxer/tokenmaxxxer-core`.

## Compliance check

`core/hooks/tests/compliance-check.sh <hooks-dir>` (also core canon,
reference only) flags a gate that hand-rolls a kill switch or an
`Edit`/`MultiEdit` reconstruction instead of calling `gate-lib`'s
functions. Run it against each plugin's `hooks/` directory before
delivering any gate change:

```
bash "${CLAUDE_PLUGIN_ROOT_CORE:-$HOME/tokenmaxxxer/tokenmaxxxer-core/core}/hooks/tests/compliance-check.sh" adr-proposal-shape/hooks
bash "${CLAUDE_PLUGIN_ROOT_CORE:-$HOME/tokenmaxxxer/tokenmaxxxer-core/core}/hooks/tests/compliance-check.sh" ep-bva-technique/hooks
bash "${CLAUDE_PLUGIN_ROOT_CORE:-$HOME/tokenmaxxxer/tokenmaxxxer-core/core}/hooks/tests/compliance-check.sh" traceability-line/hooks
bash "${CLAUDE_PLUGIN_ROOT_CORE:-$HOME/tokenmaxxxer/tokenmaxxxer-core/core}/hooks/tests/compliance-check.sh" xunit-suite-patterns/hooks
```

A rulebook's own A+ remediation issue (issue-10 for this role) cites this
output as delivery evidence, per
`docs/handbooks/gate-house-standard.md` step 4-5 in
`tokenmaxxxer-core`.
