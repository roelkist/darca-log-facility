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

# Ensure virtual environment exists and Poetry is installed (only locally)
ifeq ($(CI),false)  # Skip this in GitHub Actions
$(VENV_PATH):
	@echo "📦 Creating virtual environment in $(VENV_PATH)..."
	python3 -m venv $(VENV_PATH)
	$(VENV_PATH)/bin/pip install pipx
	$(VENV_PATH)/bin/pipx install poetry
	@echo "✅ Virtual environment ready with Poetry!"

$(POETRY_BIN): $(VENV_PATH)
	@if [ ! -f "$(POETRY_BIN)" ]; then \
		echo "🚀 Installing Poetry inside the virtual environment..."; \
		$(VENV_PATH)/bin/pipx install poetry; \
	fi
endif

# Install project dependencies
install:
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

# Run formatters
format:
	@echo "🎨 Formatting code..."
	@$(RUN) black .
	@$(RUN) isort .
	@echo "✅ Formatting complete!"

# Run linting (pre-commit hooks)
precommit:
	@echo "🔍 Running pre-commit hooks..."
	@$(RUN) pre-commit run --all-files
	@echo "✅ Pre-commit checks passed!"

# Run tests with pytest
test:
	@echo "🧪 Running tests..."
	@$(RUN) pytest --cov-report=xml --cov-report=html --cov -n auto -vv tests/
	@echo "✅ Tests completed!"

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
