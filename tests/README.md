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
- `evals/iteration-1/` — the committed summary: `benchmark.{json,md}`
  (aggregate numbers) and `ANALYSIS.md` (caveats and incidents — read this
  before quoting the numbers)

Built on the official skill-creator harness; rerun procedure is in
RUNBOOK.md. Raw run data (per-case `answer.md`, `grading.json`,
`timing.json`, trigger-results) and generated artifacts (`review.html`,
`*.log`) are **not committed** — reruns regenerate them locally
(gitignored), and the iteration-1 originals are preserved verbatim in git
history at commit `7767a0d`.

## 3. Records — what actually happened

- `records/results.md` — every TDD round (RED baseline → GREEN → refactor
  loops), with verbatim rationalizations and verdicts
- `records/field-run-1.md` — the first real end-to-end orchestration: delegation log,
  a genuine cross-vendor design disagreement resolved in one reconcile round,
  the blind reviewer catching a latent defect, and the friction list (F1–F3)
  that fed fixes back into the skill

These are documentation of how the skill was validated, kept in-repo on
purpose (they are cited by commits, ANALYSIS.md, and the RUNBOOK).
