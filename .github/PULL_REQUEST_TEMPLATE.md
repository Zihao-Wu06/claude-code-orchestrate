# What & why

<!-- What problem does this solve? What broke, or what was missing?
     One concern per PR — split unrelated changes. -->

## Skill-change gate (required)

<!-- The behavioral files are: plugin/skills/orchestrate/SKILL.md,
     plugin/skills/orchestrate/dispatch-prompt.md, plugin/agents/*.md.
     Editing ANY of them — including "just wording" — requires rerunning the
     behavior scenarios per tests/RUNBOOK.md before this PR is reviewable.
     Rounds 4–6 in tests/results.md were all reruns for exactly such edits. -->

- [ ] **No skill files touched** — this PR changes docs/tooling/CI only
- [ ] **Skill files touched** — RUNBOOK rerun done; results table pasted below:

<!-- paste the A/B/C verdict table here if the second box is checked -->

## Verification

<!-- Paste the tail of `make check`. If you changed peer.sh or install.sh,
     note any manual smoke test you ran (e.g. peer.sh PONG consult). -->

```
$ make check

```

## License acknowledgement

- [ ] I understand contributions land under [CC BY-NC 4.0](../LICENSE)
      (noncommercial use, attribution required).
