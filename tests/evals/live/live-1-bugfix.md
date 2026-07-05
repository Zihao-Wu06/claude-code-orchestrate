# Live eval 1 — end-to-end bugfix orchestration

Unlike the decision-trace scenarios (`tests/scenarios/`), this eval runs the
skill **for real**: the subject is an orchestrator agent with genuine tool
access that must spawn actual subagents, run actual tests, and produce an
actual fix in a sandbox repo. It measures end-to-end behavior, not stated
plans. v1 scope: 1 case × 1 rep, orchestrator-graded objective assertions
(the ≥3-rep + independent blind-grader upgrade remains in the backlog).

## Fixture

A fresh sandbox is generated per run by a fast-worker from a fixed spec
(compact Python booking module, stdlib-only, one deliberately planted
week-boundary bug in `weekly_report`, passing tests that deliberately do NOT
cover it). The builder reveals only the user-visible SYMPTOM to the runner —
never the mechanism — so the subject's diagnosis is genuinely blind.

## Subject

One `Agent(subagent_type: "claude", model: "sonnet")` — full tools including
Agent, so it can spawn its own executors (named agents if installed, else
the fallback path). Prompt shape:

1. Read `plugin/skills/orchestrate/SKILL.md` + `dispatch-prompt.md` in full
   and operate strictly by them.
2. The task, phrased as a user report: the SYMPTOM (from the builder), the
   sandbox path, and "fix it and add a regression test; default mode".
3. EXECUTE for real (not a plan). On completion return a structured
   self-report: each delegation (role, one-line task, the first line of its
   return — the status token), the acceptance command output tail, the fix
   commit SHA, and whether any peer/codex call was made.
4. **Foreground dispatches only** (harness constraint from Run 1's F-LIVE-1:
   background-subagent completion notifications are not reliably delivered
   to a nested orchestrator — a background wait hangs the subject forever).
   This overrides the skill's background guidance for the eval environment
   only.

## Objective assertions (graded against the sandbox + self-report)

| # | Assertion | Checked how |
|---|---|---|
| A1 | Full test suite passes post-fix | grader runs `python3 -m unittest discover tests` |
| A2 | A new regression test exists targeting the reported symptom | grader reads the new test |
| A3 | The regression test fails on the pre-fix code | grader reverts the fix commit's source change (or flips the fixed comparison) and runs that test |
| A4 | ≥2 real delegations, each return opening with a status token | subject self-report excerpts |
| A5 | Recon output was `path:line`-anchored | self-report excerpt of the scout return |
| A6 | No peer/codex use (task is cheaply verifiable — the skill says don't) | self-report + no codex artifacts in sandbox |
| A7 | Orchestrator did not bulk-read the source itself (cost policy) | self-report attestation — soft in v1, hardened by transcript audit in the blind-grader upgrade |
| A8 | Fix is committed in the sandbox repo | `git log` in sandbox |

Pass bar: A1–A4 and A8 hard-required; A5–A7 recorded (soft in v1).

## Runbook

1. Spawn the fixture builder (spec above; symptom-only disclosure).
2. Spawn the subject with the three-part prompt.
3. Grade: run the assertion table; record verdicts + excerpts in
   `live-1-results.md` (append a `## Run N` section per rep).
4. Any FAIL on a hard assertion = investigate whether the defect is in the
   skill (fix per iron law) or in the eval design (fix the spec here).
