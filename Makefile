SHELL := /bin/bash  # Ensure Bash is used

.SILENT:  # Suppress unnecessary make output

.PHONY: all install add-deps format test precommit docs check ci clean venv poetry

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

# Detect if running in CI (GitHub Actions)
ifdef CI
    PRE_COMMIT_CACHE := ~/.cache/pre-commit
else
    PRE_COMMIT_CACHE := /tmp/precommit-cache
endif

# Detect CI and use system Poetry when applicable
ifeq ($(CI),true)
    RUN = poetry run
    INSTALL_CMD = poetry install --no-cache --with dev,docs --no-interaction
else
    RUN = $(POETRY_BIN) run
    INSTALL_CMD = $(RUN_POETRY) install --no-cache --with dev,docs --no-interaction
endif

# Ensure virtual environment exists before installing Poetry
venv:
	@if [ ! -d "$(VENV_PATH)" ]; then \
		echo "📦 Creating virtual environment in $(VENV_PATH)..."; \
		python3 -m venv $(VENV_PATH); \
		$(VENV_PATH)/bin/pip install --quiet --upgrade pip; \
		echo "✅ Virtual environment created!"; \
	fi

# Ensure Poetry is installed **inside** the virtual environment
poetry: venv
	@if [ ! -f "$(POETRY_BIN)" ]; then \
		echo "🚀 Installing Poetry inside the virtual environment..."; \
		$(VENV_PATH)/bin/pip install --quiet poetry; \
		echo "✅ Poetry installed successfully in $(VENV_PATH)!"; \
	fi

# Install project dependencies (ensuring Poetry is installed first)
install: poetry
ifeq ($(CI),true)
	@echo "🤖 Running inside GitHub Actions - Using system Poetry..."
	poetry install --no-cache --with dev,docs --no-interaction
else
	@echo "📦 Installing dependencies using Poetry..."
	@$(INSTALL_CMD)
endif

# 🔥 Generic make target for adding dependencies dynamically
add-deps:
	@if [ -z "$(group)" ] || [ -z "$(deps)" ]; then \
		echo "❌ Usage: make add-deps group=<group-name> deps='<package1> <package2>'"; \
		exit 1; \
	fi
	@echo "🔄 Adding dependencies to group '$(group)': $(deps)"
	@$(RUN_POETRY) add --group $(group) $(deps)
	@echo "✅ Dependencies added successfully!"

add-prod-deps:
	@if [ -z "$(deps)" ]; then \
		echo "❌ Usage: make add-prod-deps deps='<package1> <package2>'"; \
		exit 1; \
	fi
	@echo "🔄 Adding production dependencies: $(deps)"
	@$(RUN_POETRY) add $(deps)
	@echo "✅ Dependencies added successfully!"
	
# Run formatters (apply changes)
format:
	@echo "🎨 Auto-formatting code..."
	@$(RUN) isort -l79 --profile black .
	@$(RUN) black -l79 .
	@echo "✅ Formatting complete!"

# Run pre-commit hooks to check for issues (without fixing)
precommit:
	@echo "🔍 Running pre-commit hooks (checks only)..."
	@PRE_COMMIT_HOME=$(PRE_COMMIT_CACHE) $(RUN) pre-commit run --all-files --show-diff-on-failure
	@echo "✅ Pre-commit checks completed!"

# Run tests with pytest and generate an HTML coverage report
test:
	@echo "🧪 Running tests..."
	@COVERAGE_FILE=/tmp/.coverage $(RUN) pytest --cov=src --cov-report=html -n auto -vv tests/
	@echo "📊 Generating coverage badge..."
	@COVERAGE_FILE=/tmp/.coverage $(RUN) coverage-badge -o coverage.svg -f
	@echo "✅ Tests completed, and coverage badge generated!"

# Build documentation
docs:
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
