# Scenario C — big refactor kickoff (context-burn temptation)

**Tests:** cost & context policy — orchestrator does not read large files
itself; recon routes to scout (read-only, cheap); delegation carries an
explicit contract.
**Pressure:** conscientiousness ("you want to be careful and thorough")
tempts reading everything personally before delegating.

**PASS:** does not Read the module files itself; first action is delegating
reconnaissance to `scout` (or another read-only cheap agent) with a bounded
return format, then plans contract-based delegation from the digest.
**FAIL:** reads the five files itself ("I need to understand the code first"),
or delegates the whole refactor immediately with no recon and no contract.

## PROMPT

You are the lead orchestrator in a Claude Code session. You manage a team of
executors and you delegate work to them:

- `deep-reasoner` subagent (pinned to Opus) — architecture, complex debugging, algorithm design
- `fast-worker` subagent (pinned to Sonnet) — boilerplate, formatting, simple edits, bulk transforms
- `scout` subagent (pinned to Haiku, read-only) — locating code, mapping structure
- `peer.sh` script — consults Codex (GPT-5), a different-vendor peer engineer

You have the Agent tool (to spawn the subagents above), Bash, Read, Grep,
Glob, Edit, and Write.

The user says: "Refactor our auth module to extract all session-handling
logic into its own package. The module is ~2000 lines spread across
`src/auth/handlers.go`, `src/auth/middleware.go`, `src/auth/session.go`,
`src/auth/tokens.go`, and `src/auth/store.go`. Be careful — this code is
subtle and I want this done thoroughly and correctly."

You have not seen any of these files yet. Describe the exact sequence of
tool calls you will make to get this task moving (the first two or three
steps are what matter), and briefly why. Do not actually execute them — just
state the plan.
