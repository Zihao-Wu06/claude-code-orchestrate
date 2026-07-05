#!/usr/bin/env bash
# test-peer.sh — mock-codex smoke test for plugin/skills/orchestrate/peer.sh.
# No real Codex CLI needed: a fake `codex` on PATH records the argv it gets
# and proves stdin is redirected (reads must hit EOF instantly, never hang).
# On macOS runners this also exercises the bash-watchdog timeout branch for
# real (no GNU timeout there). Runs in ~3s; wired into `make check`.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PEER="$ROOT/plugin/skills/orchestrate/peer.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

fail(){ echo "FAIL: $*" >&2; exit 1; }
pass(){ echo "  ok: $*"; }

# --- mock codex: prints argv one-per-line, then how many stdin bytes it saw
mkdir -p "$TMP/bin"
cat > "$TMP/bin/codex" <<'MOCK'
#!/usr/bin/env bash
for a in "$@"; do printf 'ARG:%s\n' "$a"; done
printf 'STDIN_BYTES:%s\n' "$(wc -c < /dev/stdin | tr -d ' ')"
MOCK
chmod +x "$TMP/bin/codex"
export PATH="$TMP/bin:$PATH"

# 1. consult mode → read-only sandbox, prompt passed, stdin empty (no hang)
out="$("$PEER" --mode consult -C "$TMP" --prompt "PING")"
grep -q '^ARG:--sandbox$' <<<"$out" && grep -q '^ARG:read-only$' <<<"$out" || fail "consult sandbox flags: $out"
grep -q '^ARG:PING$' <<<"$out" || fail "prompt not passed through"
grep -q '^STDIN_BYTES:0$' <<<"$out" || fail "stdin was not /dev/null-redirected"
pass "consult → read-only sandbox, prompt through, stdin empty"

# 2. implement mode → workspace-write
out="$("$PEER" --mode implement -C "$TMP" --prompt "X")"
grep -q '^ARG:workspace-write$' <<<"$out" || fail "implement sandbox: $out"
pass "implement → workspace-write"

# 3. --effort maps to model_reasoning_effort config
out="$("$PEER" --mode consult --effort high -C "$TMP" --prompt "X")"
grep -q '^ARG:model_reasoning_effort=high$' <<<"$out" || fail "--effort mapping: $out"
pass "--effort high → -c model_reasoning_effort=high"
out="$("$PEER" --mode consult -C "$TMP" --prompt "X")"
grep -q 'model_reasoning_effort' <<<"$out" && fail "effort flag leaked when unset"
pass "no effort flag when unset (backend default)"

# 4. --out tees the transcript to a file
"$PEER" --mode consult -C "$TMP" --out "$TMP/out.txt" --prompt "X" > /dev/null
grep -q '^ARG:X$' "$TMP/out.txt" || fail "--out file not written"
pass "--out tees transcript"

# 5. timeout kills a hung backend AND its whole process tree
#    (watchdog branch on macOS, GNU timeout on Linux). The mock spawns a
#    child `sleep` on purpose: a leaked grandchild holding the pipe open is
#    exactly the regression this guards against.
cat > "$TMP/bin/codex" <<'MOCK'
#!/usr/bin/env bash
sleep 6
MOCK
chmod +x "$TMP/bin/codex"
start=$SECONDS
rc=0; "$PEER" --mode consult -C "$TMP" --timeout 1 --prompt "X" > "$TMP/t5.out" 2>&1 || rc=$?
elapsed=$(( SECONDS - start ))
[ "$rc" -ne 0 ] || fail "timeout did not produce a non-zero exit"
[ "$elapsed" -le 4 ] || fail "timeout took ${elapsed}s (backend tree not killed)"
pass "hung backend tree killed by --timeout (rc=$rc, ${elapsed}s)"

# 6. argument validation dies cleanly (exit 2) without invoking the backend
for args in "--mode bogus --prompt X" "--effort ultra --prompt X" "--backend gemini --prompt X" ""; do
  rc=0; "$PEER" $args > /dev/null 2>&1 || rc=$?
  [ "$rc" -eq 2 ] || fail "bad args ($args) exited $rc, expected 2"
done
pass "invalid mode/effort/backend/missing-prompt all exit 2"

# 7. the persistent on/off switch (CLAUDE_DIR-scoped marker; exit 3 when off)
cat > "$TMP/bin/codex" <<'MOCK'
#!/usr/bin/env bash
echo "BACKEND_RAN"
MOCK
chmod +x "$TMP/bin/codex"
export CLAUDE_DIR="$TMP/claude-home"
out="$(CLAUDE_DIR="$CLAUDE_DIR" "$PEER" --off)"
grep -q "disabled" <<<"$out" || fail "--off did not report disabled"
test -f "$CLAUDE_DIR/orchestrate.peer-off" || fail "--off did not create the marker"
rc=0; out="$(CLAUDE_DIR="$CLAUDE_DIR" "$PEER" --mode consult -C "$TMP" --prompt "X" 2>&1)" || rc=$?
[ "$rc" -eq 3 ] || fail "disabled run exited $rc, expected 3"
grep -q "BACKEND_RAN" <<<"$out" && fail "backend ran while disabled"
grep -q "peer.sh --on" <<<"$out" || fail "disabled message lacks the re-enable hint"
st="$(CLAUDE_DIR="$CLAUDE_DIR" "$PEER" --status)"   # capture, THEN grep — grep -q on a
grep -q "disabled" <<<"$st" || fail "--status missed disabled state"   # pipe SIGPIPEs the writer
CLAUDE_DIR="$CLAUDE_DIR" "$PEER" --on > /dev/null
test ! -f "$CLAUDE_DIR/orchestrate.peer-off" || fail "--on did not remove the marker"
out="$(CLAUDE_DIR="$CLAUDE_DIR" "$PEER" --mode consult -C "$TMP" --prompt "X")"
grep -q "BACKEND_RAN" <<<"$out" || fail "backend did not run after --on"
st="$(CLAUDE_DIR="$CLAUDE_DIR" "$PEER" --status)"
grep -q "enabled" <<<"$st" || fail "--status missed enabled state"
unset CLAUDE_DIR
pass "persistent switch: --off blocks (exit 3, hint shown), --on restores, --status reports"

echo "peer.sh mock smoke: all tests passed"
