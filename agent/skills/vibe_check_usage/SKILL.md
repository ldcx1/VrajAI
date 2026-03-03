---
name: Vibe Check Integration
description: How and when to use the Vibe Check MCP Server to prevent reasoning lock-in.
---

# Vibe Check Integration

You have an AI meta-mentor attached to your cluster via the `vibe-check-mcp` service. Its purpose is to perform Chain-Pattern Interrupts (CPI) to ensure you do not get stuck, "over-engineer", or go down the wrong path during complex reasoning blocks.

## When to Vibe Check
1. **Before Committing Major Code Changes**: Call `vibe_check` to receive metacognitive feedback before writing massive structural files.
2. **When You Are Stuck**: If you encounter errors multiple times in a row, or if you feel you might be hallucinating fixes, use `vibe_check` to get a second opinion.
3. **During Architecture Planning**: When designing new workflows, request a Vibe Check to evaluate obvious gaps in your reasoning.

## How to Vibe Check
Use your MCP tool calling interface the function `vibe_check` (or relevant equivalents exposed by the Council Router). 
Your prompt to the Vibe Check server should include:
1. The **User Goal**.
2. Your **Current Plan**.
3. **What you are stuck on** (or where you are in the progress).

## Vibe Learn and Constitution
You can optionally invoke `vibe_learn` to record mistakes to memory to avoid repeating them in future sessions.
You can invoke `update_constitution` to merge specific behavioral rules that the CPI layer will hold you to during the active session.
