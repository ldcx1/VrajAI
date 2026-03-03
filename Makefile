.PHONY: help install-nomad build-images deploy-infra deploy-monitoring deploy-ollama deploy-gateways deploy-mcp deploy-nanobot deploy-all stop-all status restart-agent

# Default values for IPs if not provided
PRIMARY_NODE_IP ?= 127.0.0.1
WORKER_NODE_IP ?= 127.0.0.1

help: ## Show this help menu
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

## ===== Core Infrastructure Setup =====

install-nomad: ## Install Docker and Nomad, and configure the cluster
	@echo "Installing Nomad on Primary Node ($(PRIMARY_NODE_IP)) and Worker Node ($(WORKER_NODE_IP))..."
	cd nomad && ./install.sh $(PRIMARY_NODE_IP) $(WORKER_NODE_IP)

build-images: ## Build all Docker images for the cluster
	@echo "Building Docker images for all cluster components..."
	cd nomad && ./build_images.sh $(PRIMARY_NODE_IP)

## ===== Deployment Commands =====

deploy-infra: ## Deploy core infrastructure (Redis, Qdrant, MinIO, MLflow)
	nomad job run nomad/jobs/infrastructure.nomad

deploy-monitoring: ## Deploy telemetry stack (Prometheus, Grafana)
	nomad job run nomad/jobs/monitoring.nomad

deploy-ollama: ## Deploy Ollama LLM provider clusters
	nomad job run nomad/jobs/ollama.nomad

deploy-gateways: ## Deploy API gateways (council-router, gemini-cli-server)
	nomad job run nomad/jobs/gateways.nomad

deploy-mcp: ## Deploy all MCP servers (rag, arxiv, celery, vibe-check)
	nomad job run nomad/jobs/mcp-servers.nomad

deploy-nanobot: ## Deploy the Nanobot autonomous agent
	@echo "Syncing agent skills to Primary Node..."
	rsync -avz --delete agent/skills/ root@$(PRIMARY_NODE_IP):/opt/vrajai/skills/
	nomad job run nomad/jobs/nanobot.nomad

deploy-all: deploy-infra deploy-monitoring deploy-ollama deploy-gateways deploy-mcp deploy-nanobot ## Deploy the entire stack sequentially
	@echo "All Nomad jobs successfully submitted to the cluster."

status: ## Show cluster and node status
	nomad node status
	nomad job status

## ===== Teardown & Maintenance =====

stop-all: ## Stop all running VrajAI jobs in the cluster
	nomad job stop -purge infrastructure || true
	nomad job stop -purge monitoring || true
	nomad job stop -purge ollama || true
	nomad job stop -purge gateways || true
	nomad job stop -purge mcp-servers || true
	nomad job stop -purge nanobot || true

restart-agent: ## Quick command to restart only the Nanobot
	nomad job restart nanobot
