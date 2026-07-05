# orchestrate — a multi-model orchestration skill for Claude Code

[![ci](https://github.com/Zihao-Wu06/claude-code-orchestrate/actions/workflows/ci.yml/badge.svg)](https://github.com/Zihao-Wu06/claude-code-orchestrate/actions/workflows/ci.yml)
[![license: CC BY-NC 4.0](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey.svg)](LICENSE)
[![plugin](https://img.shields.io/badge/claude%20code-plugin-blue.svg)](.claude-plugin/plugin.json)

The session's main model (intended: Fable 5) leads as **orchestrator** — planning,
decomposing, delegating, synthesizing — while the actual work routes to cheaper,
model-pinned executors:

| Executor | Model | Does |
|---|---|---|
| deep-reasoner | Opus | architecture, complex debugging, algorithm design, hard trade-offs |
| fast-worker | Sonnet | boilerplate, tests-from-spec, formatting, bulk edits |
| scout | Haiku, read-only | locating code, mapping structure, summarizing state |
| peer (Codex) | GPT-5, different vendor | fresh perspectives, disputed designs, parallel cross-checks |

## Provenance & license

Adapted from the `fable-orchestrate` skill in
[scdenney/open-science-skills](https://github.com/scdenney/open-science-skills)
by **Steven Denney** (CC BY-NC 4.0). Substantial changes made — see the feature
delta below. This adaptation is likewise licensed
[CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/): noncommercial
use only, credit required. The pristine upstream snapshot is kept in
`vendor/fable-orchestrate/` for diffing and future syncs.

## Install

**As a plugin (recommended):**

```bash
claude plugin marketplace add Zihao-Wu06/claude-code-orchestrate
claude plugin install orchestrate@claude-code-orchestrate
```

Skills, the `/orchestrate` command, and the three agents register automatically.

**Manually:**

```bash
make install          # scripts/install.sh — copies into ~/.claude/{skills,agents,commands}
```

Named subagents (`deep-reasoner`, `fast-worker`, `scout`) resolve after a
session reload; until then `Agent(subagent_type: "general-purpose", model: …)`
gives identical pinning. The Codex peer additionally needs the
[Codex CLI](https://github.com/openai/codex) installed and `codex login` done —
without it the Codex routing rows degrade gracefully (announced, skipped).

## Use

```
/orchestrate [cheap|thorough] [custom] <task…>
```

- `cheap` — never runs the two-model parallel cross-check (announces the skip),
  routes borderline work down to Sonnet first, calls the peer at `--effort medium`.
- `thorough` — routes borderline work up to Opus, adds an adversarial falsify
  pass on high-stakes conclusions, doubles the reconcile budget.
- `custom` — asks which installed agent roles to use for this run
  (write your own with `plugin/skills/orchestrate/agent-TEMPLATE.md`).
- No modifier — the standard routing table.

Or just describe the job like a tech-lead brief: goal, context, constraints —
and ask it to show the plan first.

## What was changed vs upstream (feature delta)

Everything upstream is kept: the first-match routing table, the seven
Opus/Sonnet mixing patterns, the Codex use/don't-use signals, the blind
parallel path, the fragmentation/rubber-stamping guardrail, the gotchas.
Added on top:

1. **scout role** (new agent + routing row 4) — read-only recon on Haiku so the
   orchestrator never burns its own context reading files to "understand first".
2. **Cost & context policy** — explicit rules: >100-line reads go to scout;
   delegation prompts self-contained; every return capped at conclusion +
   evidence ≤ 20 lines with `path:line` anchors; slow work backgrounds.
3. **Verification stage** — implement-type fan-ins get an independent check:
   run the cheap check, else a fresh reviewer (blind to the implementation)
   returns a defect list, never approve/reject.
4. **Delegation contract template** — six copy-paste fields (Goal / Inputs /
   Constraints / Interface / Acceptance check / Return format).
5. **SDO-compliant description** — frontmatter states triggering conditions
   only; upstream's summarized the workflow, which makes agents follow the
   description and skip the body.
6. **Tech-lead command** — `/orchestrate` bakes in the goal/context/plan-first
   briefing pattern; main model and effort are the user's session choice, never
   dictated by the skill.
7. **Budget modes** — `cheap` / default / `thorough` adjust routing tendency
   and verification intensity, never silently (all skips announced) and never
   by reducing any executor's thinking depth.
8. **Escalation ladder** — fast-worker ×2 fail → deep-reasoner → (2 circling
   rounds) → Codex → human; never re-route a failed task down-tier.
9. **Generalized peer interface** — `codex-peer.sh` refactored to
   `peer.sh --backend codex` (one function per vendor backend; the verified
   codex invocation pattern preserved verbatim) plus `--effort` mapped to
   `model_reasoning_effort`.
10. **Fan-out worktree isolation** — parallel workers that edit files get
    `Agent(isolation: "worktree")`; non-overlapping scope on paper doesn't
    prevent real file conflicts.
11. **Regression test suite** — `tests/` holds standalone pressure scenarios,
    a RUNBOOK, and recorded baseline/with-skill results (superpowers
    writing-skills TDD); any SKILL.md edit requires a rerun.
12. **Optional custom roster** — `custom` modifier asks (multiSelect) which
    installed roles to use this run; selected roles slot into a tier
    (recon/mechanical/reasoning/peer) and inherit its rules; the routing
    table itself never changes. `agent-TEMPLATE.md` is the authoring guide.

## Layout

```
plugin/                  the shippable plugin, complete in one folder:
  ├── .claude-plugin/      plugin manifest
  ├── skills/orchestrate/  SKILL.md, dispatch-prompt.md, patterns.md, peer.sh, agent-TEMPLATE.md
  ├── agents/              the three model-pinned agent definitions
  └── commands/            the /orchestrate slash command
.claude-plugin/          marketplace manifest (repo is its own marketplace → ./plugin)
docs/                    architecture and design-decision index
tests/                   fixtures, eval harness, and validation records (see tests/README.md)
vendor/fable-orchestrate pristine upstream snapshot (see its PROVENANCE.md; do not edit)
scripts/ + Makefile      installer + maintenance tooling — `make check` is the health gate
```

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the pieces fit; the
  seven load-bearing design decisions, each linked to its SKILL.md section
- [tests/README.md](tests/README.md) — the three test layers and how to run
  them; [tests/RUNBOOK.md](tests/RUNBOOK.md) — rerun procedures and the iron
  law (no skill edit ships without a scenario rerun)
- [CONTRIBUTING.md](CONTRIBUTING.md) — setup, `make check`, style,
  versioning; [CHANGELOG.md](CHANGELOG.md) — release history

Validation highlights: six TDD rounds, a real end-to-end field run whose
blind reviewer caught a defect the whole chain missed, and a quantified
benchmark (with-skill 100% vs baseline 58.3% — caveats in
[tests/evals/iteration-1/ANALYSIS.md](tests/evals/iteration-1/ANALYSIS.md)).
