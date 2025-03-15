import logging
import os
import time

import pytest

from darca_log_facility.logger import DarcaLogger


@pytest.fixture
def logger_instance(temp_log_dir, request):
    """Creates a fresh instance of DarcaLogger for testing."""
    return DarcaLogger(
        name=request.node.name, log_directory=temp_log_dir, level=logging.DEBUG
    )


def test_logger_creation(logger_instance, request):
    """Ensure DarcaLogger initializes correctly."""
    logger = logger_instance.get_logger()
    expected_logger_name = (
        request.node.name
    )  # Logger name should match the test name
    assert (
        logger.name == expected_logger_name
    ), f"Expected logger name '{expected_logger_name}', got '{logger.name}'"


def test_logging_levels(logger_instance, temp_log_dir):
    """Verify log messages appear at the correct levels."""
    logger = logger_instance.get_logger()

    # Ensure log file exists before checking rotation
    log_file_path = os.path.join(temp_log_dir, "test_logging_levels.log")

    logger.info("Test log message")
    for handler in logger.handlers:
        handler.flush()

    for _ in range(10):
        if os.path.exists(log_file_path):
            break
        time.sleep(0.1)

    assert os.path.exists(
        log_file_path
    ), f"Log file does not exist: {log_file_path}"

    rotated_file_path = os.path.join(temp_log_dir, "test_log_rotation.log.2")
    if os.path.exists(rotated_file_path):
        with open(rotated_file_path, "r", encoding="utf-8") as f:
            rotated_content = f.read()
        assert (
            "Test log message" in rotated_content
        ), "Rotated log file missing expected content"


def test_log_file_creation(logger_instance, temp_log_dir, request):
    """Check if log file is created when logging to file is enabled."""
    logger = logger_instance.get_logger()
    log_file_path = os.path.join(temp_log_dir, f"{request.node.name}.log")

    logger.info("Test log message")

    # Ensure all handlers flush logs to file
    for handler in logger.handlers:
        handler.flush()

    # Retry checking file existence (to prevent race conditions)
    for _ in range(10):
        if os.path.exists(log_file_path):
            break
        time.sleep(0.1)

    assert os.path.exists(
        log_file_path
    ), f"Log file was not created: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert "Test log message" in log_content, "Log message not written to file"


def test_log_rotation(temp_log_dir, request):
    """Ensure log rotation works by exceeding the max log file size."""
    log_name = request.node.name  # Unique log file name per test
    logger = DarcaLogger(
        name=log_name,
        log_directory=temp_log_dir,
        max_file_size=100,  # Small size to trigger rotation quickly
        backup_count=3,  # Keep 3 rotated log files
    ).get_logger()

    log_file_path = os.path.join(temp_log_dir, f"{log_name}.log")

    # Generate logs to exceed the file size and trigger rotation
    for _ in range(100):  # More iterations to ensure rotation triggers
        logger.info(
            "This is a long log message to exceed the file size limit."
        )

    # Ensure all logs are flushed to file
    for handler in logger.handlers:
        handler.flush()

    # Retry checking file existence (to prevent race conditions)
    for _ in range(10):
        if os.path.exists(log_file_path):
            break
        time.sleep(0.1)

    assert os.path.exists(
        log_file_path
    ), f"Log file does not exist: {log_file_path}"

    # Check that rotated log files exist
    rotated_files = [f for f in os.listdir(temp_log_dir) if log_name in f]
    assert (
        len(rotated_files) > 1
    ), f"Log rotation did not happen for {log_name}"

    # Verify specific rotated files exist
    for i in range(1, 3):  # Checking for .1 and .2 rotated files
        rotated_file = os.path.join(temp_log_dir, f"{log_name}.log.{i}")
        assert os.path.exists(
            rotated_file
        ), f"Rotated log file missing: {rotated_file}"


def test_json_logging(temp_log_dir, request):
    """Verify JSON log format is correctly applied."""
    log_name = request.node.name  # Unique log file name
    logger = DarcaLogger(
        name=log_name, log_directory=temp_log_dir, json_format=True
    ).get_logger()

    log_file_path = os.path.join(temp_log_dir, f"{log_name}.log")
    logger.info("JSON format test")

    # Ensure all handlers flush logs to file
    for handler in logger.handlers:
        handler.flush()

    # Retry checking file existence
    for _ in range(10):
        if os.path.exists(log_file_path):
            break
        time.sleep(0.1)

    assert os.path.exists(
        log_file_path
    ), f"JSON log file was not created: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert '"level": "INFO"' in log_content, "JSON formatting failed"
    assert (
        '"message": "JSON format test"' in log_content
    ), "Log message missing in JSON output"

    # Handle log rotation check dynamically
    for i in range(1, 4):  # Check up to 3 backup files
        rotated_log = os.path.join(temp_log_dir, f"test_log_rotation.log.{i}")
        if os.path.exists(rotated_log):
            with open(rotated_log, "r", encoding="utf-8") as f:
                rotated_content = f.read()
            assert (
                "JSON format test" in rotated_content
            ), f"Rotated log file {rotated_log} missing expected content"


def test_dynamic_log_level_change(logger_instance, temp_log_dir, request):
    """Ensure log levels can be changed dynamically."""
    logger = logger_instance.get_logger()
    logger_instance.set_level(logging.ERROR)

    log_file_path = os.path.join(temp_log_dir, f"{request.node.name}.log")

    logger.error("Error log message")

    # Ensure logs are flushed before checking for existence
    for handler in logger.handlers:
        handler.flush()

    # Retry checking file existence (prevent race conditions)
    for _ in range(10):
        if os.path.exists(log_file_path):
            break
        time.sleep(0.1)

    assert os.path.exists(
        log_file_path
    ), f"Log file does not exist: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert "Error log message" in log_content, "Log message missing in file"
