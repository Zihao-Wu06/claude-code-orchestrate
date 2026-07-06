# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions track
`plugin/.claude-plugin/plugin.json` (bump both manifests via
`make bump-version V=x.y.z`).

## [Unreleased]

## [0.1.0] - 2026-07-06

Initial public release.

### Added
- **Skill core** (`SKILL.md`): the first-match routing table, seven
  Opus/Sonnet mixing patterns, Codex use/don't-use signals, the blind-parallel
  high-stakes path, and the fragmentation/rubber-stamping guardrail — plus the
  scout recon role (Haiku, read-only), the cost & context policy, the
  verification stage, the six-field delegation contract, an SDO-compliant
  description, budget modes (`economic` / default / `thorough`, never reducing
  any executor's thinking depth), the escalation ladder, and fan-out worktree
  isolation.
- **Custom roster — roles and skills** (`custom` modifier): enumerates
  installed agent roles *and* installed skills (frontmatter only) and asks
  which to use this run. A role slots into a tier; a selected skill is injected
  into the matching dispatch as its operating procedure — announced, never
  broadcast, the tier contract always winning. `agent-TEMPLATE.md` is the
  authoring guide for roles.
- **Dispatch + reference layers** (`dispatch-prompt.md`, `patterns.md`): the
  dispatch skeleton and per-tier templates, the
  DONE/DONE_WITH_CONCERNS/NEEDS_CONTEXT/BLOCKED status vocabulary wired into
  the ladder, file-handoff rules, the data-handoff recon exception, and the
  verbatim blind-parallel rule; the seven mixing patterns load on demand
  (progressive disclosure) while all binding rules stay in SKILL.md.
- **Cross-vendor peer** (`peer.sh`): a generalized wrapper (`--backend`, one
  function per vendor, Codex built in), `--effort` mapped to
  `model_reasoning_effort`, `--mode consult|implement`, and a portable timeout
  with a process-group watchdog for macOS. A hard, persistent on/off switch
  (`--off | --on | --status`; marker outside the skill dir so it survives
  updates; disabled calls exit 3) — while off, or when the Codex CLI is
  unreachable, the skill announces the skip and the high-stakes path falls back
  to its economic-mode single-executor form.
- **Validation**: ten TDD RED→GREEN rounds (every edit to a behavioral file
  re-runs the scenarios — the iron law); a quantified ablation (with-skill
  100% vs. baseline 58.3%, Δ+0.42); a field trial whose blind reviewer caught
  a latent defect the whole chain missed; a live end-to-end eval (a nested
  orchestrator really fixes a planted bug, graded on independent
  red-before/green-after reproduction); trigger tests (0 false activations).
- **Packaging, CI & docs**: plugin + self-hosted marketplace manifests
  (`claude plugin validate --strict` clean); `make install` with a
  post-install self-check and manifest-scoped stale-agent cleanup; `make
  check` plus a Linux **and** macOS smoke-install and a dedicated
  manifest-schema job in CI; a usage guide and a paper-style design/evaluation
  writeup in the README, `docs/ARCHITECTURE.md`, `docs/USAGE.md`,
  `CONTRIBUTING.md`; LICENSE (CC BY-NC 4.0).

[Unreleased]: https://github.com/Zihao-Wu06/claude-code-orchestrate/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/Zihao-Wu06/claude-code-orchestrate/releases/tag/v0.1.0
