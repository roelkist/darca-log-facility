.PHONY: all format lint test security check requirements precommit docs

# Default target: run tests
all: test

# Auto-format code using Black and isort via tox
format:
	tox -e format

# Linting using pre-commit (flake8, black, isort, bandit) via tox
lint:
	tox -e lint

# Run tests with pytest inside tox environments
test:
	tox -e test

# Check that `make requirements` is up-to-date
requirements:
	tox -e requirements

# Check that `pre-commit autoupdate` is up-to-date
precommit:
	tox -e precommit

# Generate documentation
docs:
	tox -e docs

# Run all checks before pushing code (format, lint, test, requirements, precommit)
check: format lint test requirements precommit
ci: precommit lint test 