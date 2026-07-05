# Provenance — vendored fable-orchestrate snapshot

**Do not edit anything in this directory.** It is a pristine snapshot of the
upstream skill this project adapts, kept for CC BY-NC 4.0 attribution and
for diffing against future upstream changes.

| Field | Value |
|---|---|
| Upstream repo | https://github.com/scdenney/open-science-skills |
| Upstream path | `plugin/skills/fable-orchestrate/` (+ `plugin/commands/fable-orchestrate.md`, `LICENSE`) |
| Author | Steven Denney |
| License | CC BY-NC 4.0 |
| Fetched | 2026-07-05, `main` branch via raw.githubusercontent.com |
| Upstream commit | not recorded at fetch time — record the SHA on the next sync |

## Files

- `SKILL.md` — upstream skill (166 lines at fetch)
- `agents/deep-reasoner.md`, `agents/fast-worker.md` — upstream agent defs
- `codex-peer.sh` — upstream Codex wrapper (basis of our `peer.sh`)
- `command-fable-orchestrate.md` — upstream slash-command activator
  (upstream path: `plugin/commands/fable-orchestrate.md`)
- `LICENSE` — upstream license text

## Sync procedure

```bash
base=https://raw.githubusercontent.com/scdenney/open-science-skills/main
for f in SKILL.md agents/deep-reasoner.md agents/fast-worker.md codex-peer.sh; do
  curl -sf "$base/plugin/skills/fable-orchestrate/$f" | diff -u "vendor/fable-orchestrate/$f" - || true
done
curl -sf "$base/plugin/commands/fable-orchestrate.md" | diff -u vendor/fable-orchestrate/command-fable-orchestrate.md - || true
```

Review any diffs, decide per hunk whether to absorb the change into
`skills/orchestrate/` (that's a skill edit → tests/RUNBOOK.md iron law
applies), then refresh this snapshot verbatim and update the **Fetched** /
**Upstream commit** fields above (`git -C <clone> rev-parse HEAD`, or the
`sha` field from the GitHub contents API).
