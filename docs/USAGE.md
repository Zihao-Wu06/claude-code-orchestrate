# Usage guide

Everything you can do with the skill and what each thing produces. For the
authoritative rule semantics see
[`SKILL.md`](../plugin/skills/orchestrate/SKILL.md); this page is the operator's
reference. There are four surfaces:

- **`/orchestrate`** — the command you run in a Claude Code session (primary).
- **A plain tech-lead brief** — describe the goal and let the skill auto-route.
- **`peer.sh`** — the cross-vendor peer CLI (usually driven by the skill; you
  use it directly to switch the peer on or off).
- **`make` targets** — install and maintain the plugin.

---

## 1. The `/orchestrate` command

```
/orchestrate [economic|thorough] [custom] <task…>
```

Describe the task like a brief to a tech lead — goal, context, constraints. The
orchestrator **shows its plan first** (its decomposition and the tier each piece
routes to), then executes. You can also skip the command and just write the
brief; the skill auto-activates on orchestration-shaped requests, but the
command is the reliable entry point.

### What routes where, and what you get back

The session's lead model stays a thin orchestrator; work routes to the cheapest
capable executor.

| Tier | Model | Handles | Returns |
|---|---|---|---|
| orchestrator (you) | session model | planning, decomposition, integration, reconciliation | the plan and the synthesis |
| scout | Haiku, read-only | locate / map / inventory code | a ≤20-line `path:line` digest |
| fast-worker | Sonnet | mechanical, fully-specified work | the artifact + acceptance-check result |
| deep-reasoner | Opus | architecture, hard debugging, design | a conclusion + a checkable artifact + a "what would make this wrong" note |
| peer (Codex) | GPT-5, different vendor | a decorrelated second opinion; blind cross-checks | an independent answer |

Routing is **first-match**: trivial single-step work the orchestrator just does
itself (delegating would cost more than doing it); recon goes to scout;
fully-specified mechanical work to fast-worker; reasoning to deep-reasoner; a
decision that is *both* high-blast-radius *and* unverifiable runs deep-reasoner
and Codex **blind, in parallel**, then the orchestrator reconciles.

### Modifiers and their effects

Modifiers go before the task, in any order, and combine
(`/orchestrate economic custom …`).

| Modifier | Effect |
|---|---|
| *(no modifier)* | Standard routing — the default. The two-model parallel cross-check fires only when a decision is both high-blast-radius and unverifiable. Verification runs the cheap check if one exists, else a blind reviewer. |
| `economic` | Lowest expensive-model spend, at some retry risk. Borderline work tries Sonnet first (ladders up on failure); the parallel cross-check is **disabled** (deep-reasoner alone + a Sonnet review, with *"human sign-off recommended"* announced); Codex fires only when the orchestrator is looping (other signals are announced and skipped); the peer runs at `--effort medium`. **Verification is never cut.** Every skip is announced in the plan and the conclusion. |
| `thorough` | Maximum rigor. Borderline work goes straight to Opus; the parallel path allows two reconcile rounds before escalating; high-stakes conclusions get an adversarial *falsify* pass; implement-type work always gets a reviewer (tests **and** a reviewer). |
| `custom` | Before planning, you're asked (multi-select) which installed agent **roles** and which installed **skills** to use this run. A selected role slots into a tier — recon / mechanical / reasoning / peer — by its description and inherits that tier's rules. A selected skill is **injected per-dispatch by domain match**: the executor whose task falls in the skill's described domain is told to read that `SKILL.md` first and follow it as its operating procedure — the orchestrator matches on the frontmatter description alone (it never reads the body), the tier's contract still binds, every injection is announced, and a selected skill that matched no dispatch is announced rather than silently dropped. The routing table itself is unchanged. Author your own role with `plugin/skills/orchestrate/agent-TEMPLATE.md`. |

**Budget modes never reduce how hard any executor thinks** — they change *who*
gets the work and how much verification runs, never the assignee's reasoning
depth. The only depth knob is the peer's `--effort`, which `economic` lowers.

### Worked examples

**Bug fix + extraction, default mode:**

```
/orchestrate Users report expenses dated the 1st get double-counted in the
monthly report. Fix it, extract the report logic into its own module, and
add tests. Repo: ~/work/expense-tracker.
```

Expected flow: plan shown first → scout inventories the module → deep-reasoner
root-causes and freezes the interface → fast-worker implements with a
regression-proof step → tests run + a blind reviewer returns a defect list.
(Documented from a real run in `tests/records/field-run-1.md`.)

**Large migration, rigor mode:**

```
/orchestrate thorough Migrate all 40 services from log4j-style logging to
structlog. Design the shared schema first; nothing moves until it's frozen.
```

Expected: schema design lands on deep-reasoner with a Codex falsify pass;
mechanical per-service edits fan out to parallel fast-workers in worktrees; you
get build+test results, not "done" claims.

**Quick sweep, thrift mode:**

```
/orchestrate economic Rename `getUserByID` to `fetchUser` across the repo and
fix all call sites. Tests must stay green.
```

Expected: scout maps call sites, fast-worker executes, tests verify — no Opus,
no Codex; any high-stakes fork is announced-and-skipped.

**Custom roster:**

```
/orchestrate custom Review this PR for security issues, then fix what's found.
```

Expected: you're asked which installed roles *and skills* to use (e.g. swap
in your own `security-reviewer` agent, or inject an installed `sec-audit`
skill). Selected roles inherit the tier rules; a selected skill lands only on
the dispatch it matches — here the review dispatch would open with *"Read
this first — it is your operating procedure; follow it:
~/.claude/skills/sec-audit/SKILL.md"*, while the fix dispatches carry nothing
extra.

### What the output looks like

- **Plan first.** Before any delegation you see the decomposition and the tier
  for each piece. If a large task did *not* delegate, that's a bug — file it
  with the printed plan.
- **Status tokens.** Each executor's result opens with `DONE`,
  `DONE_WITH_CONCERNS`, `NEEDS_CONTEXT`, or `BLOCKED`. The orchestrator acts on
  the token: supply context and retry on `NEEDS_CONTEXT`; climb the escalation
  ladder on `BLOCKED`.
- **A decision brief instead of an answer.** On a high-stakes decision where the
  two blind models disagree after one reconcile round, you get a four-part brief
  — the decision and why it went parallel, both positions at comparable depth,
  the crux facts and what would settle each, and the questions for you — with
  **no recommendation**. That is the designed outcome, not a failure: the facts
  that break the tie (roadmap, compliance, budget) are yours, not the models'.
- **Announcements.** In `economic` mode, every skipped cross-check is stated in the
  plan and again in the conclusion, so a thinned-out high-stakes answer never
  passes silently.

---

## 2. The peer (Codex) — `peer.sh`

The cross-vendor peer is a *decorrelated second prior*: a different vendor's
model whose errors are uncorrelated with the primary's. The skill drives it
automatically; you use it directly mainly to switch it on or off. It lives at
`plugin/skills/orchestrate/peer.sh` (or `~/.claude/skills/orchestrate/peer.sh`
once installed).

### Turn it on or off (persistent)

```bash
peer.sh --status     # is the peer enabled? is the codex CLI on PATH?
peer.sh --off        # disable the peer entirely (persists across sessions and updates)
peer.sh --on         # re-enable
```

While off, every peer call refuses with **exit code 3**, the skill announces the
degradation, and a high-stakes decision falls back to its `economic`-mode form
(deep-reasoner alone + independent review + a human-sign-off note). The marker
lives at `$CLAUDE_DIR/orchestrate.peer-off` (default `~/.claude/…`), deliberately
outside the plugin dir so an update or reinstall can't silently re-enable it.

### Consult vs. implement

```bash
# consult (default): read-only — ask for a second approach or an independent check
peer.sh --mode consult -C "$PWD" --prompt "Will this sharding key hot-spot?"

# implement: workspace-write — let the peer edit files under -C
peer.sh --mode implement -C ./service --prompt "Apply the fix we discussed."
```

### All flags

| Flag | Effect | Default |
|---|---|---|
| `--backend NAME` | which vendor CLI to drive | `codex` |
| `--mode consult\|implement` | read-only vs workspace-write | `consult` |
| `-C DIR` | working directory the peer sees | `$PWD` |
| `--effort low\|medium\|high\|xhigh` | peer reasoning depth | backend default (codex: `xhigh`) |
| `--timeout SEC` | hard-kill the peer after SEC seconds | `600` |
| `--out FILE` | also tee output to FILE (for background reads) | — |
| `--prompt TEXT` / `--prompt-file P` / `-` | the prompt (argument / file / stdin) | required |

Exit codes: `0` success, `2` usage error, `3` disabled by the switch. Add a
vendor by writing one `backend_<name>()` function in `peer.sh`. The Codex
backend needs the [Codex CLI](https://github.com/openai/codex) installed and
`codex login` done; without it, `--status` says so and the skill skips the Codex
rows.

---

## 3. Maintenance — `make`

| Command | Effect |
|---|---|
| `make install` | install/refresh the skill, agents, and `/orchestrate` into `~/.claude` (manual mode; cleans up renamed agents, then self-checks placement) |
| `make check` | the health gate: shell syntax, shellcheck, manifest JSON + version-drift, CI YAML, file integrity, markdown links, and the `peer.sh` mock test |
| `make smoke-install` | install into a throwaway dir and assert placement, idempotence, and stale-agent cleanup |
| `make validate` | validate both plugin manifests against the official schema |
| `make bump-version V=x.y.z` | set the version in both manifests atomically |
| `make eval-view` | print the command to regenerate the eval review viewer |

---

## 4. Install (recap)

**Plugin (recommended):**

```bash
claude plugin marketplace add Zihao-Wu06/claude-code-orchestrate
claude plugin install orchestrate@claude-code-orchestrate
```

**Manual:** `make install`. Named agents (`deep-reasoner`, `fast-worker`,
`scout`) resolve after a session reload; until then the skill uses the
equivalent `Agent(subagent_type: "general-purpose", model: "opus" | "sonnet" |
"haiku")` fallback with the role preamble from `dispatch-prompt.md`.

---

## When things look wrong

- **`peer: disabled by …orchestrate.peer-off` (exit 3)** — the peer was switched
  off on purpose (`peer.sh --off`); not an error. `peer.sh --on` re-enables it.
- **`peer degraded: codex CLI not on PATH` / `run codex login`** — the Codex
  routing rows are skipped (announced; everything else works). Install the
  [Codex CLI](https://github.com/openai/codex) and run `codex login` to enable
  them.
- **`deep-reasoner` / `fast-worker` / `scout` "unknown agent type"** — named
  agents resolve after a session reload. Until then the skill's fallback is
  equivalent: `Agent(subagent_type: "general-purpose", model: "opus" | "sonnet"
  | "haiku")` with the role preamble from `dispatch-prompt.md`.
- **A high-stakes decision came back as a brief with questions, not an answer**
  — by design, not a failure: after a blind parallel run and one reconcile
  round, genuine disagreement escalates to you with the crux facts only you
  hold (see `SKILL.md`, the high-stakes parallel path).
- **Running the orchestrator itself as a subagent (nested)?** Dispatch your
  executors in the foreground — background-subagent completion notifications are
  not reliably delivered one nesting level down, so a background wait can hang
  forever. The skill's background guidance assumes a top-level session.
- **A large task did everything itself without delegating** — trivial
  single-step tasks are *supposed* to skip delegation (routing row 2); if a big
  task did this, file a bug with the plan it printed.
