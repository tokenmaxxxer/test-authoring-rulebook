#!/usr/bin/env bash
# Resolves CLAUDE_PLUGIN_ROOT_CORE so this repo's gate test suites can run
# standalone (`bash <plugin>/tests/*.sh` outside a Claude Code session
# where a plugin installer would normally set it), without vendoring
# core/hooks/lib/gate-lib.sh|py into this repo (canon reference-only, per
# tokenmaxxxer-core's docs/handbooks/canon-scripts.md). Sourced by each
# plugin's own test suite and by tests/run-all-gate-tests.sh.
#
# Honors an already-exported CLAUDE_PLUGIN_ROOT_CORE first (a real
# install, or a developer's own local `core` checkout). Otherwise tries
# known local tokenmaxxxer-core checkouts, then falls back to a one-time
# shallow clone into a cache directory.
if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ]; then
  for _cand in \
    "$HOME/tokenmaxxxer/tokenmaxxxer-core/core" \
    "${TMPDIR:-/tmp}/tokenmaxxxer-core-canon-cache/core"
  do
    if [ -f "$_cand/hooks/lib/gate-lib.sh" ]; then
      export CLAUDE_PLUGIN_ROOT_CORE="$_cand"
      break
    fi
  done
  unset _cand
fi

if [ -z "${CLAUDE_PLUGIN_ROOT_CORE:-}" ]; then
  _resolve_core_cache="${TMPDIR:-/tmp}/tokenmaxxxer-core-canon-cache"
  if [ ! -f "$_resolve_core_cache/core/hooks/lib/gate-lib.sh" ]; then
    rm -rf "$_resolve_core_cache"
    git clone -q --depth 1 https://github.com/tokenmaxxxer/tokenmaxxxer-core.git \
      "$_resolve_core_cache" >/dev/null 2>&1 || true
  fi
  if [ -f "$_resolve_core_cache/core/hooks/lib/gate-lib.sh" ]; then
    export CLAUDE_PLUGIN_ROOT_CORE="$_resolve_core_cache/core"
  fi
  unset _resolve_core_cache
fi
