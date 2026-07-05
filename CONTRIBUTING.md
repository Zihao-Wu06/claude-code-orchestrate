# Contributing

Small project, strict discipline. The rules below exist because every one of
them caught a real defect during development — see `tests/results.md` and
`tests/field-run-1.md` for the receipts.

## Setup

```bash
git clone https://github.com/Zihao-Wu06/claude-code-orchestrate
cd claude-code-orchestrate
make check        # bash -n, shellcheck, manifest JSON, CI YAML, file integrity
make install      # manual install into ~/.claude (or use the plugin flow in README)
make validate     # claude plugin validate . --strict
```

No runtime dependencies. Tooling used by `make check`: `bash`, `jq`,
`python3` (stdlib), `shellcheck` (optional locally — CI always runs it).

## The testing iron law

**Any edit to `skills/orchestrate/SKILL.md`, `skills/orchestrate/dispatch-prompt.md`,
or `agents/*.md` requires rerunning the behavior scenarios before it ships.**
No exceptions for "just wording", "just a path", or "obviously harmless" —
Rounds 4–6 in `tests/results.md` were all reruns for exactly such edits.

- Procedure and grading rules: [tests/RUNBOOK.md](tests/RUNBOOK.md)
- Paste the rerun results table into your PR (the PR template has a slot)
- Docs/tooling/CI changes that do not touch those files are exempt — say so
  in the PR

If your change alters what the skill *should* do (not just how it's worded),
follow the full RED-GREEN loop: add or harden a scenario that fails first.

## Style

- Shell: `shellcheck -S warning` clean; portable (macOS ships bash 3.2 and
  no GNU `timeout` — `peer.sh` shows the patterns)
- Markdown/prose: plain English, no marketing voice; explain *why* a rule
  exists, not just the rule
- Skill/agent wording changes: prefer positive recipes over prohibition
  lists; keep frontmatter descriptions trigger-conditions-only

## Versioning & releases

- `make bump-version V=x.y.z` updates both manifests
  (`.claude-plugin/plugin.json` + `marketplace.json`) atomically — never edit
  version numbers by hand (two-file drift is the failure mode)
- Add a `CHANGELOG.md` entry under the new version heading in the same PR

## License

Contributions are accepted under the repo license,
[CC BY-NC 4.0](LICENSE), which also binds this project to its upstream
(`vendor/fable-orchestrate/` — do not edit that directory; see its
`PROVENANCE.md` for the sync procedure). Noncommercial use only.
