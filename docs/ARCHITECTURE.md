# Architecture

How the pieces of the `orchestrate` plugin fit together, and where each
decision lives. The behavioral source of truth is always
[plugin/skills/orchestrate/SKILL.md](../plugin/skills/orchestrate/SKILL.md) —
this document is the map, not the law.

Everything shippable lives under `plugin/` (the marketplace manifest at the
repo root points its `source` there); everything else in the repo — docs,
tests, vendor snapshot, scripts — is engineering around it.

## Components (all paths under `plugin/`)

```
                       user
                        │  /orchestrate [economic|thorough] [custom] <task>
                        ▼
          commands/orchestrate.md          (entry point: modifiers + tech-lead brief)
                        │ loads
                        ▼
          skills/orchestrate/SKILL.md      (rule core: routing table, cost policy,
                        │                   escalation ladder, budget modes,
                        │                   verification stage, reconcile rules)
                        │ references
                        ▼
          skills/orchestrate/dispatch-prompt.md
                        │                  (dispatch layer: skeleton, per-tier
                        │                   templates, status vocabulary,
                        │                   worked example)
          ┌─────────────┼──────────────┬───────────────────┐
          ▼             ▼              ▼                   ▼
   agents/scout.md  agents/fast-   agents/deep-    skills/orchestrate/peer.sh
   (Haiku,          worker.md      reasoner.md     (cross-vendor peer wrapper;
    read-only       (Sonnet,       (Opus,           --backend codex built in,
    recon)          mechanical)    reasoning)       one function per vendor)
```

Supporting pieces:

- `plugin/skills/orchestrate/patterns.md` — on-demand reference layer (the
  seven mixing patterns and per-signal Codex explanations). Binding rules
  stay in SKILL.md; this file loads only when composing multi-executor work —
  progressive disclosure, same mechanism as dispatch-prompt.md.
- `plugin/skills/orchestrate/agent-TEMPLATE.md` — authoring template for
  custom roles (used by the `custom` roster modifier). Deliberately kept
  *inside* the skill directory so plugin auto-registration never picks it up
  as a real agent.
- `scripts/install.sh` — manual installer (`make install`); `scripts/` —
  maintenance tooling.

## Two install modes, one behavior

| | Plugin install | Manual install |
|---|---|---|
| Command | `claude plugin marketplace add …` + `claude plugin install …` | `make install` |
| Skill location | plugin cache dir | `~/.claude/skills/orchestrate/` |
| Agents | auto-registered from `plugin/agents/` | copied to `~/.claude/agents/` |
| `/orchestrate` | auto-registered | copied to `~/.claude/commands/` |
| `peer.sh` path | resolve relative to SKILL.md | `~/.claude/skills/orchestrate/peer.sh` |

`plugin/` is the plugin root (`plugin/.claude-plugin/plugin.json`; `skills/`,
`agents/`, `commands/` directly under it, as the official plugin spec
requires). The repo root carries only the marketplace manifest
(`.claude-plugin/marketplace.json`, `source: "./plugin"`) — the repo is its
own marketplace.

## Load-bearing design decisions (index)

Each links to the section in SKILL.md that states the actual rule:

1. **First-match routing with a trivial-solo row** — delegation has fixed
   overhead; the table exists as much to *prevent* delegation as to cause it.
   (§ Routing rule)
2. **Cost & context policy** — the orchestrator's context is the scarcest
   resource; reads >~100 lines go to scout; returns are capped at 20 lines
   except data-handoff recon. (§ Cost & context policy)
3. **Budget modes never lower thinking depth** — `economic`/`thorough` change
   *who* gets the task and how much verification runs, never how hard the
   assignee thinks; every skipped cross-check is announced. (§ Budget modes)
4. **Status vocabulary drives the escalation ladder** — `NEEDS_CONTEXT` is
   not a failure; `BLOCKED`/two missed acceptance checks climb strictly
   upward, never down. (§ Escalation ladder)
5. **Blind-parallel path with a four-part escalation brief** — disagreement
   after one reconcile round is a stop condition; ties are never broken by
   fluency, confidence, or industry priors; the brief has no fifth part.
   (§ The high-stakes parallel path)
6. **Verification stage** — implement-type fan-ins get an independent check;
   reviewers return defect lists, never approve/reject. (§ Verification stage)
7. **Role system prompts vs dispatch prompts are two layers** — named agents
   carry their operating contract; the `general-purpose` fallback path and
   the peer must receive a role preamble in the dispatch itself.
   (dispatch-prompt.md § Skeleton)

## Testing

Three layers — fixtures, quantified evals, and narrative records — indexed in
[tests/README.md](../tests/README.md), with the iron law and rerun
procedures in [tests/RUNBOOK.md](../tests/RUNBOOK.md).

## License

[CC BY-NC 4.0](../LICENSE) — noncommercial use, attribution required. The
feature list is in [README.md](../README.md).
