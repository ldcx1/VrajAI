---
name: Model Switching
description: How to change language models and navigate routing through the council-router.
---

# Model Switching via Council Router

As Nanobot, you communicate extensively through the `council-router`. The router implements an OpenAI-compatible interface and abstracts the backend LLM providers (Google Gemini, Anthropic, OpenRouter, etc.).

## How to Switch Models
When issuing requests to the `council-router` at `http://127.0.0.1:11430/v1/chat/completions`, you must specify the `"model"` field.

- Use standard model names configured in the Council Router payload logic.
- E.g., for fast tasks, switch to `"model": "gemini-2.5-flash"`.
- For deep coding or logic evaluation, request `"model": "gemini-2.5-pro"` or an Anthropic/OpenAI equivalent if it's available.

## Fallback Mechanisms
The Council Router possesses fallback layers. If you request a model that goes offline or fails, the router will automatically fall back to another provider model based on predefined `council_router` logic. You can see these failover metrics in Grafana dashboards.

Never hardcode specific keys or IP addresses to public APIs. Let `council-router` do the authentication, load balancing, and load tracing.
