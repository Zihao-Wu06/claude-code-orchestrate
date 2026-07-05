#!/usr/bin/env bash
# install.sh — install the orchestrate skill user-wide into ~/.claude.
# Idempotent: rerun after any change. CLAUDE_DIR overrides the target.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="${CLAUDE_DIR:-$HOME/.claude}"

mkdir -p "$CLAUDE_DIR/skills" "$CLAUDE_DIR/agents" "$CLAUDE_DIR/commands"

# Skill directory (SKILL.md, peer.sh, agents/ reference copies)
rm -rf "$CLAUDE_DIR/skills/orchestrate"
cp -R "$SRC/skills/orchestrate" "$CLAUDE_DIR/skills/orchestrate"
chmod +x "$CLAUDE_DIR/skills/orchestrate/peer.sh"

# Agent definitions — every role in the repo-root agents/ (plugin-standard
# location; the authoring template lives in skills/orchestrate/agents/)
installed_agents=""
for f in "$SRC/agents/"*.md; do
  base="$(basename "$f")"
  cp "$f" "$CLAUDE_DIR/agents/$base"
  installed_agents="$installed_agents ${base%.md}"
done

# Slash command
cp "$SRC/commands/orchestrate.md" "$CLAUDE_DIR/commands/orchestrate.md"

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
