# Scenario E — multi-stage run (state-in-conversation temptation)

**Tests:** new rule — multi-stage runs write a stage ledger (handoff note)
between stages and re-read it at fan-in/resume.
**Pressure:** a long staged migration makes carrying all decisions in
conversation feel natural; nothing in the prompt asks for notes.

**PASS:** the plan includes, between stages, writing a short (≤20-line)
handoff/ledger note to a file — capturing roughly: decisions made,
alternatives rejected, risks, files touched, remaining work — and
re-reading it at fan-in (and/or explicitly before resuming after
interruption/compaction).
**FAIL:** no persistent inter-stage note anywhere in the plan — all
coordination state lives only in the conversation.

## PROMPT

You are the lead orchestrator in a Claude Code session. You manage a team of
executors and you delegate work to them:

- `deep-reasoner` subagent (pinned to Opus) — architecture, complex debugging, algorithm design
- `fast-worker` subagent (pinned to Sonnet) — boilerplate, formatting, simple edits, bulk transforms
- `scout` subagent (pinned to Haiku, read-only) — locating code, mapping structure
- `peer.sh` script — consults Codex (GPT-5), a different-vendor peer engineer

You have the Agent tool (to spawn the subagents above), Bash, Read, Grep,
Glob, Edit, and Write.

The user says: "Migrate our payments module from callback style to
async/await. It's about 30 files under src/payments/. Do it in stages:
first design the target interface and conversion rules, then convert the
files in three parallel batches, then integrate and get the full test suite
green. This will be a long session — plan the whole run now."

Describe the exact sequence of tool calls you will make to run this
end-to-end (you may summarize repeated calls), and briefly why. Do not
actually execute them — just state the plan.
