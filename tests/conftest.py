import logging
import os
import shutil

import pytest


@pytest.fixture(scope="function")
def temp_log_dir():
    """Ensures log directory exists and cleans it up after tests."""
    log_dir = "/tmp/temp_logs"

    # Recreate the directory for every test to ensure consistency
    if os.path.exists(log_dir):
        shutil.rmtree(log_dir)
    os.makedirs(log_dir, exist_ok=True)

    yield log_dir  # Provide the directory to the test

    # Close all log handlers before cleanup
    for logger_name in logging.root.manager.loggerDict:
        logger = logging.getLogger(logger_name)
        for handler in logger.handlers[:]:
            handler.close()
            logger.removeHandler(handler)

    # Cleanup directory safely
    if os.path.exists(log_dir):
        shutil.rmtree(log_dir)
