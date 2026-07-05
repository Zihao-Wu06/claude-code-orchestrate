# orchestrate — a multi-model orchestration skill for Claude Code

[![ci](https://github.com/Zihao-Wu06/claude-code-orchestrate/actions/workflows/ci.yml/badge.svg)](https://github.com/Zihao-Wu06/claude-code-orchestrate/actions/workflows/ci.yml)
[![license: CC BY-NC 4.0](https://img.shields.io/badge/license-CC%20BY--NC%204.0-lightgrey.svg)](LICENSE)
[![plugin](https://img.shields.io/badge/claude%20code-plugin-blue.svg)](plugin/.claude-plugin/plugin.json)

The session's main model (intended: Fable 5) leads as **orchestrator** — planning,
decomposing, delegating, synthesizing — while the actual work routes to cheaper,
model-pinned executors:

| Executor | Model | Does |
|---|---|---|
| deep-reasoner | Opus | architecture, complex debugging, algorithm design, hard trade-offs |
| fast-worker | Sonnet | boilerplate, tests-from-spec, formatting, bulk edits |
| scout | Haiku, read-only | locating code, mapping structure, summarizing state |
| peer (Codex) | GPT-5, different vendor | fresh perspectives, disputed designs, parallel cross-checks |

## Contents

- [Install](#install)
- [Usage](#usage)
  - [Quick start](#quick-start)
  - [The `/orchestrate` command](#the-orchestrate-command)
  - [Modifiers](#modifiers)
  - [Budget modes](#budget-modes)
  - [The custom roster](#the-custom-roster)
  - [What you get back](#what-you-get-back)
  - [The Codex peer](#the-codex-peer-optional)
  - [Maintenance](#maintenance)
- [Features](#features)
- [Design and evaluation](#design-and-evaluation)
- [Layout](#layout) · [Documentation](#documentation) · [License](#license)

## License

[CC BY-NC 4.0](LICENSE) — noncommercial use, attribution required.

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
gives identical pinning. The Codex peer is **optional** — its on/off switch and
its unreachable-auto-off behavior are covered in
[The Codex peer](#the-codex-peer-optional) below.

## Usage

Two ways in — a slash command, or plain English:

```
/orchestrate [economic|thorough] [custom] <task…>
```

or just describe the job like a brief to a tech lead (goal, context,
constraints); the skill auto-activates on orchestration-shaped requests.
`/orchestrate` is the reliable entry point — the auto-trigger is best-effort.

### Quick start

```
/orchestrate Users report expenses dated the 1st get double-counted in the
monthly report. Fix it, extract the report logic into its own module, and add
tests. Repo: ~/work/expense-tracker.
```

The orchestrator **shows its plan first** — the decomposition and the tier
each piece routes to — then executes: scout maps the module → deep-reasoner
root-causes → fast-worker implements with a regression test → the build and a
blind reviewer verify. You read concise conclusions, never file dumps.

### The `/orchestrate` command

The command makes the session model a **thin orchestrator**: it plans and
reconciles but does not do the heavy lifting, routing each unit of work to the
cheapest capable executor. Routing is **first-match, top to bottom**:

| The task is… | Routes to |
|---|---|
| planning / synthesis, or a trivial one-liner | **the orchestrator itself** (delegating would cost more) |
| locate / map / inventory existing code | **scout** — Haiku, read-only |
| mechanical **and** fully specified (success is objectively checkable) | **fast-worker** — Sonnet |
| architecture / hard debugging / design / hard trade-off | **deep-reasoner** — Opus |
| high blast radius **and** hard to verify (both) | **deep-reasoner + Codex, blind & parallel** → orchestrator reconciles |
| novel problem, suspected blind spot, or you're looping | **Codex** peer |

You always see the plan before any delegation. If a large task *doesn't*
delegate, that's a bug — file it with the printed plan.

### Modifiers

Modifiers go before the task, in any order, and combine
(`/orchestrate economic custom …`):

| Modifier | What it does | Example |
|---|---|---|
| *(none)* | Standard routing. The blind cross-check fires only when a decision is both high-blast-radius and unverifiable. | `/orchestrate Add a --json flag to the export command and cover it with tests.` |
| `economic` | **Thrift mode** — routes borderline work down to Sonnet, disables the cross-vendor double-check (announced), runs the peer at `--effort medium`. Verification is never cut. | `/orchestrate economic Rename getUserByID to fetchUser across the repo; keep tests green.` |
| `thorough` | **Rigor mode** — routes borderline work up to Opus, allows two reconcile rounds, adds an adversarial *falsify* pass, and always adds a reviewer to implement work. | `/orchestrate thorough Design the shared log schema before migrating 40 services.` |
| `custom` | Pick which installed **roles** and **skills** to use this run (see [The custom roster](#the-custom-roster)). | `/orchestrate custom Audit the payment-v2 diff for security issues, then fix them.` |

### Budget modes

`economic` / default / `thorough` change **who** gets the work and **how much
verification runs** — never how hard any executor thinks. Every skip is
announced in the plan *and* the conclusion, so a thinned-out answer never
passes silently.

| Lever | `economic` | default | `thorough` |
|---|---|---|---|
| Blind parallel cross-check | **off** — deep-reasoner solo + Sonnet review + "human sign-off recommended" | fires on high-stakes **and** unverifiable | fires; 2 reconcile rounds before escalating |
| Borderline task (reasoning vs. mechanical) | routes **down** to Sonnet | judgment call | routes **up** to Opus |
| Codex signals | only "you're looping" | all seven | all seven + an adversarial falsify pass |
| Verification stage | **never cut** (reviewer pinned to Sonnet) | cheap check, else a reviewer | tests **and** a reviewer, always |
| Peer reasoning depth | `--effort medium` | default (`xhigh`) | `xhigh` |

**Thinking depth is not a budget lever.** The savings come from routing
borderline work down and cutting the redundant second channel — both
auditable, both announced — never from hobbling an executor.

### The custom roster

`custom` (or asking mid-run) lets you shape the roster *before* planning. It
takes two kinds of injectable — **roles** (who executes) and **skills** (how a
domain is worked):

1. The orchestrator enumerates the installed **roles** (agent types) and
   **skills** (reading only their frontmatter — never a body) and asks
   (multi-select) which to use this run.
2. A selected **role** slots into a tier — recon / mechanical / reasoning /
   peer — by its description and inherits that tier's rules. The routing table
   itself never changes; a role must pin a model to be admitted.
3. A selected **skill** is injected into the *matching* dispatch as its
   operating procedure — the executor whose task falls in the skill's domain
   is told *"Read this first — it is your operating procedure; follow it:
   `<path>/SKILL.md`."* Non-matching dispatches don't carry it, the
   orchestrator never reads the body, and every injection — or a selected
   skill that matched nothing — is announced.

**Author your own role:** copy `plugin/skills/orchestrate/agent-TEMPLATE.md`
to `~/.claude/agents/<name>.md`, fill the frontmatter (a `model:` pin is
**required**), pick a tier, and reload the session so the name resolves.

```
/orchestrate custom Review the payment-v2 diff for security issues, then fix them.
→ you select your `security-reviewer` role + an installed `sec-audit` skill
→ the audit dispatch runs security-reviewer, told to follow sec-audit as its
  procedure; the fix dispatch runs fast-worker with no skill attached (announced).
```

### What you get back

- **Plan first** — the decomposition and the tier for each piece, before any
  delegation.
- **Status tokens** — each executor's result opens with `DONE`,
  `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`. The orchestrator acts on
  the token: supplies context and retries on `NEEDS_CONTEXT`, climbs the
  escalation ladder on `BLOCKED`.
- **A decision brief instead of an answer** — when two blind models disagree
  after one reconcile round on a high-stakes call, you get four parts: the
  decision and why it went parallel, both positions at equal depth, the crux
  facts that would settle it, and the questions for you — with **no
  recommendation**. That is the designed outcome; the tie-breaking facts
  (roadmap, compliance, budget) are yours, not the models'.
- **Announcements** — in `economic` mode every skipped cross-check is stated in
  the plan and again in the conclusion.

### The Codex peer (optional)

The cross-vendor peer runs through the
[Codex CLI](https://github.com/openai/codex) — install it and run `codex login`
to enable it. It is entirely optional and has a hard, persistent switch:

```bash
peer.sh --status   # is the peer enabled? is the Codex CLI reachable?
peer.sh --off      # turn it off — persists across sessions and plugin updates
peer.sh --on       # turn it back on
```

`peer.sh` lives at `~/.claude/skills/orchestrate/peer.sh` after a manual
install, or beside `SKILL.md` in the plugin directory.

**Off by choice.** While off, every peer call refuses with **exit code 3**, the
skill announces the skip once, and any high-stakes decision falls back to its
economic-mode form (deep-reasoner alone + an independent review + a
human-sign-off note). The marker lives at `~/.claude/orchestrate.peer-off`,
deliberately *outside* the skill directory, so a plugin update or reinstall
can't silently switch it back on.

**Unreachable → auto-off.** If the Codex CLI was never installed, isn't on
`PATH`, or `codex login` has lapsed, the skill turns the peer off
*automatically* — the same graceful skip, announcement, and high-stakes
fallback, with no command to run. Unlike `--off`, this is automatic and
*transient*: nothing is persisted, so the peer resumes the instant Codex is
reachable again. `peer.sh --status` reports both signals — whether the switch
is on and whether the Codex CLI is on `PATH`.

The skill drives the peer automatically; to consult it directly:

```bash
# consult (default) — read-only: ask for a second approach or an independent check
peer.sh --mode consult -C "$PWD" --prompt "Will this sharding key hot-spot?"

# implement — workspace-write: let the peer edit files under -C
peer.sh --mode implement -C ./service --prompt "Apply the fix we discussed."
```

Every flag and its default (`--backend`, `--effort`, `--timeout`, `--out`, …)
is in [docs/USAGE.md](docs/USAGE.md).

### Maintenance

| Command | Effect |
|---|---|
| `make install` | install/refresh the skill, agents, and `/orchestrate` into `~/.claude` (self-checks placement, cleans up renamed agents) |
| `make check` | the health gate — shell syntax, shellcheck, manifest + version drift, CI YAML, file integrity, markdown links, and the `peer.sh` mock test |
| `make smoke-install` | install into a throwaway dir and assert placement, idempotence, and stale-agent cleanup |
| `make validate` | validate both plugin manifests against the official schema |
| `make bump-version V=x.y.z` | set the version in both manifests atomically |

Even more detail — every `peer.sh` flag and default, the full output shapes,
and troubleshooting — lives in [docs/USAGE.md](docs/USAGE.md).

## Features

A first-match routing table, executor-mixing patterns, a blind-parallel
high-stakes path, and a fragmentation/rubber-stamping guardrail form the core.
On top of that:

1. **scout role** (routing row 4) — read-only recon on Haiku so the
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
   only; summarizing the workflow there makes agents follow the description
   and skip the body.
6. **Tech-lead command** — `/orchestrate` bakes in the goal/context/plan-first
   briefing pattern; main model and effort are the user's session choice, never
   dictated by the skill.
7. **Budget modes** — `economic` / default / `thorough` adjust routing tendency
   and verification intensity, never silently (all skips announced) and never
   by reducing any executor's thinking depth.
8. **Escalation ladder** — fast-worker ×2 fail → deep-reasoner → (2 circling
   rounds) → Codex → human; never re-route a failed task down-tier.
9. **Generalized peer interface** — `peer.sh --backend codex` wraps the vendor
   CLI (one function per backend; add a vendor by adding a function), with
   `--effort` mapped to `model_reasoning_effort` and an `--off`/`--on` switch
   that makes the peer fully optional.
10. **Fan-out worktree isolation** — parallel workers that edit files get
    `Agent(isolation: "worktree")`; non-overlapping scope on paper doesn't
    prevent real file conflicts.
11. **Regression test suite** — `tests/` holds standalone pressure scenarios,
    a RUNBOOK, recorded baseline/with-skill results, and an end-to-end live
    eval; any behavioral edit requires a scenario rerun (the iron law).
12. **Optional custom roster — roles and skills** — the `custom` modifier
    enumerates installed agent roles *and* installed skills (frontmatter
    only) and asks (multiSelect) which to use this run. Selected roles slot
    into a tier (recon/mechanical/reasoning/peer) and inherit its rules;
    selected skills are injected per-dispatch by domain match — the matching
    executor reads the skill as its operating procedure while the
    orchestrator never reads the body, and every injection is announced. The
    routing table itself never changes. `agent-TEMPLATE.md` is the authoring
    guide for roles.

## Design and evaluation

*A short technical writeup of the skill's rationale, structure, and the
controlled experiments used to validate it. Operational reference:
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md); raw data: [`tests/`](tests/README.md).*

### 1. Problem and thesis

A single-agent coding assistant runs planning, reasoning, mechanical editing,
and reconciliation in one context on one model. Two costs follow. *(i)
Economic:* the strongest — and most expensive — model is spent uniformly,
including on boilerplate and file-reading where a cheaper model is
indistinguishable in outcome. *(ii) Epistemic:* a single model self-verifies,
so a confident error survives, because the model that made the mistake is the
one asked whether it is a mistake.

This skill makes the session model a **thin orchestrator** that plans and
reconciles but does not execute, and routes each unit of work to the cheapest
*model-pinned* executor able to do it, with a *different-vendor* peer reserved
for the class of decisions a single model cannot verify. The claim under test
is that this separation lowers cost and raises correctness discipline *without*
lowering solution quality.

### 2. Design principles

Seven principles, each paired with the failure it prevents and enforced at a
specific location in the skill (indexed in [ARCHITECTURE.md](docs/ARCHITECTURE.md)):

- **P1 — Separation of orchestration from execution.** The orchestrator plans,
  decomposes, and integrates; it never does the heavy lifting. *Prevents* the
  lead model becoming the most expensive executor by default.
- **P2 — First-match cost-tiered routing.** One ordered table maps each task to
  the cheapest capable tier; its second row returns trivial single-step work to
  the orchestrator itself, because briefing an executor then costs more than
  doing it. *Prevents* both under-delegation (everything on the expensive
  model) and over-delegation (ceremony for a one-line fix).
- **P3 — Context is the scarce resource.** Reads over ~100 lines go to a
  read-only recon tier; every delegation returns *conclusion + evidence ≤ 20
  lines* with `path:line` anchors; bulk moves as files, not pasted text.
  *Prevents* silent context exhaustion.
- **P4 — Decorrelated verification, not more horsepower.** The cross-vendor peer
  is chosen because its errors are *uncorrelated* with the primary model's, not
  because it is "better"; a second call to the same model resamples the same
  error confidently. Decisions that are both high-blast-radius *and* unverifiable
  run two models **blind and in parallel**, then reconcile. *Prevents* correlated
  single-model failure on the decisions most expensive to get wrong.
- **P5 — Budget modes change *who*, not *how hard*.** `economic`/`thorough` shift
  routing tendency and verification intensity; they never reduce any executor's
  thinking depth, and every skipped cross-check is announced. *Prevents* a
  thrift mode that silently degrades answers.
- **P6 — Contracts over verdicts.** Every delegation carries an explicit
  contract (goal, inputs, constraints, interface, acceptance check, return
  format) and must return a *checkable artifact* — a test that runs, a diff that
  applies, a cited line — never a bare "looks good". Implement-type work is
  re-checked by a fresh reviewer blind to the implementation. *Prevents*
  rubber-stamping.
- **P7 — Disagreement is a stop condition.** When the two parallel models
  disagree after one reconcile round, the orchestrator does not break the tie by
  fluency, confidence, or "industry-standard" prior; it escalates to the human
  with a four-part brief and no recommendation. *Prevents* the lightest model in
  the loop adjudicating a decision it cannot itself verify.

### 3. Structure

The skill is layered so that only the rule core loads on every invocation and
reference material loads on demand (progressive disclosure):

| Layer | Artifact | Loaded |
|---|---|---|
| Rule core | `SKILL.md` — routing table, cost policy, budget modes, escalation ladder, verification stage, reconcile rules | every invocation |
| Dispatch layer | `dispatch-prompt.md` — per-tier prompt skeletons, status vocabulary, worked example | when composing a delegation |
| Reference layer | `patterns.md` — seven executor-mixing patterns, per-signal peer guidance | on demand |
| Executors | `agents/{deep-reasoner,fast-worker,scout}.md` — one model pin each | on spawn |
| Peer | `peer.sh` — vendor-CLI wrapper, one backend function per vendor | on consult |

Four executor tiers (reasoning / Opus, mechanical / Sonnet, recon / Haiku, plus
the cross-vendor peer) and the orchestrator itself compose via the first-match
routing table. The full component map and the design-decision index are in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

### 4. Evaluation

Two complementary protocols were used: a **controlled ablation** isolating the
skill's effect on routing decisions, and **sandbox trials** exercising the whole
machinery end-to-end on real repositories.

#### 4.1 Controlled ablation (baseline vs. with-skill)

*Design.* Three adversarial scenarios were authored, each posing a routing
temptation with an objective PASS/FAIL rubric: **A**, a one-line typo fix
(temptation: over-delegate); **B**, two parallel models disagreeing on a schema
after one reconcile round with the user pressing for an answer (temptation:
break the tie by fluency); **C**, a 2,000-line refactor kickoff (temptation:
read every file into the orchestrator's own context). Each scenario ran in two
arms — *baseline* (a competent model, no skill) and *with-skill* (same model,
skill loaded) — under a structured eval harness, graded against
quoted-evidence assertions. Subjects ran on Sonnet, so the with-skill arm's
compliance *lower-bounds* a stronger orchestrator's.

*Results.*

| Configuration | Pass rate | Mean tokens | Mean wall-clock |
|---|---|---|---|
| With skill | **100 % ± 0 %** (11/11 assertions) | 47.6 k | 86.7 s |
| Baseline | **58.3 % ± 38 %** (across scenarios) | 35.2 k | 76.0 s |

The +0.42 pass-rate delta concentrates where routing discipline matters.
Scenario **A** did *not* discriminate (both arms 3/3): a competent model already
refuses to over-delegate a typo, so A is retained as a regression guard proving
the skill does not *induce* over-delegation. Scenario **C** discriminated most
(with-skill 4/4 vs. baseline 1/4): the clean baseline's second step was
literally "read all five files myself" — the exact context burn P3 targets.
Scenario **B** flipped FAIL→PASS: the baseline escalated but then declared a
default winner justified by an "industry-standard" prior, precisely the
tie-break P7 forbids.

The +12.5 k-token (≈ +35 %) with-skill overhead is almost entirely the one-time
cost of reading the skill inside a single-turn subagent; it amortizes across a
real multi-step session and is *not* the cost the skill targets (the
orchestrator's own context over a long task, which a single-turn trace cannot
measure). These evals measure *rule compliance*, not end-to-end economy.

A separate **trigger study** (12 should-not-trigger queries plus should-trigger
paraphrases) found perfect precision (0 false activations) but near-zero recall
in the isolated `claude -p` probe environment, where the model treats
orchestration prompts as directly doable and skips the skill; under real
conditions the description auto-activated (observed when an installed copy
contaminated a baseline run — a methodological accident that doubles as positive
triggering evidence). `/orchestrate` is therefore documented as the primary,
reliable entry point.

#### 4.2 Sandbox trials (end-to-end)

Two trials ran the full loop on generated repositories, since the ablation
grades decisions rather than execution.

**Field trial.** On a tangled expense-tracker with a planted month-boundary
double-count bug, the skill ran scout → deep-reasoner (design) → a genuine
cross-vendor design disagreement resolved in one reconcile round → fast-worker
(implementation, with a red-before/green-after regression proof) → a
verification stage. The verification stage's *blind reviewer* — an agent given
only the diff and the acceptance criteria — surfaced a latent per-category
rounding defect that both the designer and the implementer had carried over
unnoticed. This is epistemic cost *(ii)* of §1 caught in vivo.

**Live eval.** A fixture builder planted a week-boundary double-count bug and
disclosed only its user-visible *symptom*; a nested Sonnet orchestrator then
executed a fix *for real*, spawning its own executors. Graded against objective
assertions, Run 1 passed all four hard checks: the suite was green post-fix; a
new regression test was added; that test was independently confirmed to *fail on
the pre-fix source and pass after* (reproduced by the grader via source revert,
not merely reported); and the peer was correctly *not* consulted on a cheaply
verifiable task. The trial also surfaced a harness limitation
(background-subagent completion notifications are unreliable when the
orchestrator is itself a subagent), now documented and worked around at the eval
layer. Data: [`tests/evals/live/`](tests/evals/live/).

#### 4.3 Development discipline

The skill was built test-first: ten RED→GREEN→refactor rounds, in which every
edit to a behavioral file re-ran the three scenarios before shipping (the "iron
law"). Scenario B is the one case verified by a *failing* baseline — the fluency
tie-break was observed in the un-guarded model *before* the reconcile rules were
written, then shown to flip once they were. All ten rounds' verbatim
rationalizations and verdicts are in
[`tests/records/results.md`](tests/records/results.md).

#### 4.4 Threats to validity

Reported plainly, as the repository's own discipline demands. **Construct:** the
ablation grades stated routing decisions, not executed outcomes; the sandbox
trials cover execution but at *N* = 1 task each. **Statistical:** one repetition
per arm (a cost cap); single-rep results are re-run only when marginal, and none
here were. **Grader:** the ablation grader is the coordinator reading full
outputs, not blind — assertions are quoted-evidence-backed and independently
checkable, but an independent blind grader is future work. **Population:**
subjects ran on Sonnet, not the intended Fable-5 lead, i.e. a conservative
bound. **External:** trigger recall was measured in a probe environment that
under-activates skills; real-environment activation is evidenced only
incidentally. The ≥ 3-repetition, blind-graded live eval remains queued pending
a token budget.

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
scripts/ + Makefile      installer + maintenance tooling — `make check` is the health gate
```

## Documentation

- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — how the pieces fit; the
  seven load-bearing design decisions, each linked to its SKILL.md section
- [docs/USAGE.md](docs/USAGE.md) — the full usage reference: every
  `/orchestrate` modifier and its effect, the routing tiers, output shapes,
  the `peer.sh` CLI, `make` targets, and troubleshooting
- [tests/README.md](tests/README.md) — the three test layers and how to run
  them; [tests/RUNBOOK.md](tests/RUNBOOK.md) — rerun procedures and the iron
  law (no skill edit ships without a scenario rerun)
- [CONTRIBUTING.md](CONTRIBUTING.md) — setup, `make check`, style,
  versioning; [CHANGELOG.md](CHANGELOG.md) — release history

The **Design and evaluation** section above is the writeup; the raw data and
full caveats live in [`tests/`](tests/README.md) and
[tests/evals/iteration-1/ANALYSIS.md](tests/evals/iteration-1/ANALYSIS.md).
