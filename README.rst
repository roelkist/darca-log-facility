==================================
Darca Log Facility
==================================

Darca Log Facility is a powerful, flexible, and structured logging utility for Python applications.
It provides configurable logging to both console and file, supports log rotation, and allows 
optional JSON formatting for structured logging.

Features
--------

- **Configurable logging levels** (DEBUG, INFO, WARNING, ERROR, CRITICAL).
- **File & Console Logging** (with log rotation to prevent excessive file sizes).
- **JSON Logging Format** (for structured logs, useful for log processors).
- **Colored Console Output** (using `colorlog` for improved readability).
- **Thread-safe Logging** (safe for multi-threaded applications).
- **Dynamically Change Log Level** (without restarting the application).

Installation
------------

To install Darca Log Facility, first, clone the repository:

.. code-block:: sh

    git clone https://github.com/roelkist/darca-log-facility.git
    cd darca-log-facility

Then install dependencies using Poetry:

.. code-block:: sh

    poetry install --with dev,docs

Makefile Usage
--------------

This project includes a `Makefile` to simplify common tasks.

- **Format code**:

  .. code-block:: sh

      make format

- **Run linting checks**:

  .. code-block:: sh

      make lint

- **Run tests**:

  .. code-block:: sh

      make test

- **Run pre-commit hooks**:

  .. code-block:: sh

      make precommit

- **Generate documentation**:

  .. code-block:: sh

      make docs

- **Run all pre-push checks (format, lint, test, precommit)**:

  .. code-block:: sh

      make check

- **Run full CI pipeline (precommit, lint, test)**:

  .. code-block:: sh

      make ci

Usage
-----

Basic usage example:

.. code-block:: python

    from darca_log_facility.logger import DarcaLogger
    import logging

    # Initialize logger
    logger = DarcaLogger(name="my_app", level=logging.INFO).get_logger()

    # Log messages
    logger.debug("This is a debug message")
    logger.info("This is an info message")
    logger.warning("This is a warning message")
    logger.error("This is an error message")
    logger.critical("This is a critical message")

File logging example:

.. code-block:: python

    logger = DarcaLogger(name="file_logger", log_directory="logs", log_to_file=True).get_logger()
    logger.info("This message will be written to a log file.")

JSON logging example:

.. code-block:: python

    logger = DarcaLogger(name="json_logger", log_directory="logs", json_format=True).get_logger()
    logger.info("This log is formatted as JSON.")

Configuration Options
---------------------

DarcaLogger supports multiple configuration options:

+--------------+----------------------------------------+------------------+
| Parameter    | Description                            | Default Value    |
+==============+========================================+==================+
| name         | Name of the logger                     | ``"app"``        |
+--------------+----------------------------------------+------------------+
| level        | Logging level (DEBUG, INFO, etc.)      | ``logging.INFO`` |
+--------------+----------------------------------------+------------------+
| log_directory| Directory to store log files           | ``"logs"``       |
+--------------+----------------------------------------+------------------+
| max_file_size| Max size of a log file before rotating | ``5MB``          |
+--------------+----------------------------------------+------------------+
| backup_count | Number of rotated log files to keep    | ``5``            |
+--------------+----------------------------------------+------------------+
| json_format  | Whether to format logs in JSON         | ``False``        |
+--------------+----------------------------------------+------------------+


Development and Contribution
----------------------------

We welcome contributions! Follow these steps to contribute:

1. Fork the repository: https://github.com/roelkist/darca-log-facility
2. Clone your forked repo:

   .. code-block:: sh

       git clone https://github.com/YOUR_USERNAME/darca-log-facility.git

3. Install dependencies using Poetry:

   .. code-block:: sh

       poetry install --with dev,docs

4. Run all checks before submitting code:

   .. code-block:: sh

       make check

5. Submit a pull request.

Testing
-------

Darca Log Facility uses `pytest` for testing. To run the test suite, use:

.. code-block:: sh

    make test

Continuous Integration (CI)
===========================

GitHub Actions runs the following pipeline automatically:

- **Pre-commit hooks**: `make precommit`
- **Linting**: `make lint`
- **Testing with coverage**: `make test`
- **Documentation build**: `make docs`
- **Coverage and documentation artifacts are uploaded**

Run the full pipeline locally with:

.. code-block:: bash

    make ci

License
-------

This project is licensed under the MIT License.

Contact
-------

- **GitHub Repository:** https://github.com/roelkist/darca-log-facility
- **Issues & Bug Reports:** https://github.com/roelkist/darca-log-facility/issues

Enjoy using Darca Log Facility! 🚀
