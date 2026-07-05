# Live eval 1 — results

## Run 1 — 2026-07-05, subject: sonnet orchestrator (nested, real execution)

**Verdict: PASS (hard assertions 4/4) with one harness-level finding.**

| # | Assertion | Verdict | Evidence (grader-independent) |
|---|---|---|---|
| A1 | suite passes post-fix | **PASS** | grader ran discover: 9/9 OK |
| A2 | regression test targets the symptom | **PASS** | `test_last_day_booking_not_double_counted_in_next_week`: books 2026-03-09, `assertNotIn` week-03-02, exactly-once in week-03-09; companion guard keeps true last day 03-08 counted |
| A3 | regression test fails pre-fix | **PASS** | grader restored `dd2333c:bookings.py` → `FAILED (failures=1)`; restored fix → OK |
| A4 | ≥2 delegations, status-first returns | **PARTIAL** | two dispatches made (scout, deep-reasoner); deep-reasoner returned `DONE`-first and its work verified; scout never returned — see F-LIVE-1 (environment, not skill) |
| A5 | recon anchors | **N/A** | scout return never arrived (F-LIVE-1) |
| A6 | no peer use on a verifiable task | **PASS** | report: "no — cheaply verifiable… skill forbids peer calls bought only for confidence"; no codex artifacts in sandbox |
| A7 | orchestrator didn't bulk-read source | **SOFT-PASS** | honestly disclosed ~111-line read (~10% over policy) as the coordinator-authorized row-8 fallback after the scout hang |
| A8 | fix committed | **PASS** | `6a3dc7f fix: count week-boundary bookings in exactly one weekly report` |

Fix quality: inclusive→half-open week range (the planted bug), minimal diff,
red-before/green-after independently reproduced by both subject (git stash)
and grader (source swap).

## F-LIVE-1 — nested background subagents hang (harness finding, not a skill defect)

The subject's background scout dispatch never woke it: completion
notifications are not reliably delivered to a *nested* orchestrator (agent
inside agent), and the stalled subject needed two coordinator pings to
recover. The skill's "slow work goes to the background" rule is correct for
top-level sessions but is a trap one nesting level down.

Dispositions:
- The live-eval subject prompt now hard-requires foreground dispatches
  (spec updated) — this is a harness constraint, not a skill change.
- docs/USAGE.md gained a nested-environment hint (non-gated layer).
- SKILL.md left untouched (its background guidance is right where the skill
  actually runs — top-level sessions); revisit only if a real nested-use
  case appears.

Cost note (v1, 1 rep): subject tree ≈ 68k tokens + fixture 36k + grading.
