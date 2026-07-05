# Test RUNBOOK — orchestrate skill

Regression tests for `skills/orchestrate/SKILL.md`, following the superpowers
`writing-skills` TDD methodology: every scenario must FAIL without the skill
(baseline / RED) and PASS with it (GREEN). **Any edit to SKILL.md requires
rerunning all three scenarios** — the iron law applies to edits, not just
creation.

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
