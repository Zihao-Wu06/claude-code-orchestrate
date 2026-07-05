# Using /orchestrate — worked examples

`/orchestrate` is the primary entry point (auto-triggering exists but the
command is the reliable path — see the eval analysis). Exact modifier
semantics live in SKILL.md's **Budget modes** and **Custom roster** sections;
this page is about *when* to reach for what.

## Which modifier, when

| You want | Use | Rough shape of the run |
|---|---|---|
| Normal work, sensible spend | *(no modifier)* | full routing table; parallel cross-check only when a decision is both high-blast-radius AND unverifiable |
| Minimum expensive-model spend, accept a retry risk | `cheap` | borderline work tries Sonnet first; the two-model cross-check is skipped **and announced** — read those announcements before trusting high-stakes conclusions |
| A decision you must not get wrong | `thorough` | borderline work goes straight to Opus; high-stakes conclusions get an adversarial falsify pass |
| Non-default team for this run | `custom` | you pick the roster from installed agents before planning |

Modifiers combine: `/orchestrate cheap custom fix the flaky retry test…`.

## Examples

**Bug fix + extraction, default mode:**

```
/orchestrate Users report expenses dated the 1st get double-counted in the
monthly report. Fix it, extract the report logic into its own module, and
add tests. Repo: ~/work/expense-tracker.
```

Expected flow: plan shown first → scout inventories the module → deep-reasoner
root-causes and freezes the interface → fast-worker implements with a
regression-proof step → tests run + a blind reviewer returns a defect list.
(This exact flow is documented from a real run in tests/records/field-run-1.md.)

**Large migration, rigor mode:**

```
/orchestrate thorough Migrate all 40 services from log4j-style logging to
structlog. Design the shared schema first; nothing moves until it's frozen.
```

Expected: schema design lands on deep-reasoner with a Codex falsify pass;
mechanical per-service edits fan out to parallel fast-workers in worktrees;
you get build+test results, not "done" claims.

**Quick sweep, thrift mode:**

```
/orchestrate cheap Rename `getUserByID` to `fetchUser` across the repo and
fix all call sites. Tests must stay green.
```

Expected: scout maps call sites, fast-worker executes, tests verify — no
Opus, no Codex, skips announced if any high-stakes fork appears.

**Custom roster:**

```
/orchestrate custom Review this PR for security issues, then fix what's found.
```

Expected: you're asked which installed roles to use (e.g. swap in your own
`security-reviewer` agent); selected roles inherit the tier rules — see
`plugin/skills/orchestrate/agent-TEMPLATE.md` to author one.

## When things look wrong

- **"peer degraded: codex CLI not on PATH / run codex login"** — the Codex
  routing rows are skipped (announced, everything else works). Install the
  [Codex CLI](https://github.com/openai/codex) and `codex login` to enable
  them.
- **`deep-reasoner`/`fast-worker`/`scout` "unknown agent type"** — named
  agents resolve after a session reload. Until then the skill's fallback is
  equivalent: `Agent(subagent_type: "general-purpose", model: "opus" |
  "sonnet" | "haiku")` with the role preamble from dispatch-prompt.md.
- **A high-stakes decision came back as a brief with questions instead of an
  answer** — that's by design, not a failure: after a blind parallel run and
  one reconcile round, genuine disagreement escalates to you with the crux
  facts only you hold (see SKILL.md, the high-stakes parallel path).
- **Everything routed to the orchestrator itself** — trivial single-step
  tasks are *supposed* to skip delegation (routing row 2); if a big task did
  this, file a bug with the plan it printed.
