# Collaboration Patterns & Peer Signals — orchestrate skill

On-demand reference layer (same mechanism as dispatch-prompt.md): read this
when composing multi-executor work or weighing a Codex consult. The binding
rules live in [SKILL.md](SKILL.md) — this file explains and illustrates; if
anything here reads as conflicting with SKILL.md, SKILL.md wins.

## The seven mixing patterns — fast-worker (Sonnet) and deep-reasoner (Opus)

Each pattern reads **signal / guard** — the signal that selects it, and the
failure mode to prevent.

- **Spec then build.** Opus fixes the interface and acceptance check; Sonnet implements. *Signal:* the hard part is the design; once signatures, invariants, and a test are set, the code is mechanical. *Guard:* an under-specified handoff makes Sonnet invent design silently. Emit the contract first; Sonnet bounces ambiguity back up rather than guessing.
- **Draft then harden.** Sonnet writes a fast first cut; Opus reviews and hardens it. *Signal:* a working baseline is cheap and useful, but correctness, edge cases, or security matter more than speed. *Guard:* Opus rubber-stamps a fluent-but-wrong draft. Aim it at failure modes (concurrency, boundaries, auth, error paths) and demand a specific defect list, not polish.
- **Plan then fan out.** Opus plans and partitions; N Sonnet workers do the pieces in parallel. *Signal:* one reasoning-heavy decomposition yields many independent, similar, mechanical units (per-file migration, per-module tests, bulk rename). *Guard:* fragmentation. Freeze the shared contract before fan-out, assign non-overlapping scopes, and — when workers edit files concurrently — give each `Agent(isolation: "worktree")`: non-overlapping scope on paper does not prevent real file conflicts. Run the full build and tests after fan-in. Piecewise-correct is not integrated-correct.
- **Gather then reason.** Scout (or Sonnet, if the gathering needs light tooling) greps and collects; Opus reasons over the digest. *Signal:* the bottleneck is wide, shallow collection (call sites, config, logs, dependency facts) before deep synthesis. *Guard:* the collector pre-selecting the cause or dumping raw volume. Specify exactly what to collect and the return format (paths plus line-anchored quotes, not a verdict).
- **Reason then verify.** Opus produces the fix or design; Sonnet writes the test or reproduction that proves it. *Signal:* Opus's output is high-stakes but checkable. *Guard:* a vacuous test that restates the implementation. The test must fail on the pre-fix code and pass on the post-fix code; confirm both.
- **Triage then deep-dive.** Sonnet reproduces and localizes; Opus root-causes; Sonnet applies the bounded fix. *Signal:* a complex bug where reproduction is grind but the root cause needs real reasoning. *Guard:* Sonnet "fixing" a symptom. Its job ends at a reliable minimal repro plus a suspected locus; the fix decision is Opus's, and the repro stays as a regression test.
- **Routine vs. exceptional split.** Sonnet takes the conventional path; Opus owns the one hard subsystem. *Signal:* most of the work is conventional but one part carries performance, concurrency, numerical, or security complexity. *Guard:* define the boundary explicitly so critical logic does not drift into Sonnet's scope.

## Codex peer signals — explained

The one-line lists live in SKILL.md; these are the per-signal explanations.

Fire on any one signal:

- **Unverifiable check.** Opus answered, and you need an independent check on a claim you cannot cheaply verify (no test, no ground truth).
- **You are looping.** Two or more rounds have circled the same framing or repeated the same wrong fix. A vendor switch breaks the fixation.
- **Disputed, expensive-to-undo design.** API shape, schema, concurrency model, or migration strategy where reasonable engineers disagree and being wrong is costly.
- **High-stakes parallel path (row 3).** High blast radius *and* hard to verify: launch Opus and Codex blind, then reconcile.
- **"Am I framing this wrong?"** You suspect your own decomposition, not the answer within it.
- **Unfamiliar or recent ecosystem.** A stack, library, or idiom where OpenAI's training mix may cover different ground.
- **Adversarial cross-review.** Have each model attack the other's output; ask Codex to *falsify* a confident Opus conclusion, not merely review it.

Do **not** reach for Codex when:

- The task is **cheaply verifiable** (a test runs, a type checks, a diff applies). Verify instead; decorrelation buys nothing you can just check.
- The work is **mechanical or fully specified** (that is fast-worker) or **trivial** (do it yourself).
- The answer needs **deep in-repo context** Codex would have to re-acquire. The briefing cost exceeds the benefit; keep it with Opus.
- You **only want more confidence** on something Opus already verified. Confidence is not a reason; a checkable artifact is.
- **Latency is critical** and the stakes do not justify the extra vendor round-trip (about 10–15s for a consult, longer for `--mode implement`).
