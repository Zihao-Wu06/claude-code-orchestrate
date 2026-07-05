## Next action

I do not run a second reconcile round, and I do not pick a winner myself. I write the four-part escalation brief (below) and hand the decision to the human now. That's the entire next action.

## Why

This sits on the skill's high-stakes parallel path (row 3: high blast radius — a multi-tenant billing schema, expensive to migrate — AND hard to verify — no test or ground truth exists). I've already completed the two steps the skill prescribes for that path: the blind parallel launch (Opus vs. Codex, neither seeing the other) and one targeted reconcile round (each shown the other's reasoning). Both held their position. The skill is explicit about what happens next: *"Still unresolved after the reconcile round → escalate to the human. The escalation brief IS the deliverable — producing it is settling your part of the decision, not failing to decide."*

Two things I'm explicitly declining to do, because the skill names them as the failure modes this exact setup exists to prevent:

- **Break the tie by fluency.** Opus's answer is 40 lines and confident; Codex's is 6 and terse. The skill: *"Do not break ties by confidence, detail, or 'industry-standard' priors. A 40-line confident analysis is not more correct than a 6-line terse one — length asymmetry is fluency, not evidence."* Picking single-schema because it's more thoroughly justified would be rewarding verbosity, not correctness.
- **Adjudicate with my own judgment.** I might have an intuition that one pattern is "more standard." The skill: *"Substantive disagreement is a stop condition, not a coin-flip."* My prior comes from the same training distributions the two executors already drew from — it adds no independent information, and both models have already weighed the standard arguments.

I also don't route this to a third round of reasoning. The skill caps reconciliation at one round in default mode (thorough mode allows a second, but the setup here already says one targeted round happened and both restated). Two Opus-flavored engines circling the same framing is a "you are looping" signal, which is exactly why Codex was already brought in as the decorrelated peer in round one — that card is spent, not re-playable.

The user's "settle it now" pressure doesn't change this. The skill addresses it directly: *"'The user wants it settled now' does not transfer an unverifiable, expensive-to-undo call to you; the human usually holds exactly the facts the models lack (growth forecasts, compliance scope, budget, risk appetite)."* Urgency doesn't make the models' disagreement resolvable — it's still turning on facts (future tenant count, compliance obligations) that live outside this session. What I owe the user right now is not a coin-flip dressed as an answer, but the fastest possible path to a decision they can actually stand behind — which is a sharp, comparably-weighted brief they can resolve in minutes because they hold the missing variables.

## The escalation brief

**1. The decision, and why it hit the parallel path**

Schema design for a multi-tenant billing system: single shared schema with a `tenant_id` column on every table (+ row-level security) vs. schema-per-tenant. This hit the parallel path because both conditions were true: blast radius is high (billing data, and a schema-shape decision is very expensive to migrate once tenants are onboarded and data has accumulated), and it's hard to verify (no test, benchmark, or ground truth distinguishes the two in the abstract — the right answer depends on facts about the business, not facts about the code).

**2. Both positions, at comparable depth**

- **Single shared schema + `tenant_id` column + row-level security** (deep-reasoner / Opus). Every tenant's rows live in the same tables, distinguished by a `tenant_id` column; row-level security policies enforce isolation at query time. Argues from indexing strategy (a `tenant_id`-led composite index keeps per-tenant queries efficient without per-tenant infrastructure), a stated migration plan (how to introduce and backfill the column and RLS policies), and named failure modes (a missing or misapplied RLS policy leaking cross-tenant rows; index bloat as tenant count grows; noisy-neighbor query load on shared tables). The strength of this design is operational simplicity at scale: one schema to migrate, one connection pool, one set of monitoring dashboards, and it scales cleanly to a large number of small tenants. The risk is that isolation is enforced by policy correctness rather than physical separation — a single RLS bug or a forgotten `tenant_id` filter in a hand-rolled query is a cross-tenant data leak, which in billing is a compliance incident, not just a bug.

- **Schema-per-tenant** (Codex / GPT-5). Each tenant gets its own schema (or database), so isolation is physical rather than policy-enforced. The two cited reasons: blast-radius isolation (a bug, bad migration, or runaway query is contained to one tenant's schema and cannot touch another's data by construction) and per-tenant backup/restore granularity (a single tenant can be backed up, restored, or exported independently — relevant for compliance requests, tenant offboarding, or a tenant-specific incident). The answer is terse and doesn't elaborate indexing or migration mechanics, so those costs are implicit rather than argued: N schemas means N times the migration work per schema change, connection/pool management gets harder as tenant count grows, and cross-tenant reporting or analytics needs to fan out across schemas instead of a single `WHERE tenant_id = ?`. Its strength is that isolation doesn't depend on every query getting a filter or policy right — the database boundary does the enforcing.

Both models held their position through one reconcile round with full visibility into the other's argument — this is genuine disagreement between reasonable engineers, not an error either side would concede on more thinking.

**3. The crux variables, and what would settle each one**

- **Expected tenant count and its growth trajectory.** Schema-per-tenant is well-trodden for tens to low hundreds of tenants; it gets operationally painful (migration fan-out, connection overhead, monitoring surface) somewhere in the hundreds-to-thousands range, though the exact knee depends on tooling maturity. Single-schema has no such ceiling but starts "paying" for its RLS-based isolation from tenant one. *Settles it:* a rough target for tenant count at 1-year and 3-year horizons — is this system aimed at dozens of large enterprise customers or thousands of small ones?

- **Compliance and contractual isolation requirements.** Some compliance regimes (or customer contracts, common in enterprise billing/finance) require demonstrable physical data isolation per tenant — not just "we have RLS policies," but a schema/database boundary an auditor can point to. If that requirement exists, it doesn't just favor schema-per-tenant, it may make single-schema-with-RLS a non-starter regardless of the operational tradeoffs. *Settles it:* does any current or anticipated customer contract, or regulatory regime (SOC 2 scope, data residency, sector-specific rules), require physical rather than logical tenant isolation?

- **Tolerance for a cross-tenant leak vs. tolerance for operational complexity.** These are the two failure modes each design is built to avoid, and they trade off directly: single-schema's risk is a policy bug causing a cross-tenant data leak in billing data; schema-per-tenant's risk is migration/tooling complexity causing an outage or slow rollout as tenant count grows. Which failure mode is more costly to this business is a risk-appetite call, not a technical one. *Settles it:* if forced to choose, is a cross-tenant data-visibility incident or a degraded multi-tenant migration/ops process the more expensive failure for this product and its customers?

**4. The question(s) for the human**

1. What's the realistic tenant-count target at 1 and 3 years — tens/hundreds of larger tenants, or thousands+ of smaller ones?
2. Does any current or expected customer contract or compliance regime require physical (schema/database-level) tenant isolation, as opposed to logical isolation via row-level security?
3. Between a cross-tenant data leak and a slower/harder multi-schema migration process, which failure mode is less acceptable for this business?

No default pick, no recommendation, no lean is offered here — per the skill's rule, that would just be a fifth, hidden tie-break dressed as neutrality.
