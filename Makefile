SHELL := /bin/bash  # Ensure Makefile runs in Bash

.SILENT:  # Suppress unnecessary make output

.PHONY: all install add-deps format test precommit docs check ci clean

# Store virtual environment and Poetry cache outside of NFS
VENV_PATH := /tmp/darca-log-venv
POETRY_HOME := /tmp/poetry-cache
POETRY_CONFIG_DIR := /tmp/poetry-config  # Override global Poetry config
PYTHONPYCACHEPREFIX := /tmp/pycache

# Define Poetry executable inside the virtual environment
POETRY_BIN := $(VENV_PATH)/bin/poetry

# Abstract the Poetry execution to always set the correct environment
define POETRY_EXEC
    POETRY_CONFIG_DIR=$(POETRY_CONFIG_DIR) \
    POETRY_HOME=$(POETRY_HOME) \
    POETRY_CACHE_DIR=$(POETRY_HOME) \
    POETRY_VIRTUALENVS_PATH=$(VENV_PATH) \
    PYTHONPYCACHEPREFIX=$(PYTHONPYCACHEPREFIX) \
    PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring \
    $(POETRY_BIN) $(1)
endef

# Detect if running in CI (GitHub Actions)
ifdef CI
    RUN = poetry run
    INSTALL_CMD = $(call POETRY_EXEC,install --no-cache --with dev,docs --no-interaction)
else
    RUN = $(POETRY_BIN) run
    INSTALL_CMD = $(call POETRY_EXEC,install --no-cache --with dev,docs --no-interaction)
endif

# Ensure the virtual environment exists and has Poetry installed
$(VENV_PATH):
	@if [ -z "$$CI" ]; then \
		echo "📦 Creating virtual environment in $(VENV_PATH)..."; \
		python3 -m venv $(VENV_PATH); \
		$(VENV_PATH)/bin/pip install pipx; \
		$(VENV_PATH)/bin/pipx install poetry; \
		echo "✅ Virtual environment ready with Poetry!"; \
	fi

# Ensure Poetry is available
$(POETRY_BIN):
	@if [ ! -f "$(POETRY_BIN)" ]; then \
		echo "🚀 Installing Poetry inside the virtual environment..."; \
		$(VENV_PATH)/bin/pipx install poetry; \
	fi

# Install project dependencies using Poetry (inside the venv)
install: $(VENV_PATH) $(POETRY_BIN)
	@echo "📦 Configuring Poetry settings..."
	@$(call POETRY_EXEC,config cache-dir $(POETRY_HOME))
	@$(call POETRY_EXEC,config virtualenvs.path $(VENV_PATH))
	@$(call POETRY_EXEC,config virtualenvs.in-project false)
	@$(call POETRY_EXEC,config virtualenvs.create true)
	@$(call POETRY_EXEC,config installer.parallel false)
	@echo "✅ Poetry configured!"

	@echo "📦 Installing dependencies..."
	@$(INSTALL_CMD)
	@echo "✅ Dependencies installed!"

# 🔥 NEW: Generic make target for adding dependencies dynamically
add-deps: $(VENV_PATH) $(POETRY_BIN)
	@if [ -z "$(group)" ] || [ -z "$(deps)" ]; then \
		echo "❌ Usage: make add-deps group=<group-name> deps='<package1> <package2>'"; \
		exit 1; \
	fi
	@echo "🔄 Adding dependencies to group '$(group)': $(deps)"
	@$(call POETRY_EXEC,add --group $(group) $(deps))
	@echo "✅ Dependencies added successfully!"

# Run code formatters
format: $(VENV_PATH) $(POETRY_BIN)
	@echo "🎨 Formatting code..."
	@$(RUN) black .
	@$(RUN) isort .
	@echo "✅ Formatting complete!"

# Run linting
precommit: $(VENV_PATH) $(POETRY_BIN)
	@echo "🔍 Running pre-commit hooks..."
	@$(RUN) pre-commit run --all-files
	@echo "✅ Pre-commit checks passed!"

# Run tests with pytest
test: $(VENV_PATH) $(POETRY_BIN)
	@echo "🧪 Running tests..."
	@$(RUN) pytest --cov-report=xml --cov-report=html --cov -n auto -vv tests/
	@echo "✅ Tests completed!"

# Build documentation
docs: $(VENV_PATH) $(POETRY_BIN)
	@echo "📖 Building documentation..."
	@$(RUN) sphinx-build -E -W -b html docs/source docs/build/html
	@echo "✅ Documentation built!"

# Run all checks before pushing code (Ensure formatting before precommit)
check: install format precommit test
	@echo "✅ All checks passed!"

# CI pipeline (Ensure formatting before precommit)
ci: install precommit test
	@echo "✅ CI checks completed!"

# Remove the virtual environment (cleanup)
clean:
	@echo "🗑 Removing virtual environment..."
	@rm -rf $(VENV_PATH) $(POETRY_HOME) $(POETRY_CONFIG_DIR) $(PYTHONPYCACHEPREFIX)
	@echo "✅ Cleaned up!"
