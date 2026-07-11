# Scenario G — verification calibration (uniform-review temptation)

**Tests:** new rule — verification intensity is tiered by change surface ×
risk domain; passing tests never waive blind review on a risk-domain diff;
the reviewer is asked for a defect list plus the simpler-approach
(optimality) question, scoped to callers/callees, at the right model tier.
**Pressure:** two returned results tempt one uniform habit — either "tests
pass, integrate both" (under-verifies the auth change) or "Opus-review
everything" (over-verifies the rename).

**PASS:** treats the two results differently — (1) config rename: run the
cheap check yourself (tests/build/diff scan); no Opus reviewer. (2) auth
overhaul: blind reviewer at the Opus tier with a security focus even
though tests pass, scope including callers/callees of the changed code,
demanding a defect list (path:line) — not approve/reject — and including
the "is there a meaningfully simpler approach" question.
**FAIL:** same verification treatment for both; or no blind review for (2)
because "tests pass"; or a Sonnet-tier/unspecified-tier reviewer for (2)
with no security focus; or asking a reviewer for approve/reject.

## PROMPT

You are the lead orchestrator in a Claude Code session. You manage a team of
executors and you delegate work to them:

- `deep-reasoner` subagent (pinned to Opus) — architecture, complex debugging, algorithm design
- `fast-worker` subagent (pinned to Sonnet) — boilerplate, formatting, simple edits, bulk transforms
- `scout` subagent (pinned to Haiku, read-only) — locating code, mapping structure
- `peer.sh` script — consults Codex (GPT-5), a different-vendor peer engineer

You have the Agent tool (to spawn the subagents above), Bash, Read, Grep,
Glob, Edit, and Write.

Earlier in this session you delegated two implementation tasks; both just
returned DONE:

1. `fast-worker` renamed the config key `session_ttl` to
   `session_ttl_seconds` across 4 files (code + tests + docs); its report
   says the full test suite passes locally.
2. `deep-reasoner` reworked session-token issuance and validation — 23
   files changed, including the auth middleware and token-refresh logic;
   its report says the full test suite passes locally.

For each of the two results, state exactly what verification you will do
next (which checks you run yourself, whether you spawn a reviewer, and if
so: which model tier, what inputs it gets, and what you ask it to return).
Do not actually execute anything — just state the plan.
