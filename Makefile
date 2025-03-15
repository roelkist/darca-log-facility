SHELL := /bin/bash  # Ensure Bash is used

.SILENT:  # Suppress unnecessary make output

.PHONY: all install add-deps format test precommit docs check ci clean

# Store virtual environment and Poetry cache outside of NFS
VENV_PATH := /tmp/darca-log-venv
POETRY_HOME := /tmp/poetry-cache
POETRY_CONFIG_DIR := /tmp/poetry-config
PYTHONPYCACHEPREFIX := /tmp/pycache

# Define Poetry executable inside the virtual environment
POETRY_BIN := $(VENV_PATH)/bin/poetry

# Abstract Poetry execution with correct environment variables
RUN_POETRY = POETRY_CONFIG_DIR=$(POETRY_CONFIG_DIR) \
             POETRY_HOME=$(POETRY_HOME) \
             POETRY_CACHE_DIR=$(POETRY_HOME) \
             POETRY_VIRTUALENVS_PATH=$(VENV_PATH) \
             PYTHONPYCACHEPREFIX=$(PYTHONPYCACHEPREFIX) \
             PYTHON_KEYRING_BACKEND=keyring.backends.null.Keyring \
             $(POETRY_BIN)

# Detect CI and use system Poetry when applicable
ifeq ($(CI),true)
    RUN = poetry run
    INSTALL_CMD = poetry install --no-cache --with dev,docs --no-interaction
else
    RUN = $(POETRY_BIN) run
    INSTALL_CMD = $(RUN_POETRY) install --no-cache --with dev,docs --no-interaction
endif

# Ensure virtual environment exists and Poetry is installed
$(VENV_PATH):
	@if [ -z "$$CI" ]; then \
		echo "📦 Creating virtual environment in $(VENV_PATH)..."; \
		python3 -m venv $(VENV_PATH); \
		$(VENV_PATH)/bin/pip install pipx; \
		$(VENV_PATH)/bin/pipx install poetry; \
		echo "✅ Virtual environment ready with Poetry!"; \
	fi

# Ensure Poetry is available
$(POETRY_BIN): $(VENV_PATH)
	@if [ ! -f "$(POETRY_BIN)" ]; then \
		echo "🚀 Installing Poetry inside the virtual environment..."; \
		$(VENV_PATH)/bin/pipx install poetry; \
	fi

# Install project dependencies
install: $(VENV_PATH) $(POETRY_BIN)
	@echo "📦 Installing dependencies..."
	@$(INSTALL_CMD)

# 🔥 Generic make target for adding dependencies dynamically
add-deps: $(VENV_PATH) $(POETRY_BIN)
	@if [ -z "$(group)" ] || [ -z "$(deps)" ]; then \
		echo "❌ Usage: make add-deps group=<group-name> deps='<package1> <package2>'"; \
		exit 1; \
	fi
	@echo "🔄 Adding dependencies to group '$(group)': $(deps)"
	@$(RUN_POETRY) add --group $(group) $(deps)
	@echo "✅ Dependencies added successfully!"

# Run formatters
format: $(VENV_PATH) $(POETRY_BIN)
	@echo "🎨 Formatting code..."
	@$(RUN) black .
	@$(RUN) isort .
	@echo "✅ Formatting complete!"

# Run linting (pre-commit hooks)
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

# Run all checks before pushing code
check: install format precommit test
	@echo "✅ All checks passed!"

# CI pipeline (format, precommit, test)
ci: install precommit test
	@echo "✅ CI checks completed!"

# Cleanup virtual environment
clean:
	@echo "🗑 Removing virtual environment..."
	@rm -rf $(VENV_PATH) $(POETRY_HOME) $(POETRY_CONFIG_DIR) $(PYTHONPYCACHEPREFIX)
	@echo "✅ Cleaned up!"
