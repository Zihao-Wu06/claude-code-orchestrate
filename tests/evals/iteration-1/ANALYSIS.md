# Iteration 1 — analyst notes

## Headline numbers (benchmark.json)

| Config | Pass rate | Mean tokens | Mean time |
|---|---|---|---|
| with_skill | **100%** (11/11 assertions) | ~47.6k | ~86.7s |
| without_skill | **58.3%** (7/12 weighted; 6/11 raw assertions) | ~35.2k | ~76.0s |

Delta: **+41.7 points pass rate**, at ~+12k tokens per one-shot run.

## What discriminates and what doesn't

- **eval-0 trivial-solo-routing does NOT discriminate** (both arms 3/3). Sonnet
  already refuses to over-delegate a typo fix without the skill. Kept as a
  regression guard: it proves the skill doesn't *induce* over-delegation
  (an easy failure for orchestration skills that push delegation hard).
- **eval-1 conflict-escalation discriminates on the two load-bearing rules**:
  baseline escalated with questions (2/4) but still declared a default via an
  industry prior ("more common industry-default for SaaS billing"); with-skill
  refused any fifth part (4/4).
- **eval-2 recon-context-policy discriminates hardest** (1/4 → 4/4): the clean
  baseline's step 2 was literally "I read all five files myself, in full" —
  the exact context burn the cost policy targets — and it kept the design
  call for itself; with-skill dispatched scout first and reserved design for
  the reasoning tier.

## Token/time caveat (read before quoting the numbers)

The +12k-token with-skill overhead is almost entirely the one-time Read of
SKILL.md + dispatch-prompt.md inside a one-shot subagent. In a real session
the skill loads once and amortizes across the whole task; and the savings the
skill actually targets — the orchestrator's own context over a long
multi-file task — are not measurable in a single-turn decision-trace eval.
These evals measure rule compliance, not end-to-end cost. See
tests/field-run-1.md for in-vivo behavior.

## Incident: baseline contamination (methodology note)

The first eval-2 without_skill run auto-triggered the *globally installed*
copy of the skill (it appears in every subagent's available-skills list) and
reproduced routing-table vocabulary verbatim. The run was discarded; the
baseline was rerun with the installed skill temporarily parked outside
~/.claude/skills. Two implications, honestly stated: (1) "baseline" on a
machine with the skill installed is not reachable for orchestration-flavored
prompts — the description auto-triggers; (2) that contamination is itself
positive triggering evidence under real conditions.

## Trigger tests (description validation)

- **Precision: perfect across all rounds** — 4/4 should-NOT-trigger queries
  never triggered (12 total negative samples, 0 false positives).
- **Recall in the `claude -p` probe environment: ~0** (v1: 1/4 at 1 rep;
  v2 pushier description: 1/4 at 1 rep, 0/4 at 3 reps — the v1 "pass" was
  sampling noise). Interpretation: probe sessions lack the installed agent
  roster and treat orchestration prompts as directly doable, so they don't
  consult the skill (skill-creator docs: models only consult skills for work
  they can't handle directly).
- **Real-environment counter-evidence:** the contamination incident above IS
  an observed auto-trigger under real conditions, same day, same description
  family.
- Verdict: keep the v2 (pushier, still trigger-conditions-only) description;
  primary invocation channel remains the /orchestrate command; a full
  run_loop description optimization (3 reps × 5 iterations) is queued as
  future work rather than burned here.

## Bench hygiene

- Single rep per arm (by design, cost cap). Marginal-looking results should
  be rerun 2-3× before concluding — none were marginal this round.
- Grader = the session orchestrator reading full outputs (not blind). The
  assertions are quoted-evidence-backed and checkable by any reader from the
  saved answer.md files; a fully independent grader pass is a future-work
  upgrade.
