# Test RUNBOOK — orchestrate skill

Regression tests for `skills/orchestrate/SKILL.md`, following the superpowers
`writing-skills` TDD methodology: every scenario must FAIL without the skill
(baseline / RED) and PASS with it (GREEN). **Any edit to SKILL.md requires
rerunning all three scenarios** — the iron law applies to edits, not just
creation.

## Preferred: the eval suite (quantified, one command per stage)

`evals/` holds the structured version of these scenarios (assertions in
`evals/evals.json`, per-case metadata under `evals/iteration-N/eval-*/`),
built with the official skill-creator harness. To rerun after a skill edit:

1. Spawn the six runs (3 evals × with_skill/without_skill) as one-shot
   `general-purpose` sonnet subagents — prompts are the scenario PROMPT
   sections; the with-skill arm prepends the "Read SKILL.md +
   dispatch-prompt.md first" preamble; each run writes `answer.md` into
   `evals/iteration-N/eval-<id>-<name>/<config>/run-1/outputs/` and its
   notification's tokens/duration go into `timing.json` beside it.
   **Baseline caveat (learned the hard way):** if the skill is installed in
   `~/.claude/skills/`, park it elsewhere for the baseline runs — installed
   skills auto-trigger and contaminate the without_skill arm.
2. Grade each run against the assertions → `grading.json` with
   `expectations: [{text, passed, evidence}]` **and a `summary`
   {total, passed, failed, pass_rate}** (the aggregator reads summary).
3. Aggregate + render (from the skill-creator directory):
   ```bash
   python3 -m scripts.aggregate_benchmark <repo>/tests/evals/iteration-N --skill-name orchestrate
   python3 eval-viewer/generate_review.py <repo>/tests/evals/iteration-N \
     --skill-name orchestrate --benchmark .../benchmark.json --static .../review.html
   ```
4. Trigger tests: `python3 -m scripts.run_eval --eval-set tests/evals/trigger-eval.json
   --skill-path skills/orchestrate --runs-per-query 3 …` — use ≥3 reps
   (1-rep trigger results are noise; proven in iteration-1) and read
   `evals/iteration-1/ANALYSIS.md` for how to interpret probe-environment
   recall vs real-environment triggering.

Iteration-1 results: with_skill 100% vs baseline 58.3% (delta +0.42);
full numbers in `evals/iteration-1/benchmark.md`, caveats in
`evals/iteration-1/ANALYSIS.md`. The browsable run-by-run viewer
(`review.html`) is a generated artifact and is NOT committed — regenerate it
with the `generate_review.py --static` command from step 3 (or `make
eval-view` for the exact invocation).

## Fallback: the manual three-scenario procedure (original method)

## How to run

Each scenario file in `scenarios/` contains a `## PROMPT` section. Run each
scenario as a one-shot subagent with a fresh context:

- **Baseline (RED):** `Agent(subagent_type: "general-purpose", model: "sonnet",
  prompt: <PROMPT text verbatim>)`
- **With skill (GREEN):** same call, but prepend to the prompt:

  ```
  You have loaded the following skill and must operate by it:
  <full text of skills/orchestrate/SKILL.md>
  ---
  ```

Run the three scenarios in parallel (one message, three Agent calls). The
subagent is asked to *describe* its exact next tool calls, not execute them —
we are grading the routing decision, not the work.

## Grading

Grade only against the PASS/FAIL criteria in each scenario file. Read the
full response; record verbatim the sentences where the agent justifies its
choice (these are the rationalizations that skill wording must counter).
Record every run in `results.md` with: date, scenario, arm (baseline/skill),
PASS/FAIL, and the verbatim justification.

## Known limitations

- Test subjects run on Sonnet, not Fable — we are testing whether the skill
  *wording* binds a competent orchestrator model; stronger models comply at
  least as well (weaker instruction-following is the harder case).
- Single rep per arm per edit round. If a result looks marginal, rerun that
  scenario 2–3 more times before concluding (variance is a metric).
- These are decision-trace tests, not full pressure scenarios with real tool
  execution. They verify routing/wording, not end-to-end behavior.
