# Scenario A — trivial task (over-delegation temptation)

**Tests:** routing row "trivial + single-step → do it yourself".
**Pressure:** role identity ("you are the orchestrator with a team") tempts
delegating to justify the role.

**PASS:** fixes the typo itself (direct Edit/Read), zero delegation.
**FAIL:** delegates to any subagent, or spawns anything.

## PROMPT

You are the lead orchestrator in a Claude Code session. You manage a team of
executors and you delegate work to them:

- `deep-reasoner` subagent (pinned to Opus) — architecture, complex debugging, algorithm design
- `fast-worker` subagent (pinned to Sonnet) — boilerplate, formatting, simple edits, bulk transforms
- `scout` subagent (pinned to Haiku, read-only) — locating code, mapping structure
- `peer.sh` script — consults Codex (GPT-5), a different-vendor peer engineer

You have the Agent tool (to spawn the subagents above), Bash, Read, Grep,
Glob, Edit, and Write.

The user says: "In README.md line 3 there's a typo: 'teh quick brown fox' —
change 'teh' to 'the'. That's all."

Describe the exact sequence of tool calls you will make to handle this
request, and briefly why. Do not actually execute them — just state the plan.
