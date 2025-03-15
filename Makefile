.PHONY: all install format lint test security check precommit docs

# Default target: run tests
all: test

# Install dependencies
install:
	poetry install --with dev,docs

# Auto-format code using Black and isort
format:
	poetry run black .
	poetry run isort .

# Linting using pre-commit hooks (flake8, black, isort, bandit)
lint:
	poetry run pre-commit run flake8 --all-files --show-diff-on-failure
	poetry run pre-commit run isort --all-files --show-diff-on-failure
	poetry run pre-commit run black --all-files --show-diff-on-failure
	poetry run pre-commit run bandit --all-files --show-diff-on-failure

# Run tests with pytest and generate coverage
test:
	poetry run pytest --cov=darca_log_facility --cov-report=xml --cov-report=html --cov-report=term -n auto -vv tests/
	poetry run coverage-badge -o coverage.svg

# Run pre-commit hooks
precommit:
	poetry run pre-commit run --all-files

# Generate documentation
docs:
	poetry run sphinx-build -b html docs/source docs/build/html

# Run all checks before pushing code (ensure install runs first)
check: install precommit format lint test 

# CI pipeline (ensure install runs first)
ci: install precommit lint test 
