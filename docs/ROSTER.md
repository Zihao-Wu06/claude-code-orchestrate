# Roster

Who executes what, and when *not* to reach for them. The behavioral source of
truth is always
[plugin/skills/orchestrate/SKILL.md](../plugin/skills/orchestrate/SKILL.md) —
this page is the operator-facing matrix, not the law.

## Default roster

| Role | Model | Serves routing row(s) | Typical dispatch | When NOT to use it |
|---|---|---|---|---|
| **orchestrator** (you) | session model | 1, 2, 8 — planning, trivial one-liners, leftovers | decompose the task, reconcile executor output, integrate and run the real build/tests | never delegate the orchestration itself — that's the one thing this role can't hand off |
| **deep-reasoner** | Opus | 3 (half the parallel path), 6 | architecture, complex/multi-file debugging, algorithm design, hard trade-offs, genuine design ambiguity | a fact only the user or the repo can supply (vendor choice, current state) — that's the ambiguity gate's job, not a reasoning model's guess |
| **fast-worker** | Sonnet | 5 | boilerplate, tests-from-spec, formatting, simple edits, renames, bulk transforms — fully specified, objectively checkable | a real design decision is still open — it returns `NEEDS_CONTEXT` rather than guessing, but don't dispatch it there to begin with |
| **scout** | Haiku, read-only | 4 | locate code, map structure, inventory symbols/call sites, summarize current state | anything needing judgment or a fix — it collects, it does not decide |
| **Codex peer** | GPT-5, different vendor | 3 (other half of the parallel path), 7 | fresh-perspective or decorrelated second opinion; blind parallel cross-check on high-stakes-and-unverifiable calls; adversarial falsify pass | cheaply verifiable work (just verify it), mechanical/trivial work, or deep in-repo context Codex would have to re-acquire from scratch |

Routing-row numbers refer to the first-match table in SKILL.md § Routing rule.

## Verification tiers

Mirrors SKILL.md § Verification stage — reviewer tier is calibrated by change
surface × risk domain, and is never waived by green tests on a risk-domain
diff:

| Change surface × risk domain | Reviewer |
|---|---|
| Cheaply verifiable, no risk-domain touch, below the size line | none by default — the orchestrator runs the check itself |
| Not cheaply verifiable, no risk-domain touch, below the size line | blind reviewer, Sonnet tier — diff + acceptance criteria only |
| Large (≈>20 files), **or** any risk-domain touch (security/auth, data-loss, concurrency, crypto, public API) | blind reviewer, **Opus tier, security/correctness focus** — even with green tests |

On a risk-domain diff, default mode's floor is **one** blind Opus reviewer; a
second, adversarial Codex reviewer is thorough mode's falsify pass, or fires
on an explicit Codex signal — never by default. Every reviewer returns a
defect list (`path:line` + why it's wrong) plus an explicit answer to *is
there a meaningfully simpler or safer approach?*, scoped to the changed code
and its callers/callees — never an approve/reject verdict.

## Custom roster admission rules

From SKILL.md § Custom roster (`custom` modifier):

- **A pinned model is required.** A role whose definition doesn't pin exactly
  one of `opus | sonnet | haiku` is not admitted to the roster — pinning is
  what keeps spend predictable.
- **Tier slotting by description.** A selected role slots into one of four
  tiers — recon / mechanical / reasoning / peer — by its description, and
  inherits that tier's routing row, cost rules, and ≤20-line return
  contract. The routing table itself never changes.
- **Skill injection is per-dispatch and announced.** A selected skill is
  injected only into the dispatch whose task matches its described domain
  (added to that dispatch's Inputs as its operating procedure); the
  orchestrator matches on the frontmatter description alone and never reads
  the skill body. Every injection is announced in the plan, and a selected
  skill that matched no dispatch is announced rather than silently dropped.
- **Tier contract wins.** An injected skill never overrides the tier's own
  rules — status-first return, the return cap, scout's read-only bound. If a
  skill's procedure needs what the tier forbids, the orchestrator announces
  the conflict and routes per the table instead of injecting.

## Authoring a custom role

Copy
[`plugin/skills/orchestrate/agent-TEMPLATE.md`](../plugin/skills/orchestrate/agent-TEMPLATE.md)
to `~/.claude/agents/<name>.md`, fill the frontmatter (a `model:` pin is
required), pick a tier from the table above, and reload the session so the
name resolves. See [docs/USAGE.md](USAGE.md) for how a custom role is
selected at runtime via the `custom` modifier.
