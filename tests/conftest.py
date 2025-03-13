import logging
import os
import shutil
import tempfile

import pytest


@pytest.fixture(scope="function")
def temp_log_dir():
    """Creates an isolated temporary log directory for each test and
    cleans up afterward."""
    log_dir = tempfile.mkdtemp(
        prefix="darca_logs_"
    )  # Create a unique temp dir for each test

    yield log_dir  # Provide the directory to the test

    # Close all log handlers before cleanup
    for logger_name in logging.root.manager.loggerDict:
        logger = logging.getLogger(logger_name)
        for handler in logger.handlers[:]:
            handler.close()
            logger.removeHandler(handler)

    # Ensure cleanup after tests
    if os.path.exists(log_dir):
        shutil.rmtree(log_dir)
