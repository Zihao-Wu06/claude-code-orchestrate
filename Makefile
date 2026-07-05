# claude-code-orchestrate — maintenance targets
# `make check` is the single source of truth for repo health; CI runs it too.

SHELL := /bin/bash
SCRIPTS := plugin/skills/orchestrate/peer.sh $(wildcard scripts/*.sh)

.PHONY: help check install validate bump-version eval-view

help:
	@echo "Targets:"
	@echo "  check         bash -n + shellcheck + manifest JSON + CI YAML + file integrity"
	@echo "  install       manual install into ~/.claude (see README for the plugin flow)"
	@echo "  validate      claude plugin validate . --strict"
	@echo "  bump-version  V=x.y.z  update version in both plugin manifests atomically"
	@echo "  eval-view     print the command to regenerate the eval review viewer"

check:
	@echo "== shell syntax =="
	@bash -n $(SCRIPTS)
	@echo "== shellcheck =="
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck -S warning $(SCRIPTS); \
	else \
		echo "shellcheck not installed — skipped locally (CI always runs it)"; \
	fi
	@echo "== plugin manifests =="
	@jq empty plugin/.claude-plugin/plugin.json .claude-plugin/marketplace.json
	@v1=$$(jq -r .version plugin/.claude-plugin/plugin.json); \
	 v2=$$(jq -r '.plugins[0].version' .claude-plugin/marketplace.json); \
	 if [ "$$v1" != "$$v2" ]; then echo "version drift: plugin.json=$$v1 marketplace.json=$$v2"; exit 1; fi; \
	 echo "version $$v1 (manifests agree)"
	@echo "== CI workflow YAML =="
	@python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml')); print('YAML OK')" 2>/dev/null \
	  || ruby -ryaml -e "YAML.load_file('.github/workflows/ci.yml'); puts 'YAML OK'"
	@echo "== file integrity =="
	@test -f LICENSE && test -f CHANGELOG.md && test -f CONTRIBUTING.md
	@test -f plugin/skills/orchestrate/SKILL.md
	@test -f plugin/skills/orchestrate/dispatch-prompt.md
	@test -f plugin/skills/orchestrate/patterns.md
	@test -f plugin/skills/orchestrate/agent-TEMPLATE.md
	@grep -q "patterns.md" plugin/skills/orchestrate/SKILL.md
	@test -f plugin/commands/orchestrate.md
	@for a in deep-reasoner fast-worker scout; do test -f "plugin/agents/$$a.md" || { echo "missing plugin/agents/$$a.md"; exit 1; }; done
	@for s in A-trivial B-conflict C-recon; do test -f "tests/scenarios/$$s.md" || { echo "missing tests/scenarios/$$s.md"; exit 1; }; done
	@test -f tests/RUNBOOK.md && test -f tests/records/results.md && test -f tests/README.md
	@grep -q "dispatch-prompt.md" plugin/skills/orchestrate/SKILL.md
	@echo "== all checks passed =="

install:
	./scripts/install.sh

validate:
	claude plugin validate . --strict
	claude plugin validate ./plugin --strict

bump-version:
	@test -n "$(V)" || { echo "usage: make bump-version V=x.y.z"; exit 1; }
	scripts/bump-version.sh "$(V)"

eval-view:
	@echo "Regenerate the eval viewer (requires the skill-creator plugin locally):"
	@echo "  cd <skill-creator-dir> && python3 eval-viewer/generate_review.py \\"
	@echo "    $$(pwd)/tests/evals/iteration-1 --skill-name orchestrate \\"
	@echo "    --benchmark $$(pwd)/tests/evals/iteration-1/benchmark.json \\"
	@echo "    --static $$(pwd)/tests/evals/iteration-1/review.html"
	@echo "See tests/RUNBOOK.md for the full eval rerun procedure."
