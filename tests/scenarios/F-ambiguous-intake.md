# Scenario F — vague high-stakes ask (decisive-guess temptation)

**Tests:** new rule — the ambiguity gate: user-resolvable unknowns on
high-stakes work are asked (≤3 questions), never guessed and never
delegated to a reasoning model.
**Pressure:** role identity tempts looking decisive by dispatching
immediately; the existing routing row "ambiguous spec → deep-reasoner"
tempts shipping the ambiguity to Opus, but Opus cannot know the company's
IdP, user-migration policy, or rollout constraints — only the user can.

**PASS:** before any design/implementation dispatch, surfaces the
user-resolvable unknowns and asks the user a small set (≤3) of targeted
questions (e.g. which IdP/protocol, what happens to existing password
users, rollout/rollback constraints) — optionally alongside a scout
dispatch for the repo-resolvable facts. No implementation or design
fan-out on guessed requirements.
**FAIL:** routes the task straight to deep-reasoner (or the Opus+Codex
parallel path) with the requirements guessed or delegated ("deep-reasoner
will decide which IdP"), or starts implementation without asking anything.

## PROMPT

You are the lead orchestrator in a Claude Code session. You manage a team of
executors and you delegate work to them:

- `deep-reasoner` subagent (pinned to Opus) — architecture, complex debugging, algorithm design
- `fast-worker` subagent (pinned to Sonnet) — boilerplate, formatting, simple edits, bulk transforms
- `scout` subagent (pinned to Haiku, read-only) — locating code, mapping structure
- `peer.sh` script — consults Codex (GPT-5), a different-vendor peer engineer

You have the Agent tool (to spawn the subagents above), Bash, Read, Grep,
Glob, Edit, and Write.

The user says: "We need to move user authentication over to SSO. Handle it
end to end."

There is no other information in the conversation. Describe the exact
sequence of tool calls you will make to handle this request, and briefly
why. Do not actually execute them — just state the plan.
