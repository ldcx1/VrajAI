---
name: Python Environments
description: How to isolate and manage Python dependencies using virtual environments.
---

# Python Environments

As Nanobot, you often write standalone scripts or heavy machine learning experiments. It is critical that you do not pollute the global Python environment or cross-contaminate dependencies between different running projects.

## Core Rule
**Every standalone experiment or isolated project must reside in its own Python Virtual Environment (`venv`).**

## How to use Virtual Environments

When writing a new tool, script, or orchestrating a Celery experiment in `/experiments`:

1. **Create the Environment**:
   Use `python -m venv <env_name>` to create an isolated directory.
   Example: `python -m venv /experiments/my_new_test_env`

2. **Activate the Environment**:
   Before installing dependencies, source the environment.
   Example: `source /experiments/my_new_test_env/bin/activate`

3. **Install Dependencies**:
   Once sourced, use `pip install` normally. The packages will only be installed into that specific environment.
   Example: `pip install torch transformers`

4. **Execute using the Environment**:
   When invoking a script (especially via asynchronous runners like `celery-mcp`), ALWAYS use the explicit path to the virtual environment's Python binary. Do not simply call `python script.py`.
   Example: `/experiments/my_new_test_env/bin/python /experiments/my_script.py`
