#!/usr/bin/env bash
# install.sh — install the orchestrate skill user-wide into ~/.claude.
# Idempotent: rerun after any change. CLAUDE_DIR overrides the target.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLUGIN="$ROOT/plugin"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

# Stale-agent cleanup: remove agents WE installed previously that this version
# no longer ships. Strict manifest whitelist — ~/.claude/agents is a shared
# directory; files this installer never recorded are never touched.
MANIFEST="$CLAUDE_DIR/skills/orchestrate/.installed-agents"
if [ -f "$MANIFEST" ]; then
  while IFS= read -r old; do
    [ -n "$old" ] || continue
    [ -f "$PLUGIN/agents/$old.md" ] && continue   # still shipped this version
    rm -f "$CLAUDE_DIR/agents/$old.md" && echo "  removed stale agent: $old"
  done < "$MANIFEST"
fi

# Skill directory (SKILL.md, dispatch-prompt, patterns, peer.sh, template)
rm -rf "$CLAUDE_DIR/skills/orchestrate"
cp -R "$PLUGIN/skills/orchestrate" "$CLAUDE_DIR/skills/orchestrate"
chmod +x "$CLAUDE_DIR/skills/orchestrate/peer.sh"

# Agent definitions — every role in plugin/agents/ (plugin-standard location);
# record what we installed so the next run can clean up renames.
installed_agents=""
: > "$CLAUDE_DIR/skills/orchestrate/.installed-agents"
for f in "$PLUGIN/agents/"*.md; do
  base="$(basename "$f")"
  cp "$f" "$CLAUDE_DIR/agents/$base"
  installed_agents="$installed_agents ${base%.md}"
  echo "${base%.md}" >> "$CLAUDE_DIR/skills/orchestrate/.installed-agents"
done

# Slash command
cp "$PLUGIN/commands/orchestrate.md" "$CLAUDE_DIR/commands/orchestrate.md"

# Self-check: everything this installer claims to install must actually exist.
for f in SKILL.md dispatch-prompt.md patterns.md peer.sh agent-TEMPLATE.md; do
  [ -e "$CLAUDE_DIR/skills/orchestrate/$f" ] || { echo "SELF-CHECK FAILED: skills/orchestrate/$f" >&2; exit 1; }
done
for f in "$PLUGIN/agents/"*.md; do
  base="$(basename "$f")"
  [ -f "$CLAUDE_DIR/agents/$base" ] || { echo "SELF-CHECK FAILED: agents/$base" >&2; exit 1; }
done
[ -f "$CLAUDE_DIR/commands/orchestrate.md" ] || { echo "SELF-CHECK FAILED: commands/orchestrate.md" >&2; exit 1; }

echo "Installed (manual mode; plugin users: claude plugin marketplace add Zihao-Wu06/claude-code-orchestrate):"
echo "  skill   -> $CLAUDE_DIR/skills/orchestrate/"
echo "  agents  -> $CLAUDE_DIR/agents/:$installed_agents"
echo "  command -> $CLAUDE_DIR/commands/orchestrate.md (/orchestrate)"
echo
echo "Named subagents resolve after a session reload; until then use"
echo 'Agent(subagent_type: "general-purpose", model: "opus"|"sonnet"|"haiku").'

if command -v codex >/dev/null 2>&1; then
  codex login status 2>&1 | sed 's/^/  codex: /' || echo "  peer degraded: run 'codex login'"
else
  echo "  peer degraded: codex CLI not on PATH (Codex routing rows will be skipped; everything else works)"
fi
