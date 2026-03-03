# HashiCorp Nomad Architecture Plan

## 1. Overview
This setup deploys a HashiCorp Nomad cluster across two servers with built-in telemetry:
- **Primary Node**: Acts as the Nomad Server (control plane) and a Nomad Client. Runs heavy compute tasks, the main gateway, Nanobot, MCP servers, and infrastructure (Redis, Qdrant, MinIO).
- **Worker Node**: Acts as a Nomad Client only. Runs the T1 Ollama instance.

## 2. Hassle-Free Deployment
An initialization script (`install.sh`) will handle the setup:
- Accepts the IP addresses of the Primary Node and Worker Node as arguments.
- Installs Docker and Nomad on both servers.
- Configures Nomad `server.hcl` and `client.hcl` files, templating the IP addresses.
- Starts the Nomad agents as persistent systemd services.

## 3. Storage and Volumes
To enable cross-container communication and state-sharing, we will use Nomad `host_volume` configurations defined on the Primary Node's Nomad client:

| Volume Name | Host Path | Container Path / Target | Usage |
|-------------|-----------|------------------|-------|
| `experiments_data` | `/opt/vrajai/experiments` | `/experiments` (or `/opt/vrajai/experiments`) | **Shared storage:** Both `nanobot` and `celery-mcp` (experiment runner) use this to write shared files. `gemini-cli-server` uses this to execute LLM commands directly over the directory. |
| `gemini_config` | `/home/dlese/.gemini` (or user's gemini cache) | `~/.gemini` | **Credentials:** Mapped into the `gemini-cli-server` container so it automatically picks up the cached OAuth/service account tokens. |
| `ollama_data_big` | `/opt/vrajai/ollama` (Primary Node) | `/root/.ollama` | Persists model weights on the Primary Node. |
| `ollama_data_sm` | `/opt/vrajai/ollama` (Worker Node) | `/root/.ollama` | Persists model weights on the Worker Node. |
| `infra_data` | `/opt/vrajai/infra` | Various | Persistent state for Redis, Qdrant, MinIO. |

## 4. Job Specifications
Nomad will manage the containers using the `docker` task driver. The jobs are split by domain:

### `infrastructure.nomad`
- **Redis**: For task queues. Constrained to Primary Node.
- **Qdrant**: Vector DB. Constrained to Primary Node.
- **MinIO**: S3 Object storage. Constrained to Primary Node.
- **MLflow**: Experiment tracking. Constrained to Primary Node.

### `monitoring.nomad`
- **Prometheus**: Scrapes Nomad and Docker allocation telemetry data.
- **Grafana**: Automatically hooks into Prometheus for live dashboarding. Available on port `3000`.

### `ollama.nomad`
- Task Group `big`: Constrained to Primary Node (`meta.node_type = "big"`).
- Task Group `small`: Constrained to Worker Node (`meta.node_type = "small"`).

### `gateways.nomad`
- **gemini-cli-server**: Mounts `gemini_config` host volume.
- **council-router**: Serves as the `/v1` endpoint.

### `mcp-servers.nomad`
- **code-graph-rag**: Code search.
- **RAG-Anything**: RAG functionality.
- **celery-mcp**: Mounts `experiments_data` host volume to run experiment tasks. (Excluding the Report Generator MCP as requested).
- **vibe-check-mcp**: AI meta-mentor executing oversight across the cluster, pointed securely at `council-router`.
- **arxiv-mcp**: Scientific literature retrieval interface. Downloads academic papers persistently into the `experiments_data` volume and exports tool-usage telemetry to Prometheus.

### `nanobot.nomad`
- **nanobot**: The main agent. Mounts `experiments_data` host volume so it can create and edit experiment files that the `celery-mcp` will execute.

## 5. Directory Structure
```
/work/VrajAI/
├── nomad/                 # Cluster deployment and HCL files
├── PLAN.md                # High-level goals & roadmap
├── README.md              # The entry point explaining the architecture
│
├── agent/                 # Frontend agents & CLI interactors
│   ├── nanobot/           # Main agent
│   └── skills/            # Workspace agent logic (skills/ workflows)
│
├── mcp-servers/           # All Model Context Protocol tools
│   ├── arxiv-mcp-server/
│   ├── aws-s3-mcp/
│   ├── celery-mcp/
│   ├── code-graph-rag/
│   ├── mcp-system-monitor/
│   ├── RAG-Anything/
│   └── vibe-check-mcp-server/
│
├── services/              # Core backend infrastructure & routers
│   ├── council-router/    # Main LLM gateway routing requests
│   └── gemini-cli-server/ # CLI interface
│
└── vendor/                # Upstream dependencies & external submodules
├── install.sh             # Interactive / automated setup script
├── config/
│   ├── server.hcl         # Primary Node Nomad config template
│   └── client.hcl         # Worker Node Nomad config template
└── jobs/
    ├── infrastructure.nomad
    ├── monitoring.nomad
    ├── ollama.nomad
    ├── gateways.nomad
    ├── mcp-servers.nomad
    └── nanobot.nomad
```
