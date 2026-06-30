# jaspr-ribbon-toolbar — development harness.
#
# The make targets below are the canonical commands for this project. Agents
# and humans should use these rather than invoking dart directly, so the
# workflow stays consistent. `make verify` is the CI gate.

DART := dart
MEMBERS := packages/jaspr_ribbon_toolbar packages/jaspr_ribbon_lsp

.PHONY: help pub-get fmt fmt-check analyze test verify docs lint-ribbon clean doctor serve-example

help: ## Show this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z_-]+:.*##/ {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

pub-get: ## Resolve workspace dependencies
	$(DART) pub get

fmt: ## Apply dart formatting
	$(DART) format $(MEMBERS)

fmt-check: ## Fail if any file is not formatted
	$(DART) format --output=none --set-exit-if-changed $(MEMBERS)

analyze: ## Run dart analyze (fatal on infos)
	$(DART) analyze $(MEMBERS) --fatal-infos

test: ## Run dart test in every member that has tests
	@bash tool/test.sh

verify: ## CI gate: fmt-check + analyze + test
	@bash tool/verify.sh

docs: ## Generate API reference into api/ (jaspr_ribbon_toolbar package)
	cd packages/jaspr_ribbon_toolbar && $(DART) doc --output ../../api
	@echo "Open api/index.html"

lint-ribbon: ## Validate .ribbon bundles: make lint-ribbon FILE=examples/explorer.ribbon
	@if [ -z "$(FILE)" ]; then echo "Usage: make lint-ribbon FILE=path/to/x.ribbon"; exit 64; fi
	@bash tool/lint-ribbon.sh "$(FILE)"

clean: ## Remove build artifacts
	$(DART) pub global deactivate jaspr_cli 2>/dev/null || true
	@for m in $(MEMBERS); do rm -rf $$m/.dart_tool $$m/build; done
	rm -rf .dart_tool build api coverage

doctor: ## Print toolchain + project info
	@bash tool/doctor.sh

# --- Optional targets that auto-install the Jaspr CLI ------------------------
JASPR := $(shell command -v jaspr 2>/dev/null)

ensure-jaspr:
	@if [ -z "$(JASPR)" ]; then echo "Installing jaspr CLI…"; $(DART) pub global activate jaspr_cli; fi

serve-example: ensure-jaspr ## (future) Serve the example app — wired in milestone 2
	@echo "Example app lands in milestone 2 (canvas renderer)."
