Contributing to Darca File Utils
================================

We welcome contributions from the community! This document outlines the guidelines for contributing
to Darca File Utils, including setting up your development environment, coding standards, and the
process for submitting pull requests.

Getting Started
---------------

1. **Fork the Repository:**  
   Visit https://github.com/roelkist/darca-file-utils and fork the project to your own GitHub account.

2. **Clone Your Fork:**  
   Clone the repository locally:
   
   .. code-block:: bash

      git clone https://github.com/your-username/darca-file-utils.git
      cd darca-file-utils

3. **Create a Feature Branch:**  
   Create a new branch for your feature or bug fix:
   
   .. code-block:: bash

      git checkout -b feature/your-feature-name

4. **Set Up Your Environment:**  
   Create and activate a virtual environment, then install development dependencies:
   
   .. code-block:: bash

      python -m venv venv
      source venv/bin/activate  # On Windows: venv\Scripts\activate
      pip install -r requirements-dev.txt

Coding Standards and Testing
----------------------------

- **Formatting and Linting:**  
  The project uses Black for code formatting and Flake8 for linting. To check your code, run:

  .. code-block:: bash

      tox -e lint

- **Running Tests:**  
  Ensure that all tests pass by running:

  .. code-block:: bash

      tox

- **Pre-commit Hooks:**  
  Pre-commit hooks are configured to enforce code quality before commits. Install them with:

  .. code-block:: bash

      pre-commit install

  And run them manually with:

  .. code-block:: bash

      pre-commit run --all-files

Submitting a Pull Request
-------------------------

1. **Push Your Branch:**  
   Once your changes are ready, push your branch to your fork:

   .. code-block:: bash

      git push origin feature/your-feature-name

2. **Open a Pull Request:**  
   On GitHub, open a pull request against the ``main`` branch of the upstream repository.
   Include a clear description of your changes and reference any related issues.

3. **Review Process:**  
   The maintainers will review your pull request and may request changes or merge it after
   approval.

Reporting Issues
----------------

If you encounter any bugs or have feature requests, please open an issue on the GitHub repository
with a detailed description of the problem or enhancement.

Thank you for contributing to Darca File Utils!
