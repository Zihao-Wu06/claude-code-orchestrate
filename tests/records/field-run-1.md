# Field run 1 — first real end-to-end orchestration

Date: 2026-07-05. Orchestrator: Fable 5 (session model, effort max). Skill
version: post-dispatch-prompt-layer (commit 2b03103 era). Purpose: exercise
the machinery in vivo — named agents, contracts, statuses, file handoff,
background peer flow, verification stage — not to test whether the
orchestrator can find bugs.

## Setup

Sandbox (built by fast-worker, planted bug known to it only by symptom):
`scratchpad/field-sandbox/` — 139-line Python expense-tracker CLI
(storage + core + report + argparse tangled in one module), 7 passing tests,
zero report coverage. Reported symptom: an expense dated the 1st of a month
is double-counted (current month AND previous month).

Task given to the orchestration: "Fix the double-count bug, extract report
logic into report.py, add report tests. Thorough and correct."

Plan shown first (per skill): scout recon → deep-reasoner root-cause +
frozen design → fast-worker implementation → verification stage (tests +
blind reviewer). Plus one peer.sh Codex consult on the interface — recorded
honestly: per the routing table this task is cheaply verifiable, so Codex
would normally NOT fire; the consult ran as an infrastructure exercise only.

## Delegation log

| # | Executor | Route | Status returned | Notes |
|---|---|---|---|---|
| 0 | fast-worker (named) | fixture build (row 5) | `DONE`, ≤15 lines, symptom-only disclosure honored | status contract worked on first real use |
| 1 | scout (named) | row 4, data-handoff recon | `DONE` (F1) | full anchored inventory, quoted the filter function verbatim, refused to diagnose — correct tier discipline |
| 2 | deep-reasoner (named) | row 6, diagnosis + frozen design | `DONE` (F1) | scout digest handed as file; root cause with a code-verified worked example; 12-test list incl. mandatory pre-fix-failing regression |
| 3 | peer.sh --backend codex | infrastructure exercise (not a routing-table hit) | n/a (raw text) | background + --out worked; returned a **conflicting** interface design (DI: data-in, not path-in) |
| 4 | deep-reasoner (resumed via SendMessage) | reconcile round (one, targeted) | `DONE`, status first line | **adopted peer design in full** on structural grounds (kills the circular-import hazard; tests need no temp files) — not fluency deference. Convergence on the same checkable artifact |
| 5 | fast-worker (named) | row 5, frozen brief as file | `DONE`, first line, ≤15 lines | 19/19 tests; regression-proof: flipped fix back → test #3 FAIL → restored → green. Zero design decisions needed — brief quality confirmed |
| 6 | orchestrator (self) | verification stage step 1 | — | ran the suite + CLI myself (integration ownership): 19/19 OK |
| 7 | general-purpose sonnet (blind reviewer) | verification stage step 2 | `DONE_WITH_CONCERNS` (F1) | defect list, not verdict. **Caught a real latent defect** both designer and implementer carried over: per-category incremental rounding vs once-rounded total diverge (10× 0.033 → total 0.33, category 0.30). Adjudicated: real, pre-existing, out of contract scope — recorded, not fixed in the disposable sandbox |

## Outcome

Task complete and verified: bug fixed (half-open interval), report.py extracted
with strict one-way dependency, 12 new tests incl. a genuine regression guard,
CLI output byte-identical. Sandbox commit `bfedcb5`.

## What worked

- Named agents resolved and stayed in tier (scout wouldn't diagnose; fast-worker
  bounced zero decisions because the brief left none).
- File handoff end-to-end: scout digest → file → deep-reasoner; frozen brief →
  file → fast-worker; diff → file → reviewer; implementer's full report → file,
  final message ≤15 lines. Orchestrator context stayed lean.
- Background peer flow (`run_in_background` + `--out` + read on notification).
- The reconcile round: a real executor disagreement (path-API vs data-API)
  resolved in ONE targeted round on checkable structural grounds.
- Verification stage: the blind reviewer found a defect nobody upstream saw —
  the stage paid for itself on its first outing.
- Statuses: DONE / DONE_WITH_CONCERNS used correctly and meaningfully.

## Friction found (F-list)

- **F1 — status token not on the first line (3 of 6 subagent returns).**
  Scout, deep-reasoner (first reply), and the blind reviewer all emitted
  narrative before the status token; fast-worker (both runs) and the resumed
  deep-reasoner complied. Where the dispatch said "First line = status token,
  nothing before it" compliance improved but was not airtight (reviewer still
  violated). Fix applied: agent defs + TEMPLATE + dispatch-prompt.md status
  section all now state "the FIRST LINE of your final message is the status
  token — nothing before it". Residual risk accepted: the orchestrator can
  still parse a status that appears late.
- **F2 — codex header noise.** peer.sh output includes the codex transcript
  header + token count; the answer needs manual extraction from the tail.
  Known upstream gotcha, confirmed live. No change (documented behavior).
- **F3 — routing discipline held under temptation.** Not a defect, an
  observation: the Codex consult here was NOT justified by the routing table
  (cheaply verifiable task) — run only as an infrastructure exercise. A real
  run should skip it; the table's "don't reach for Codex" list was correct.

## Fixes applied after this run

F1 wording fix in `agents/{deep-reasoner,fast-worker,scout}.md`,
`agents/TEMPLATE.md` (post-move: repo-root `agents/`), and
`skills/orchestrate/dispatch-prompt.md`. Per the iron law the three RUNBOOK
scenarios were rerun after the edit — results in results.md Round 4.
