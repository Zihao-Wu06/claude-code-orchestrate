#!/usr/bin/env bash
# peer.sh — invoke a different-vendor engineer as a peer for the orchestrate skill.
# Adapted from codex-peer.sh in scdenney/open-science-skills (CC BY-NC 4.0).
#
# Backends: codex (default; GPT-5 family via the Codex CLI). Adding a vendor =
# writing one backend_<name>() function below and listing it in run()'s case.
# Backend contract: print the answer to stdout; read nothing from stdin.
#
# A peer is a decorrelated second prior, not a reviewer. Two modes:
#   consult   (default) — read-only. Ask a question / get a second approach.
#   implement           — workspace-write. Let the peer edit files in a directory.
#
# VERIFIED codex pattern (the reason this wrapper exists):
#   codex exec --sandbox <mode> --skip-git-repo-check -C <dir> "<prompt>" < /dev/null
# The `< /dev/null` is LOAD-BEARING: without it, codex exec prints
# "Reading additional input from stdin..." and hangs forever even when the
# prompt is passed as an argument. `timeout` is a second backstop.
#
# The orchestrator runs this via the Bash tool with run_in_background:true so a
# long peer turn does not block the loop — then reads the --out file when the
# task-notification fires. For the high-stakes path, launch this AND a
# deep-reasoner (Opus) subagent on the SAME prompt in one message, blind to
# each other, then reconcile.
#
# Usage:
#   peer.sh [--backend NAME] [--mode consult|implement] [-C DIR]
#           [--effort low|medium|high|xhigh] [--timeout SEC] [--out FILE]
#           (--prompt TEXT | --prompt-file PATH | -)
#
#   --backend NAME  vendor CLI to use (default: codex)
#   --mode MODE     consult = read-only sandbox; implement = workspace-write
#   -C DIR          working dir the peer sees (default: $PWD)
#   --effort LEVEL  peer reasoning depth; unset = backend default (codex: xhigh)
#   --timeout SEC   hard kill after SEC seconds (default: 600)
#   --out FILE      also tee stdout+stderr here (for background reads)
#   --prompt TEXT   prompt as a single argument
#   --prompt-file P read prompt from file P
#   -               read prompt from stdin (the wrapper handles the /dev/null dance)
set -euo pipefail

BACKEND="codex"; MODE="consult"; DIR="$PWD"; EFFORT=""; TIMEOUT=600; OUT=""; PROMPT=""; PROMPT_SET=0

die(){ echo "peer: $*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --backend)     BACKEND="${2:?}"; shift 2 ;;
    --mode)        MODE="${2:?}"; shift 2 ;;
    -C|--dir)      DIR="${2:?}"; shift 2 ;;
    --effort)      EFFORT="${2:?}"; shift 2 ;;
    --timeout)     TIMEOUT="${2:?}"; shift 2 ;;
    --out)         OUT="${2:?}"; shift 2 ;;
    --prompt)      PROMPT="${2:?}"; PROMPT_SET=1; shift 2 ;;
    --prompt-file) PROMPT="$(cat "${2:?}")"; PROMPT_SET=1; shift 2 ;;
    -)             PROMPT="$(cat)"; PROMPT_SET=1; shift ;;
    -h|--help)     sed -n '2,41p' "$0"; exit 0 ;;
    *)             die "unknown arg: $1 (see --help)" ;;
  esac
done

[ "$PROMPT_SET" = 1 ] || die "no prompt (use --prompt, --prompt-file, or -)"
[ -n "$PROMPT" ] || die "empty prompt"
[ -d "$DIR" ] || die "no such dir: $DIR"

case "$MODE" in
  consult|implement) : ;;
  *) die "bad --mode: $MODE (consult|implement)" ;;
esac
case "$EFFORT" in
  ""|low|medium|high|xhigh) : ;;
  *) die "bad --effort: $EFFORT (low|medium|high|xhigh)" ;;
esac

# Portable timeout: GNU timeout / gtimeout when present (Linux, brew coreutils),
# else a bash watchdog — macOS ships no `timeout` and the hard kill is a
# required backstop for a hung vendor CLI.
with_timeout(){
  if command -v timeout >/dev/null 2>&1; then
    timeout "${TIMEOUT}s" "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout "${TIMEOUT}s" "$@"
  else
    "$@" &
    local cmd_pid=$!
    ( sleep "$TIMEOUT"; kill -TERM "$cmd_pid" 2>/dev/null ) &
    local dog_pid=$!
    local rc=0
    wait "$cmd_pid" || rc=$?
    kill "$dog_pid" 2>/dev/null || true
    wait "$dog_pid" 2>/dev/null || true
    return "$rc"
  fi
}

# ---- backends ----------------------------------------------------------------

backend_codex(){
  command -v codex >/dev/null || die "codex CLI not on PATH — install it first"
  local sandbox
  case "$MODE" in
    consult)   sandbox="read-only" ;;
    implement) sandbox="workspace-write" ;;
  esac
  local extra=()
  [ -n "$EFFORT" ] && extra=(-c "model_reasoning_effort=$EFFORT")
  with_timeout codex exec \
    --sandbox "$sandbox" \
    --skip-git-repo-check \
    ${extra[@]+"${extra[@]}"} \
    -C "$DIR" \
    "$PROMPT" < /dev/null
}

run(){
  case "$BACKEND" in
    codex) backend_codex ;;
    *)     die "unknown --backend: $BACKEND (available: codex)" ;;
  esac
}

if [ -n "$OUT" ]; then
  run 2>&1 | tee "$OUT"
else
  run
fi
