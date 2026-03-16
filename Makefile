.PHONY: test lint check install clean help

SCRIPTS := $(wildcard scripts/massive_*.sh)
LIB := scripts/_lib.sh

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

test: ## Run all tests
	@if command -v bats >/dev/null 2>&1; then \
		bats tests/; \
	else \
		echo "bats not found. Install: brew install bats-core or apt install bats"; \
		exit 1; \
	fi

lint: ## Run shellcheck on all scripts
	@shellcheck -x $(LIB) $(SCRIPTS)

check: lint test ## Run lint + test

install: ## Install scripts to ~/.local/bin
	@mkdir -p ~/.local/bin/massive-skill
	@cp scripts/*.sh ~/.local/bin/massive-skill/
	@chmod +x ~/.local/bin/massive-skill/*.sh
	@echo "Installed to ~/.local/bin/massive-skill/"

clean: ## Remove installed scripts
	@rm -rf ~/.local/bin/massive-skill
	@echo "Removed ~/.local/bin/massive-skill/"
