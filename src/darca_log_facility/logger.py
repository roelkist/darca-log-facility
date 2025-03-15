import json
import logging
import logging.handlers
import os
import sys
from datetime import datetime

try:
    from colorlog import (
        ColoredFormatter,  # Optional: Enhances console output readability
    )

    COLORLOG_AVAILABLE = True
except ImportError:
    COLORLOG_AVAILABLE = False


class JSONFormatter(logging.Formatter):
    """Custom JSON log formatter."""

    def format(self, record):
        log_record = {
            "timestamp": datetime.utcfromtimestamp(record.created).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "process": record.process,
            "thread": record.thread,
        }
        return json.dumps(log_record)


class DarcaLogger:
    """A configurable logging manager for consistent logging across
    applications."""

    _instances = {}  # Singleton pattern to avoid duplicate loggers

    def __new__(cls, name="app", *args, **kwargs):
        if name not in cls._instances:
            cls._instances[name] = super(DarcaLogger, cls).__new__(cls)
        return cls._instances[name]

    def __init__(
        self,
        name="app",
        level=logging.INFO,
        log_to_file=True,
        log_to_console=True,
        log_directory="logs",
        max_file_size=5 * 1024 * 1024,  # 5 MB per file
        backup_count=5,  # Keep last 5 logs
        json_format=False,
        colored_console=True,
    ):
        if hasattr(self, "logger"):  # Prevent re-initialization in singleton
            return

        self.logger = logging.getLogger(name)
        self.logger.setLevel(level)
        self.logger.propagate = False  # Prevent duplicate logs

        self.formatter = (
            JSONFormatter()
            if json_format
            else logging.Formatter(
                "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
            )
        )

        if log_to_file:
            self._setup_file_logging(
                name, log_directory, max_file_size, backup_count
            )

        if log_to_console:
            self._setup_console_logging(colored_console)

    def _setup_file_logging(
        self, name, log_directory, max_file_size, backup_count
    ):
        """Setup file logging with rotation."""
        if not os.path.exists(log_directory):
            os.makedirs(
                log_directory, exist_ok=True
            )  # Ensure directory exists

        log_file_path = os.path.join(log_directory, f"{name}.log")

        file_handler = logging.handlers.RotatingFileHandler(
            log_file_path,
            maxBytes=max_file_size,
            backupCount=backup_count,
            encoding="utf-8",
        )
        file_handler.setFormatter(self.formatter)
        self.logger.addHandler(file_handler)

        # Debugging log to check if file is created
        self.logger.info(
            f"Logger initialized. Writing logs to {log_file_path}"
        )

    def _setup_console_logging(self, colored_console):
        """Setup console logging with optional color support."""
        console_handler = logging.StreamHandler(sys.stdout)
        if colored_console and COLORLOG_AVAILABLE:
            console_formatter = ColoredFormatter(
                "%(log_color)s%(asctime)s - %(name)s - "
                "%(levelname)s - %(message)s",
                log_colors={
                    "DEBUG": "cyan",
                    "INFO": "green",
                    "WARNING": "yellow",
                    "ERROR": "red",
                    "CRITICAL": "bold_red",
                },
            )
            console_handler.setFormatter(console_formatter)
        else:
            console_handler.setFormatter(self.formatter)

        self.logger.addHandler(console_handler)

    def get_logger(self):
        """Return the configured logger instance."""
        return self.logger

    def set_level(self, level):
        """Dynamically update the logging level."""
        self.logger.setLevel(level)
