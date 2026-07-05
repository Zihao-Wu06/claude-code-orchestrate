# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions track
`.claude-plugin/plugin.json` (bump both manifests via
`make bump-version V=x.y.z`).

## [Unreleased]

### Changed
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
