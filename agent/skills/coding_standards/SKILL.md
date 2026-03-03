---
name: Coding Standards
description: How to write and test code according to VrajAI environment standards.
---

# Coding Standards

When evaluating or writing code across the VrajAI workspace (such as in `council-router` or other backend nodes), you must aggressively adhere to the established Clean Code guidelines and testing practices.

## Code Formatting and Linting
1. **Tooling**: Code formatting is enforced via **Black** (100 character line max limit). Linting is enforced via **Ruff**. Type checking is enforced via strict **MyPy**.
2. **Commands**: Always run `make format` followed by `make lint` on the target repository after modifying Python code.
3. **Typing**: Ensure all variables and function signatures remain strictly type-hinted. Do not leave typing ambiguous (`Any` should be used sparingly).
4. **Imports**: Keep imports explicitly at the top of the file. No inline imports.
5. **Constants**: Hardcoded variables or loop counts should be extracted into named constants.

## Testing
Code is never complete until it is fully tested.
1. **Tooling**: We use **Pytest**. For asynchronous endpoints (typical for MCP/LLM routers), utilize `pytest-asyncio`.
2. **Command**: Run `make test` inside the repository to execute the entire suite.
3. **Methodology**: Do not report back success to the user until you have successfully executed tests spanning your modifications. If you write new logic, write a matching `tests/unit/` or `tests/component/` edge case for it immediately.
