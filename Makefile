# claude-code-orchestrate — maintenance targets
# `make check` is the single source of truth for repo health; CI runs it too.

SHELL := /bin/bash
SCRIPTS := plugin/skills/orchestrate/peer.sh $(wildcard scripts/*.sh)

.PHONY: help check smoke-install install validate bump-version eval-view

help:
	@echo "Targets:"
	@echo "  check         syntax + shellcheck + manifests + YAML + integrity + links + peer mock"
	@echo "  smoke-install install into a throwaway CLAUDE_DIR: placement, idempotence, stale cleanup"
	@echo "  install       manual install into ~/.claude (see README for the plugin flow)"
	@echo "  validate      claude plugin validate --strict (marketplace + plugin)"
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
	@for f in LICENSE CHANGELOG.md CONTRIBUTING.md \
	          plugin/skills/orchestrate/SKILL.md \
	          plugin/skills/orchestrate/dispatch-prompt.md \
	          plugin/skills/orchestrate/patterns.md \
	          plugin/skills/orchestrate/agent-TEMPLATE.md \
	          plugin/commands/orchestrate.md \
	          plugin/agents/deep-reasoner.md plugin/agents/fast-worker.md plugin/agents/scout.md \
	          tests/scenarios/A-trivial.md tests/scenarios/B-conflict.md tests/scenarios/C-recon.md \
	          tests/RUNBOOK.md tests/records/results.md tests/README.md; do \
	  test -f "$$f" || { echo "missing $$f"; exit 1; }; \
	done
	@for ref in dispatch-prompt.md patterns.md; do \
	  grep -q "$$ref" plugin/skills/orchestrate/SKILL.md || { echo "SKILL.md no longer references $$ref"; exit 1; }; \
	done
	@echo "== markdown relative links =="
	@python3 scripts/check-links.py
	@echo "== peer.sh mock smoke =="
	@bash tests/shell/test-peer.sh
	@echo "== all checks passed =="

smoke-install:
	@T=$$(mktemp -d); \
	 echo "== install smoke: placement =="; \
	 CLAUDE_DIR="$$T" ./scripts/install.sh > /dev/null; \
	 for f in skills/orchestrate/SKILL.md skills/orchestrate/dispatch-prompt.md \
	          skills/orchestrate/patterns.md skills/orchestrate/peer.sh \
	          skills/orchestrate/agent-TEMPLATE.md skills/orchestrate/.installed-agents \
	          agents/deep-reasoner.md agents/fast-worker.md agents/scout.md \
	          commands/orchestrate.md; do \
	   test -e "$$T/$$f" || { echo "smoke FAIL: missing $$f"; exit 1; }; \
	 done; \
	 test -x "$$T/skills/orchestrate/peer.sh" || { echo "smoke FAIL: peer.sh not executable"; exit 1; }; \
	 echo "placement OK"; \
	 echo "== install smoke: idempotence =="; \
	 CLAUDE_DIR="$$T" ./scripts/install.sh > /dev/null && echo "second run OK"; \
	 echo "== install smoke: stale-agent cleanup =="; \
	 touch "$$T/agents/old-role.md" "$$T/agents/user-own-agent.md"; \
	 echo "old-role" >> "$$T/skills/orchestrate/.installed-agents"; \
	 CLAUDE_DIR="$$T" ./scripts/install.sh > /dev/null; \
	 test ! -f "$$T/agents/old-role.md" || { echo "smoke FAIL: stale agent not removed"; exit 1; }; \
	 test -f "$$T/agents/user-own-agent.md" || { echo "smoke FAIL: touched a user agent outside the manifest"; exit 1; }; \
	 echo "stale cleanup OK (user files untouched)"; \
	 rm -rf "$$T"

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
