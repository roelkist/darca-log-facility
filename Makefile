SHELL := /bin/bash  # Ensure Makefile runs in Bash

# .SILENT:  # Suppress unnecessary make output

.PHONY: all install format test precommit docs check ci clean

# Define virtual environment path
VENV_PATH := $(HOME)/.venvs/darca-log-facility
POETRY := $(VENV_PATH)/bin/poetry

# Detect if running in CI (GitHub Actions)
ifdef CI
    RUN = poetry run
    INSTALL_CMD = poetry install --with dev,docs
else
    RUN = $(VENV_PATH)/bin/poetry run
    INSTALL_CMD = $(POETRY) install --with dev,docs
endif

# Ensure the virtual environment exists (only when running locally)
$(VENV_PATH):
	@if [ -z "$$CI" ]; then \
		echo "📦 Creating virtual environment..."; \
		python3 -m venv $(VENV_PATH); \
		$(VENV_PATH)/bin/pip install poetry; \
		echo "✅ Virtual environment ready!"; \
	fi

# Install project dependencies using Poetry
install: $(VENV_PATH)
	@echo "📦 Installing dependencies..."
	@$(INSTALL_CMD)
	@echo "✅ Dependencies installed!"

# Run code formatters
format: $(VENV_PATH)
	@echo "🎨 Formatting code..."
	@$(RUN) black .
	@$(RUN) isort .
	@echo "✅ Formatting complete!"

# Run linting
precommit: $(VENV_PATH)
	@echo "🔍 Running pre-commit hooks..."
	@$(RUN) pre-commit run --all-files
	@echo "✅ Pre-commit checks passed!"

# Run tests with pytest
test: $(VENV_PATH)
	@echo "🧪 Running tests..."
	@$(RUN) pytest --cov-report=xml --cov-report=html --cov -n auto -vv tests/
	@echo "✅ Tests completed!"

# Build documentation
docs: $(VENV_PATH)
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
	@rm -rf $(VENV_PATH)
	@echo "✅ Cleaned up!"
