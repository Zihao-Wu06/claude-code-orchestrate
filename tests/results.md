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
