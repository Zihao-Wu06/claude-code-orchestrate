# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions track
`plugin/.claude-plugin/plugin.json` (bump both manifests via
`make bump-version V=x.y.z`).

## [Unreleased]

### Added
- Live end-to-end eval v1 (`tests/evals/live/`): a nested orchestrator
  subject really spawns subagents to fix a planted bug; graded on objective
  assertions (independent red-before/green-after reproduction included).
  Run 1: PASS 4/4 hard assertions; surfaced F-LIVE-1 (background-subagent
  notifications unreliable one nesting level down — harness now mandates
  foreground dispatches for subjects; documented in USAGE). Manifest-path
  prose drift in CHANGELOG/CONTRIBUTING/bump-version fixed, with a
  make-check guard for the stale-path pattern (both per cross-vendor
  review follow-up).
- The Codex peer is now explicitly optional: `peer.sh --off | --on | --status`
  persistent switch (marker outside the skill dir, survives updates; disabled
  runs refuse with exit 3). While off, the skill announces the skip and the
  high-stakes path falls back to its cheap-mode single-executor form.
- CI now smoke-tests the manual install path on Linux **and macOS**
  (`make smoke-install`: placement, idempotence, stale-agent cleanup — the
  macOS job is the first CI coverage of peer.sh's bash-3.2/watchdog branch),
  runs a mock-codex peer.sh test (`tests/shell/test-peer.sh`: sandbox flags,
  --effort mapping, stdin redirection, hung-backend kill), validates both
  plugin manifests against the official schema in a dedicated job, and
  checks relative markdown links (`scripts/check-links.py` — the guard for
  the README badge link rot this round fixed). install.sh gained a
  post-install self-check and manifest-scoped stale-agent cleanup.
  docs/USAGE.md added (worked examples, modifier guidance, failure hints).
  A live-scenario eval (≥3 reps, blind grading) is queued in the eval
  backlog pending a token budget. (Adjudicated from a cross-vendor Codex
  review: adopted P0/P1b fully, P1a/P2a/P2b partially, deferred P1c.)

### Changed
- The shippable plugin now lives entirely under `plugin/` (agents, commands,
  skills, plugin manifest), mirroring upstream open-science-skills; the root
  marketplace manifest points at `./plugin`. `install.sh` moved to
  `scripts/install.sh` (`make install`). Root entries: 19 → 15.
- GitHub tree slimmed: raw eval run data is no longer committed (regenerable;
  iteration-1 originals preserved in git history at `7767a0d`) — only
  benchmark summaries and ANALYSIS ship; narrative records moved to
  `tests/records/`; the agent authoring template moved up to
  `skills/orchestrate/agent-TEMPLATE.md` (single-file directory removed);
  accidentally committed local workflow config (AGENTS.md, .codex/) amended
  out of history and gitignored.
- Progressive disclosure: the seven mixing patterns and per-signal Codex
  explanations moved to `skills/orchestrate/patterns.md` (on-demand
  reference layer); all binding rules — including the cross-pattern
  invariants and the fan-out worktree rule — remain in SKILL.md, verified
  by a scenario rerun whose subjects deliberately did not read patterns.md.
- `agents/TEMPLATE.md` authoring steps are now install-mode aware (plugin
  users author in `~/.claude/agents/`, never the plugin cache; manual users
  in repo `agents/` + `./install.sh`) — the previous steps predated the
  agents-directory move.
- `peer.sh --help` extracts the header by marker instead of a hardcoded
  line range; `commands/orchestrate.md` no longer duplicates modifier
  semantics (SKILL.md is the single source); CI gains `workflow_dispatch`.
- Repository structure aligned with industrial open-source conventions
  (referenced: anthropics/claude-plugins-official, obra/superpowers):
  `docs/` layer (ARCHITECTURE), CONTRIBUTING, CHANGELOG, vendor PROVENANCE,
  Makefile + `scripts/bump-version.sh`, `.editorconfig`/`.gitattributes`,
  PR/issue templates with the skill-change test gate, CI converged onto
  `make check`, `tests/README.md` index.
- Generated artifacts (`review.html`, run logs, scratch eval subsets) are no
  longer tracked; regeneration commands documented in `tests/RUNBOOK.md`.
- Deliberately omitted (not oversight): CODE_OF_CONDUCT/SECURITY.md (no
  community/attack surface yet), pre-commit framework (Makefile + CI cover
  the same checks without a new dependency), CLAUDE.md/AGENTS.md
  (CONTRIBUTING.md carries that role).

## [0.1.0] - 2026-07-05

Initial release: an adaptation of `fable-orchestrate` from
[scdenney/open-science-skills](https://github.com/scdenney/open-science-skills)
(Steven Denney, CC BY-NC 4.0), substantially extended.

### Added
- **Skill core** (`skills/orchestrate/SKILL.md`): everything upstream —
  first-match routing table, seven Opus/Sonnet mixing patterns, Codex
  use/don't-use signals, blind-parallel path, fragmentation/rubber-stamping
  guardrail — plus twelve enhancements: scout recon role (Haiku, read-only),
  cost & context policy, verification stage, six-field delegation contract,
  SDO-compliant description, `/orchestrate` command, budget modes
  (`cheap`/`thorough`, never reducing thinking depth), escalation ladder,
  generalized `peer.sh` (`--backend`, `--effort`, portable timeout fallback
  for macOS), fan-out worktree isolation, TDD regression suite, optional
  custom roster (`custom` modifier + agents TEMPLATE).
- **Dispatch-prompt layer** (`dispatch-prompt.md`): six-part dispatch
  skeleton, per-tier fill-in templates, DONE/DONE_WITH_CONCERNS/
  NEEDS_CONTEXT/BLOCKED status vocabulary wired into the ladder, file
  handoff rules, data-handoff recon exception, peer framing + verbatim
  blind-parallel rule. Modeled on superpowers subagent-driven-development.
- **Validation**: six TDD rounds (baseline B failure — fluency tie-break —
  flipped GREEN and held through every subsequent edit); a real end-to-end
  field run whose blind reviewer caught a latent defect the whole chain
  missed (`tests/records/field-run-1.md`); a quantified eval suite (with-skill 100%
  vs baseline 58.3%, `tests/evals/`); trigger tests (0 false positives).
- **Packaging**: plugin + self-hosted marketplace manifests
  (`claude plugin validate --strict` clean), manual `install.sh`, CI
  (shellcheck, manifest, integrity checks), LICENSE (CC BY-NC 4.0 with
  upstream attribution).

[0.1.0]: https://github.com/Zihao-Wu06/claude-code-orchestrate/releases/tag/v0.1.0
