# tests/ — what lives here and how to run it

This directory holds three distinct kinds of content (pattern borrowed from
[obra/superpowers](https://github.com/obra/superpowers)' `docs/testing.md`
two-way split between deterministic tests and LLM-behavior evals):

## 1. Behavior scenarios — the fixtures

- `scenarios/A-trivial.md` — over-delegation temptation (routing row 2)
- `scenarios/B-conflict.md` — fluency tie-break temptation (parallel-path
  reconcile rules)
- `scenarios/C-recon.md` — context-burn temptation (cost policy, dispatch
  skeleton, fallback role preamble)

Each file is a standalone pressure prompt with PASS/FAIL criteria. They are
the **inputs** to both harnesses below. The methodology (baseline vs
with-skill, grading rules, the iron law that any skill edit requires a
rerun) lives in [RUNBOOK.md](RUNBOOK.md).

## 2. Quantified eval harness — the numbers

- `evals/evals.json` — the scenarios as structured eval cases with assertions
- `evals/trigger-eval.json` — should-trigger / should-not-trigger queries for
  the frontmatter description
- `evals/iteration-1/` — recorded runs: per-case `answer.md` (evidence),
  `grading.json` (assertion verdicts with quotes), `timing.json`,
  `benchmark.{json,md}` (aggregate), `ANALYSIS.md` (caveats and incidents —
  read this before quoting the numbers)

Built on the official skill-creator harness; rerun procedure is in
RUNBOOK.md. Generated artifacts (`review.html`, `*.log`) are not committed —
regenerate on demand (`make eval-view` prints the command).

## 3. Records — what actually happened

- `results.md` — every TDD round (RED baseline → GREEN → refactor loops),
  Rounds 1–6, with verbatim rationalizations and verdicts
- `field-run-1.md` — the first real end-to-end orchestration: delegation log,
  a genuine cross-vendor design disagreement resolved in one reconcile round,
  the blind reviewer catching a latent defect, and the friction list (F1–F3)
  that fed fixes back into the skill

These are documentation of how the skill was validated, kept in-repo on
purpose (they are cited by commits, ANALYSIS.md, and the RUNBOOK).
