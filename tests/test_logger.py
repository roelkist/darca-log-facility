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
    expected_logger_name = request.node.name
    assert logger.name == expected_logger_name, f"Expected '{expected_logger_name}', got '{logger.name}'"


def test_logging_levels(logger_instance, temp_log_dir):
    """Verify log messages appear at the correct levels."""
    logger = logger_instance.get_logger()
    log_file_path = os.path.join(temp_log_dir, "test_logging_levels.log")

    logger.info("Test log message")
    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(log_file_path), f"Log file does not exist: {log_file_path}"


def test_log_file_creation(logger_instance, temp_log_dir, request):
    """Check if log file is created when logging to file is enabled."""
    logger = logger_instance.get_logger()
    log_file_path = os.path.join(temp_log_dir, f"{request.node.name}.log")

    logger.info("Test log message")
    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(log_file_path), f"Log file was not created: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert "Test log message" in log_content, "Log message not written to file"


def test_log_rotation(temp_log_dir, request):
    """Ensure log rotation works by exceeding the max log file size."""
    log_name = request.node.name
    logger = DarcaLogger(
        name=log_name, log_directory=temp_log_dir, max_file_size=100, backup_count=3
    ).get_logger()

    log_file_path = os.path.join(temp_log_dir, f"{log_name}.log")

    for _ in range(100):  # Force rotation
        logger.info("This is a long log message to exceed the file size limit.")

    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(log_file_path), f"Log file does not exist: {log_file_path}"

    rotated_files = [f for f in os.listdir(temp_log_dir) if log_name in f]
    assert len(rotated_files) > 1, f"Log rotation did not happen for {log_name}"

    for i in range(1, 3):
        rotated_file = os.path.join(temp_log_dir, f"{log_name}.log.{i}")
        assert os.path.exists(rotated_file), f"Rotated log file missing: {rotated_file}"


def test_json_logging(temp_log_dir, request):
    """Verify JSON log format is correctly applied."""
    log_name = request.node.name
    logger = DarcaLogger(name=log_name, log_directory=temp_log_dir, json_format=True).get_logger()

    log_file_path = os.path.join(temp_log_dir, f"{log_name}.log")
    logger.info("JSON format test")

    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(log_file_path), f"JSON log file was not created: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert '"level": "INFO"' in log_content, "JSON formatting failed"
    assert '"message": "JSON format test"' in log_content, "Log message missing in JSON output"


def test_dynamic_log_level_change(logger_instance, temp_log_dir, request):
    """Ensure log levels can be changed dynamically."""
    logger = logger_instance.get_logger()
    logger_instance.set_level(logging.ERROR)

    log_file_path = os.path.join(temp_log_dir, f"{request.node.name}.log")

    logger.error("Error log message")
    for handler in logger.handlers:
        handler.flush()

    assert os.path.exists(log_file_path), f"Log file does not exist: {log_file_path}"

    with open(log_file_path, "r", encoding="utf-8") as f:
        log_content = f.read()

    assert "Error log message" in log_content, "Log message missing in file"


# 🚀 **Fixed test for console logging capture**
def test_console_logging_enabled(caplog):
    """Ensure console logging works correctly with color support."""
    logger = DarcaLogger(name="console_test", log_to_console=True).get_logger()

    # Enable log propagation to capture logs
    logger.propagate = True

    # Ensure a stream handler exists for proper capturing
    if not any(isinstance(handler, logging.StreamHandler) for handler in logger.handlers):
        stream_handler = logging.StreamHandler()
        stream_handler.setLevel(logging.INFO)
        logger.addHandler(stream_handler)

    with caplog.at_level(logging.INFO):
        logger.info("Console test message")

    assert "Console test message" in caplog.text, f"Captured logs: {caplog.text}"


def test_console_logging_disabled(caplog):
    """Ensure console logging is disabled when specified."""
    logger = DarcaLogger(name="no_console", log_to_console=False).get_logger()

    with caplog.at_level(logging.INFO):
        logger.info("This should not be logged")

    assert "This should not be logged" not in caplog.text, "Console logging was incorrectly enabled"


def test_file_logging_disabled(temp_log_dir, request):
    """Ensure logs are not written to file when file logging is disabled."""
    log_name = request.node.name
    logger = DarcaLogger(name=log_name, log_to_file=False, log_directory=temp_log_dir).get_logger()

    log_file_path = os.path.join(temp_log_dir, f"{log_name}.log")
    logger.info("No file logging test")

    assert not os.path.exists(log_file_path), "Log file was created despite being disabled"


def test_logger_singleton():
    """Ensure multiple instances with the same name return the same logger."""
    logger1 = DarcaLogger(name="singleton_test").get_logger()
    logger2 = DarcaLogger(name="singleton_test").get_logger()

    assert logger1 is logger2, "Logger instances are not the same (singleton failed)"


def test_colorlog_import_error(monkeypatch):
    """Simulate missing colorlog package to test fallback behavior."""
    
    # Prevent `colorlog` from being imported
    monkeypatch.setattr("builtins.__import__", lambda name, *args: None if name == "colorlog" else __import__(name, *args))

    try:
        logger = DarcaLogger(name="fallback_logger").get_logger()
        logger.info("Fallback test message")
    except Exception as e:
        pytest.fail(f"Logger failed with missing colorlog: {e}")
