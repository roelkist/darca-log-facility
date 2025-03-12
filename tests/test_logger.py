import logging
import os

import pytest

from darca_log_facility.logger import DarcaLogger


@pytest.fixture
def logger_instance(temp_log_dir):
    """Creates a fresh instance of DarcaLogger for testing."""
    return DarcaLogger(
        name="test_logger", log_directory=temp_log_dir, level=logging.DEBUG
    )


def test_logger_creation(logger_instance):
    """Ensure DarcaLogger initializes correctly."""
    logger = logger_instance.get_logger()
    assert isinstance(logger, logging.Logger)
    assert logger.name == "test_logger"


def test_logging_levels(logger_instance, caplog):
    """Verify log messages appear at the correct levels."""
    logger = logger_instance.get_logger()

    # Ensure logger is propagating logs
    logger.propagate = True

    with caplog.at_level(logging.DEBUG):
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        logger.critical("Critical message")

    # Flush logs to ensure caplog captures them
    for handler in logger.handlers:
        handler.flush()

    assert (
        "Debug message" in caplog.text
    ), "DEBUG message missing in captured logs"
    assert (
        "Info message" in caplog.text
    ), "INFO message missing in captured logs"
    assert (
        "Warning message" in caplog.text
    ), "WARNING message missing in captured logs"
    assert (
        "Error message" in caplog.text
    ), "ERROR message missing in captured logs"
    assert (
        "Critical message" in caplog.text
    ), "CRITICAL message missing in captured logs"


def test_log_file_creation(logger_instance, temp_log_dir):
    """Check if log file is created when logging to file is enabled."""
    logger = logger_instance.get_logger()
    log_file_path = os.path.join(temp_log_dir, "test_logger.log")

    logger.info("Test log message")

    # Force flush to ensure the message is written
    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(
        log_file_path
    ), f"Log file was not created: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert "Test log message" in log_content, "Log message not written to file"


def test_log_rotation(logger_instance):
    """Ensure log rotation works by exceeding the max log file size."""
    logger = DarcaLogger(
        name="rotating_logger",
        log_directory="tests/temp_logs",
        max_file_size=100,  # Small size to trigger rotation
        backup_count=2,
    ).get_logger()

    log_file_path = os.path.join("tests/temp_logs", "rotating_logger.log")

    for _ in range(50):
        logger.info(
            "This is a long log message to exceed the file size limit."
        )

    assert os.path.exists(log_file_path), "Log file does not exist"

    rotated_files = [
        f for f in os.listdir("tests/temp_logs") if "rotating_logger" in f
    ]
    assert len(rotated_files) > 1, "Log rotation did not happen"


def test_json_logging(temp_log_dir):
    """Verify JSON log format is correctly applied."""
    logger = DarcaLogger(
        name="json_logger", log_directory=temp_log_dir, json_format=True
    ).get_logger()

    log_file_path = os.path.join(temp_log_dir, "json_logger.log")
    logger.info("JSON format test")

    # Force flush to ensure the message is written
    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(
        log_file_path
    ), f"JSON log file was not created: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert '"level": "INFO"' in log_content, "JSON formatting failed"
    assert (
        '"message": "JSON format test"' in log_content
    ), "Log message missing in JSON output"


def test_dynamic_log_level_change(logger_instance):
    """Ensure log levels can be changed dynamically."""
    logger = logger_instance.get_logger()
    logger_instance.set_level(logging.ERROR)

    assert (
        logger.level == logging.ERROR
    ), "Log level was not updated dynamically"
