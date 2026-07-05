# Test results — orchestrate skill

Method per RUNBOOK.md. Test subjects: `Agent(general-purpose, model: sonnet)`,
one-shot, fresh context, decision-trace prompts.

## Round 1 — baseline (RED), 2026-07-05, no skill text

| Scenario | Verdict | Summary |
|---|---|---|
| A — trivial | **no failure** (complies without skill) | Fixed the typo itself, two tool calls, zero delegation. Verbatim: "spawning `scout`, `fast-worker`, or `peer.sh` for a one-word, one-line, already-located typo fix would be pure overhead… This is squarely in 'just do it yourself' territory." |
| B — conflict | **FAIL** | Escalated to the human with crux questions (good), **but declared a default winner** — "recommend the shared-schema + tenant_id + RLS path (Opus's answer) as the default, because it's the more common industry-proven pattern" — i.e. leaned to the more fluent, more detailed side on prior alone. Also invented its own tie-break argument (reversibility asymmetry) and adjudicated with it itself instead of feeding it back as evidence. Pressure that worked: "the user is waiting and wants the schema decision settled in this session" → "Give a recommendation, not just a menu — because the user explicitly wants it settled this session." |
| C — recon | **no failure** (complies without skill) | Scout-first parallel recon with bounded return format; deep-reasoner only after the digest; no personal Read of the module files. Verbatim: "scout is read-only and cheap (Haiku), and I don't yet know the codebase shape well enough to write a good task for deep-reasoner." |

### Implications for the skill (honest scoping of what TDD verifies)

- **B is the verified-by-failing-test content.** The reconciliation wording must
  counter, explicitly: (1) "user wants it settled now → I must pick a default";
  (2) recommendation-as-synthesis that leans to the fluent side "on
  industry-common priors"; (3) the orchestrator inventing a new tie-break
  argument and adjudicating with it itself (correct move: feed genuinely new
  evidence back as one more targeted reconcile round, not decide).
- **A and C rules are adopted from upstream (proven there); baseline already
  complies here.** For A/C the GREEN run serves as a regression guard only —
  verifying the added skill text does not *degrade* compliant behavior — not as
  proof the skill causes it. Caveat: A/C prompts list the roster (including
  scout's description), which itself primes good routing; that priming is
  realistic, since installing the skill installs those agent descriptions.
- Test subjects are Sonnet, not Fable (see RUNBOOK limitations).

## Round 2 — with skill (GREEN), 2026-07-05, SKILL.md read by subject before answering

| Scenario | Verdict | Summary |
|---|---|---|
| A — trivial | **PASS** (no regression) | Read → Edit, zero delegation; cited routing row 2 verbatim and rejected each other row explicitly. |
| B — conflict | **PASS** (baseline failure flipped) | Stopped delegating; produced the four-part brief with no fifth part — "no recommendation, no lean". Compressed Opus's 40 lines and expanded Codex's 6 to comparable depth ("so neither reads as more authoritative purely from length"). Countered the settle-now pressure with the skill's own rule: "'user wants it settled now' doesn't transfer an unverifiable, expensive-to-undo call onto me; the human holds the growth/compliance facts neither model had." |
| C — recon | **PASS** (behavior upgraded vs baseline) | Walked the routing table row by row; correctly ruled row 3 *out* via the dual-condition test (high blast radius but cheaply verifiable → single executor + verification); scout-first with a full six-field contract; cited the cost policy ("don't read to understand — dispatch scout"); planned fan-out with `isolation: "worktree"` and an independent post-implementation reviewer. |

**Outcome: 3/3 PASS, no refactor round needed.** B — the one
verified-by-failing-test scenario — flipped RED → GREEN on the first GREEN
run. A and C confirm the added text does not degrade already-compliant
behavior and that the new sections (cost policy, contract, verification,
worktree) are actually picked up and applied.

## Round 3 — dispatch-prompt layer edit, 2026-07-05 (skill + dispatch-prompt.md read by subject)

Edit under test: new dispatch-prompt.md (skeleton, per-tier templates, status
vocabulary, worked example), SKILL.md wiring (fallback-path role preamble
requirement, status-driven ladder, file handoff, peer framing + verbatim
blind-parallel rule), status bullet in all agent defs. Scenario C hardened
for this round: named subagents declared unavailable (forces the fallback
path) and the subject must write its first dispatch prompt verbatim.

| Scenario | Verdict | Summary |
|---|---|---|
| A — trivial | **PASS** | Read → Edit, zero delegation, cites row 2; explicitly declines a post-edit verification read as context burn. |
| B — conflict | **PASS** | Four-part brief, "no default pick, no recommendation, no lean"; symmetric-depth presentation ("symmetric length, not symmetric confidence"). |
| C — recon (hardened) | **PASS** | Fallback path handled correctly: scout role preamble prepended verbatim, scene-setting line, six-field contract, status vocabulary first, judgment bounced ("requires reasoning — route to deep-reasoner"). One finding → refactor below. |

**REFACTOR finding (C):** the subject sensibly let a data-handoff inventory
exceed the ≤20-line return cap — correct behavior, but the skill didn't
license it, so a stricter subject might truncate an inventory to fit the cap
(silent data loss). Fix: data-handoff exception added as an observable-predicate
conditional (dispatch-prompt.md recon template + cost-policy line).

**Round 3b — scenario C rerun after fix: PASS.** Subject explicitly invoked
the new exception ("This is a data-handoff recon feeding another executor…
caps do not apply here") and kept the rest of the skeleton intact.

## Round 4 — post-field-run F1 fix, 2026-07-05

Edit under test: field run 1 (tests/field-run-1.md) found statuses arriving
after narrative preamble in 3 of 6 real subagent returns (F1). Fix: "The
FIRST LINE of your final message is the status token — nothing before it"
in all agent defs, TEMPLATE, and dispatch-prompt.md's status section.

| Scenario | Verdict | Summary |
|---|---|---|
| A — trivial | **PASS** | Row-2 solo; explicitly rules out every executor including the reviewer stage ("briefing costs more than doing"). |
| B — conflict | **PASS** | Four-part brief, no fifth part; new depth: refuses to smuggle its own new argument into the brief after the reconcile round closed ("introducing a fresh consideration only in the brief, unweighed by either executor, would be me quietly casting a vote"), and expands the terse side by asking that executor to state its own reasoning rather than inventing it. |
| C — recon (hardened, fallback) | **PASS** | Role preamble verbatim, data-handoff exception invoked with justification, status-line-first in the return format, six fields present, and correctly defers the row-3 decision until recon returns. |

**Outcome: 3/3 PASS.** The F1 wording is in the templates the subjects
reproduce; live-executor compliance is verified separately in field runs
(field-run-1.md notes residual risk: dispatch-level repetition helps but is
not airtight — the orchestrator tolerates late-status parsing as fallback).

## Round 5 — description SDO update, 2026-07-05

Edit under test: frontmatter description made pushier (broader trigger
surface: worker/sub agents, split design from grunt work, run-two-models-and-
reconcile, don't-burn-context phrasing) after trigger tests showed
undertriggering in the probe environment. Body unchanged. Iron-law rerun:

| Scenario | Verdict |
|---|---|
| A — trivial | **PASS** (row-2 solo, zero delegation) |
| B — conflict | **PASS** (four-part brief, no fifth part, one-reconcile-round cap correctly applied) |
| C — recon (fallback) | **PASS** (scout-first with verbatim preamble, data-handoff exception, test-coverage item added to gate the row-3 decision) |

**Outcome: 3/3 PASS — description change causes no behavioral regression.**

## Round 6 — plugin packaging path updates, 2026-07-05

Edit under test: Setup section rewritten for the plugin/manual dual install
(agents moved to repo-root agents/, peer.sh resolve-relative note). Body
rules unchanged. Iron-law rerun: A **PASS** (row-2 solo), B **PASS**
(four-part brief, no fifth part), C **PASS** (scout-first fallback with
preamble; notably ruled row 3 *out* on cheap-verifiability grounds and held
Codex in reserve for the verification stage — sharper than earlier rounds).
**3/3 PASS — packaging edits cause no behavioral regression.**

## Round 7 — progressive-disclosure split, 2026-07-05

Edit under test: seven mixing patterns + per-signal Codex explanations moved
to patterns.md (reference layer); SKILL.md keeps the pattern-name list, the
cross-pattern invariants, the worktree rule, and one-line signal
enumerations (24,778 → 21,530 bytes, −13.1%). TEMPLATE.md authoring steps
made install-mode aware. **Test design: subjects deliberately read only
SKILL.md + dispatch-prompt.md — if a scenario failed on moved content, that
content was load-bearing and must move back.**

| Scenario | Verdict |
|---|---|
| A — trivial | **PASS** (row-2 solo, two tool calls, refuses ceremony) |
| B — conflict | **PASS** (four-part brief, no fifth part; correctly notes thorough-mode's 2-round allowance doesn't apply in default mode) |
| C — recon (fallback) | **PASS** — and notably picked up "disputed, expensive-to-undo design" and "adversarial falsify" from the compressed one-line signal list alone, planning a Codex falsify pass on the frozen design |

**Outcome: 3/3 PASS with patterns.md unread — the rules layer is
self-sufficient; only explanations moved out.**

## Round 8 — tree cleanup reference updates, 2026-07-05

Edit under test: agent authoring template moved up to
`skills/orchestrate/agent-TEMPLATE.md` (single-file agents/ dir removed);
SKILL.md custom-roster pointer updated. No rule changes.

| Scenario | Verdict |
|---|---|
| A — trivial | **PASS** (row-2 solo, Read→Edit, refuses ceremony) |
| B — conflict | **PASS** (four-part brief, no fifth part, no third round) |
| C — recon (fallback) | **PASS** (scout-first with preamble, data-handoff exception, row-3 held for the design step with explicit dual-condition reasoning) |

**Outcome: 3/3 PASS.** Note: subjects running inside this repo also surfaced
the local CLAUDE.md orchestration default (another session's local, untracked
config) — it did not affect verdicts; behavior matched the skill in all three.

## Round 9 — plugin/ nesting path updates, 2026-07-05

Edit under test: the shippable plugin moved under `plugin/` (marketplace
`source: "./plugin"`); SKILL.md Setup section repo paths updated
(`<repo>/plugin/agents/`, `make install`). No rule changes. Subjects read
the skill at its new path.

| Scenario | Verdict |
|---|---|
| A — trivial | **PASS** (row-2 solo, Read→Edit, explicitly declines a disproportionate verification step) |
| B — conflict | **PASS** (four-part brief, no fifth part; expands the terse side by asking that executor rather than inventing) |
| C — recon (fallback) | **PASS** (scout-first with preamble, data-handoff exception, row-3 correctly ruled out on verifiability, file-handoff rule cited for the relay) |

**Outcome: 3/3 PASS — repository re-layout is behavior-neutral.**

## Round 10 — peer on/off switch wiring, 2026-07-05

Edit under test: the peer is now explicitly optional — `peer.sh --off/--on/
--status` hard switch (marker outside the skill dir; disabled runs exit 3);
SKILL.md Setup extends the degradation sentence (switched-off = same
announced-skip path, row-3 falls back to its cheap-mode form) and
Troubleshooting gains the exit-3 entry. Routing rules unchanged.

| Scenario | Verdict |
|---|---|
| A — trivial | **PASS** (row-2 solo; correctly notes the status vocabulary is for executors, not for second-guessing complete instructions) |
| B — conflict | **PASS** (four-part brief, no fifth part; distinguishes executor *failure* — ladder territory — from stable substantive disagreement) |
| C — recon (fallback) | **PASS** (scout-first; builds the row-3-vs-row-6 deciding fact — session test coverage — into recon item 6 instead of discovering it after mis-routing) |

**Outcome: 3/3 PASS — the optionality wiring causes no behavioral drift.**

## Eval suite (iteration 1) — quantified benchmark, 2026-07-05

The scenarios were also ported to the skill-creator eval harness
(tests/evals/): with_skill **100%** (11/11 assertions) vs without_skill
**58.3%**, delta **+0.42**. Trigger tests: perfect precision (0 false
positives across 12 negative samples), ~zero recall in the `claude -p`
probe environment (see evals/iteration-1/ANALYSIS.md for the honest
interpretation — including the same-day real-environment auto-trigger that
contaminated, and thereby validated, the baseline arm). Full artifacts:
benchmark.md and ANALYSIS.md under tests/evals/iteration-1/ (the browsable
review.html viewer is generated, not committed — see tests/RUNBOOK.md).
