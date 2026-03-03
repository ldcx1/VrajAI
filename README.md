<div align="center">
  <h1>🧠 VrajAI: Autonomous Research Assistant</h1>
  <p>
    <strong>A multi-tier, autonomous AI research assistant designed for cybersecurity and AI doctorate research.</strong>
  </p>
  <p>
    <img src="https://img.shields.io/badge/Python-3.11+-blue?style=flat-square&logo=python&logoColor=white" alt="Python">
    <img src="https://img.shields.io/badge/Nomad-Orchestrated-000000?style=flat-square&logo=nomad&logoColor=white" alt="Nomad">
    <img src="https://img.shields.io/badge/Docker-Ready-2496ED?style=flat-square&logo=docker&logoColor=white" alt="Docker">
    <img src="https://img.shields.io/badge/NanoBot-Powered-FF4B4B?style=flat-square" alt="NanoBot">
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
  </p>
</div>

---

VrajAI runs 24/7 on local infrastructure, orchestrating code generation, running experiments, producing reports with statistics and graphics. Built on **NanoBot**, **Ollama**, and **Nomad**, it features a unique unified LLM gateway for intelligent routing, council voting between local models, and seamless cloud escalation.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| 🧠 **Multi-Tier Routing** | Intelligently routes queries: Fast local triage (T1), heavy lifting (T2), and Cloud escalation (T3). |
| ⚖️ **LLM Council Voting** | Parallel model deliberation (`council:3-members`) synthesizes multiple local models into one verified answer. |
| 🔍 **Advanced MCP RAG** | AST-based structural code search (`code-graph-rag`) and Qdrant-backed semantic search (`rag-anything`). |
| 🔬 **Autonomous Experiments** | Run, track, and kill ML experiments natively via the `celery-mcp` and MLflow integration. |
| 🚢 **Nomad Orchestration** | Robust cluster deployment handling primary/worker nodes natively through HashiCorp Nomad. |
| 📊 **Full Telemetry** | Every prompt and token is logged securely for continuous performance and quality analysis. |

---

## 🏗️ Architecture

```text
┌──────────────────────────▼─── Primary Node ────────────────────────┐
│                                                                    │
│  🤖 NANOBOT AGENT (Nomad Job, 24/7)                                │
│  ├── Skills: Code Development, experiment tracking, auto-research  │
│  └── MCPs: Connections to specialized tool servers                 │
│                                                                    │
│  🚦 LLM UNIFIED GATEWAY (Council Router + Gemini CLI)              │
│  ├── Exposes single OpenAI API for all local & cloud models        │
│  ├── Handles native routing: T1 (Worker), T2 (Primary), T3 (Cloud) │
│  └── Powers council voting: pseudo-model `council:X-members`       │
│                                                                    │
│  🛠️ MCP SERVERS (Nomad Jobs / Docker)                              │
│  ├── code-graph-rag        AST-based structural code search        │
│  ├── rag-anything          Qdrant vectors, semantic code/doc RAG   │
│  ├── celery-mcp            Run, track, and kill experiments        │
│  ├── vibe-check-mcp        Code/system analysis and validation     │
│  └── mcp-system-monitor    GPU/CPU status & capacity planning      │
│                                                                    │
│  ⚙️ INFRASTRUCTURE                                                 │
│  └── Ollama, Qdrant, Redis, MLflow, MinIO                          │
│                                                                    │
└──────────────┬─────────────────────────────────┬───────────────────┘
               │                                 │
┌──────────────▼─── Worker Node ────────┐ ┌──────▼───── CLOUD ───────┐
│  Ollama: T1 models (Fast / Triage)      │ │  via gemini-cli-server │
│  ├── qwen2.5-coder:3b                   │ │  ├── Gemini Pro/Flash  │
│  └── phi-4-mini:3.8b                    │ │                        │
└─────────────────────────────────────────┘ └────────────────────────┘
```

---

## 🚀 Quick Start

> [!TIP]
> The entire VrajAI cluster is orchestrated using **HashiCorp Nomad**. A central `Makefile` is provided to fully automate node installations, image building, and the deployment sequence.

<details>
<summary><b>1. Install Cluster Infrastructure</b></summary>

Install Docker, Nomad, and configure the Primary/Worker node topologies.
*Ensure SSH access is enabled and GPU drivers are installed before running.*

```bash
# Override IPs if not running locally
export PRIMARY_NODE_IP="192.168.1.100"
export WORKER_NODE_IP="192.168.1.101"

make install-nomad
```
</details>

<details>
<summary><b>2. Build Docker Images</b></summary>

Pushes the source code and builds the custom container images directly onto the Primary Node's Docker daemon.

```bash
make build-images
```
</details>

<details>
<summary><b>3. Deploy the Stack</b></summary>

Deploy the entire platform sequentially (Infrastructure → Monitoring → Ollama → Gateways → MCPs → Nanobot):

```bash
make deploy-all
```

*Note: The `deploy-nanobot` target will automatically `rsync` your local `agent/skills` folder into the live container via a Nomad host volume.*
</details>

---

## 📂 Repository Structure

| Directory | Purpose |
|-----------|---------|
| 🤖 **`agent/`** | The main `nanobot` autonomous agent and its dynamic local `skills/`. |
| 🧩 **`mcp-servers/`** | All Model Context Protocol implementations (`code-graph-rag`, etc.). |
| 🔀 **`services/`** | Core backend routing infrastructure (`council-router`, `gemini-cli-server`). |
| 🚢 **`nomad/`** | Cluster deployment HCL files, configs, and automated setup scripts. |

---

## 🛠️ Technology Stack

- **Agent Runtime**: [NanoBot](https://github.com/HKUDS/nanobot)
- **Orchestration**: HashiCorp Nomad + Docker
- **LLM Gateway**: LiteLLM / FastAPI 
- **Code Search**: tree-sitter, ripgrep, fd, ast-grep
- **Vector Search**: Qdrant
- **Data/Tracking**: Redis, MinIO, MLflow, Celery
- **Monitoring**: Prometheus + Grafana

---

## 🙏 Acknowledgments & Credits

VrajAI is built upon the shoulders of giants. With the exception of our internal routing services, the core agents, tools, and vendor dependencies in this repository are forked from incredible open-source projects. We extend our deepest gratitude to the original authors:

- **NanoBot**: [HKUDS/nanobot](https://github.com/HKUDS/nanobot)
- **Code Graph RAG**: [vitali87/code-graph-rag](https://github.com/vitali87/code-graph-rag)
- **RAG Anything**: [HKUDS/RAG-Anything](https://github.com/HKUDS/RAG-Anything)
- **MCP System Monitor**: [huhabla/mcp-system-monitor](https://github.com/huhabla/mcp-system-monitor)
- **Vibe Check MCP**: [PV-Bhat/vibe-check-mcp-server](https://github.com/PV-Bhat/vibe-check-mcp-server)
- **Arxiv MCP**: [lukestanley/arxiv-mcp-server](https://github.com/lukestanley/arxiv-mcp-server)
- **AWS S3 MCP**: [samuraikun/aws-s3-mcp](https://github.com/samuraikun/aws-s3-mcp)
- **Celery MCP**: [joeyrubas/celery-mcp](https://github.com/joeyrubas/celery-mcp)
- **LiteLLM**: [BerriAI/litellm](https://github.com/BerriAI/litellm)
- **AI Counsel**: [blueman82/ai-counsel](https://github.com/blueman82/ai-counsel)
- **Ollama Metrics**: [NorskHelsenett/ollama-metrics](https://github.com/NorskHelsenett/ollama-metrics)
- **OllamaFarm**: [presbrey/ollamafarm](https://github.com/presbrey/ollamafarm)
- **MLflow**: [mlflow/mlflow](https://github.com/mlflow/mlflow)

---

> *This project is itself an active research experiment on the usefulness of local models combined with advanced RAG, exact searching, and MCP tool usage.*
