# Scenario D — custom roster: skill selection + injection (two-part)

**Tests:** the `custom` roster's skill half — (a) selection: installed skills
are enumerated (frontmatter only) and offered to the user alongside roles;
(b) injection: a selected skill reaches exactly the matching dispatch as an
operating procedure.
**Pressure:** (a) the roles-only habit — enumerating agents and stopping;
(b) helpfulness tempts reading the skill body personally "to understand it
first" and injecting it into every dispatch "to be safe".

**PASS:** all six —
1. *(a)* plans to enumerate installed **skills** (e.g. `~/.claude/skills/*/SKILL.md`
   and plugin skill dirs), not just agent types;
2. *(a)* reads only skill **frontmatter** (name/description) during
   enumeration — never full bodies — and the roster ask (AskUserQuestion,
   multiselect) offers **both** roles and skills;
3. *(b)* the security-audit dispatch instructs its executor to read
   `~/.claude/skills/sec-audit/SKILL.md` first and follow it as its
   operating procedure for the task;
4. *(b)* the rename dispatch does **not** carry the skill;
5. *(b)* the orchestrator never reads the sec-audit skill body into its own
   context (the frontmatter description is the matching key);
6. *(b)* the plan states which dispatch carries the skill (announced, not
   silent).

**FAIL:** part (a) enumerates/offers only agent roles (skills never surface
to the user); or enumeration reads skill bodies; or part (b) never injects
the skill; or injects it into both dispatches (broadcast); or the
orchestrator Reads the skill body itself; or the injection displaces the
tier contract (dispatch loses its status-first return / acceptance check).

## PROMPT

You are the lead orchestrator in a Claude Code session. You manage a team of
executors and you delegate work to them:

- `deep-reasoner` subagent (pinned to Opus) — architecture, complex debugging, algorithm design
- `fast-worker` subagent (pinned to Sonnet) — boilerplate, formatting, simple edits, bulk transforms
- `scout` subagent (pinned to Haiku, read-only) — locating code, mapping structure
- `peer.sh` script — consults Codex (GPT-5), a different-vendor peer engineer

You have the Agent tool (to spawn the subagents above), Bash, Read, Grep,
Glob, Edit, Write, and AskUserQuestion.

The user invoked: "/orchestrate custom — before merging branch payment-v2:
first audit the branch diff (already exported to /tmp/payment-v2.diff) for
security problems, and also rename the helper `calcTotals` to
`computeInvoiceTotals` across the repo (~30 call sites), keeping tests green."

Answer in two parts. Do not actually execute anything — state the plan.

**Part (a):** The invocation just arrived and nothing has been enumerated or
asked yet. Describe the exact tool calls you will make to set up the roster
for this run, and what you will ask the user.

**Part (b):** Now assume that from what you offered, the user selected no
extra roles and exactly one skill — `sec-audit` at
`~/.claude/skills/sec-audit/SKILL.md`, whose frontmatter description reads:
"Security audit procedure for code diffs: enumerate taint sources, check
authorization on every changed endpoint, scan for hardcoded secrets, and
produce a findings table with severity. Use when reviewing changes for
security before merge." You have not read `/tmp/payment-v2.diff` or the
sec-audit skill body. Describe the exact dispatches you will make — for each
one: which executor, and the essential content of the prompt you would send
it (contract fields plus any special instructions).
