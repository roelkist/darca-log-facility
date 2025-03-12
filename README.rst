Darca File Utils
================

Darca File Utils is a Python package that provides a comprehensive suite of utilities for managing
files, directories, and YAML configurations. It is designed to be modular, easy to integrate, and
suitable for both simple scripting and complex application development.

Features
--------

- **Directory Operations:** Check existence, create, list, remove, rename, move, and copy directories.
- **File Operations:** Check existence, read, write, remove, rename, move, and copy files.
- **YAML Operations:** Load from and write to YAML files with robust error handling.

License
-------

This project is licensed under the MIT License. See the ``LICENSE`` file for details.

Project Home
------------

- GitHub Repository: https://github.com/roelkist/darca-file-utils

Installation
------------

Install the runtime dependencies using:

.. code-block:: bash

   pip install -r requirements.txt

For development (including testing, linting, and documentation), install additional requirements:

.. code-block:: bash

   pip install -r requirements-dev.txt

Usage
-----

Import the modules into your project as needed:

.. code-block:: python

   from directory_utils import DirectoryUtils
   from file_utils import FileUtils
   from yaml_utils import YamlUtils

For detailed examples, please refer to the documentation files under the ``docs/`` directory,
including the API Reference and Usage Guide.

Development
-----------

- **Testing:** Run unit tests using ``pytest`` or via Tox.
- **Linting & Formatting:** Code style is enforced with Flake8 and Black.
- **Documentation:** Documentation can be generated using Sphinx by running:
  
  .. code-block:: bash

     tox -e docs

Contributing
------------

Contributions are welcome. Please see the CONTRIBUTING.rst file for more information.

Maintainers
-----------

For details on project maintainers, refer to the MAINTAINERS.rst file.
