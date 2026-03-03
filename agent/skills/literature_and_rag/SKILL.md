---
name: Literature and RAG Search
description: How to synthesize academic research via ArXiv MCP and query local codebase tools via Code Graph RAG.
---

# Literature and RAG Search

As an autonomous research assistant, you are expected to operate from a foundation of scientific fact, not hallucinated patterns. Before writing complex ML systems, use your RAG and literature tools.

## Internal System Knowledge (`code-graph-rag` & `rag-anything`)
Never build utility codes from scratch if they already exist in the cluster.
- Use the **Code Graph RAG MCP Server** to query the existing structural maps of the VrajAI repositories to find helper functions, database mappers, and prior experiment scripts.
- Use the **RAG Anything MCP Server** to ingest and reason over vast markdown documentation folders logically without dumping hundreds of files into your immediate prompt context.

## Academic Literature (`arxiv-mcp-server`)
When asked to implement new math, such as Speculative Decoding or state space models (Mamba):
1. **Search**: Call the `search_papers` MCP tool to pull the latest publications on the topic.
2. **Download & Read**: Call the `download_paper` and `read_paper` MCP tools. The ArXiv server saves these PDFs persistently into the `/experiments/arxiv_papers` host boundary so you don't need to re-download them during the session.
3. **Analyze**: Rely on the `deep-paper-analysis` prompt template built into the ArXiv server to systematically break down the methodology before you begin writing the PyTorch equivalents.
