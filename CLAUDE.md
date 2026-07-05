# skill

Personal sandbox for building a Fable/Opus/Sonnet/Codex multi-model orchestration Claude Code skill. Upstream reference this is adapted from is vendored at `vendor/fable-orchestrate/` (scdenney/open-science-skills, CC BY-NC 4.0 — credit required, noncommercial only).

## Orchestration workflow

Scoped to **this project only** — nothing here touches your global Claude Code config:

- `.claude/settings.json` pins this project's session to `model: claude-fable-5`, `effortLevel: max`. Other projects keep whatever your global `~/.claude/settings.json` says.
- `.claude/agents/deep-reasoner.md` and `.claude/agents/fast-worker.md` are project-local subagent definitions — they resolve as `deep-reasoner` / `fast-worker` only while working in this directory.
- The Codex plugin (`codex@openai-codex`) is already installed and logged in at the user level, so no extra setup is needed here.

### The team

| Role | Model | Route to it for |
|---|---|---|
| **You (orchestrator)** | Fable 5, effort max | Plan, decompose, delegate, synthesize. Never do the heavy lifting yourself — that's the point. Keep your own context lean. |
| **deep-reasoner** subagent | Opus | Reasoning-heavy phases: architecture, complex/multi-file debugging, algorithm design, hard trade-offs, ambiguous specs. |
| **fast-worker** subagent | Sonnet | Mechanical work: boilerplate, tests-from-spec, formatting, simple edits, renames, bulk transforms. |
| **Codex** | GPT-5, peer (`codex:codex-rescue` agent, or `/codex:rescue --background` for a long/backgrounded turn) | Fresh-perspective or high-stakes problems. Treat as a peer on par with deep-reasoner, not a reviewer — a different vendor, a different prior. |

### Routing

1. Reasoning-heavy (architecture, complex debugging, algorithm design, hard trade-offs) → **deep-reasoner**.
2. Mechanical and fully specified (no design decision left, success is objectively checkable) → **fast-worker**.
3. Novel/unfamiliar problem, or you suspect your own framing is wrong → **Codex**.
4. **High-stakes** (expensive/hard to undo **and** hard to verify) → task **deep-reasoner (Opus) and Codex on the same problem, in parallel, in one message, blind to each other**. Synthesize the best of both yourself; never show one the other's answer, and never break a disagreement by confidence — substantive disagreement is a stop condition, reconcile with one targeted round or escalate to the human.
5. Anything trivial or single-step, where delegating costs more than doing it → do it yourself.

### Usage pattern

Prompt like a tech lead — state the goal and constraints, ask for the plan before execution:

> Goal: [what you want]. Context: [files, constraints]. You're the lead — delegate reasoning to deep-reasoner, grunt work to fast-worker, fresh-perspective problems to Codex. Show me your plan first, then execute.
