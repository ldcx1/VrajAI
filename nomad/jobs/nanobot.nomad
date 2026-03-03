job "nanobot" {
  datacenters = ["dc1"]
  type        = "service"


  group "nanobot-agent" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    
    network {
      mode = "bridge"
    }

    service {
      name = "nanobot-agent"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "council-router"
              local_bind_port  = 11430
            }
          }
        }
      }
    }

    volume "experiments_data" {
      type      = "host"
      source    = "experiments_data"
      read_only = false
    }

    volume "skills_data" {
      type      = "host"
      source    = "skills_data"
      read_only = true
    }

    task "nanobot-process" {
      driver = "docker"
      config {
        image = "nanobot:latest"
        
        # Running securely without privileged access enabled.

        volumes = [
          "local/config.json:/root/.nanobot/config.json"
        ]
      }
      resources {
        cpu        = 6000
        memory     = 8192
        memory_max = 16384
      }
      volume_mount {
        volume      = "experiments_data"
        destination = "/experiments"
        read_only   = false
      }
      volume_mount {
        volume      = "skills_data"
        destination = "/app/nanobot/skills"
        read_only   = true
      }
      env {
        # Configure NanoBot to talk to the local Envoy Proxy routing to Council Router
        NANOBOT_GATEWAY_URL = "http://127.0.0.1:11430/v1"
      }

      vault {
        policies = ["nanobot-read"]
      }

      template {
        data = <<EOF
{{ with secret "secret/data/nanobot/api" }}
NANOBOT_API_KEY="{{ .Data.data.api_key }}"
{{ end }}
EOF
        destination = "secrets/nanobot.env"
        env         = true
      }

      template {
        data = <<EOF
{
  "tools": {
    "mcpServers": {
      "context7": {
        "url": "https://mcp.context7.com/mcp",
        "headers": {
          "CONTEXT7_API_KEY": "YOUR_API_KEY"
        }
      },
      "code-graph-rag": {
        "command": "nomad",
        "args": ["alloc", "exec", "-i", "-job", "mcp-servers", "-task", "code-graph-rag-server", "code-graph-rag", "mcp-server"]
      },
      "rag-anything": {
        "command": "nomad",
        "args": ["alloc", "exec", "-i", "-job", "mcp-servers", "-task", "rag-anything-server", "rag-anything", "mcp-server"]
      },
      "celery-mcp": {
        "command": "nomad",
        "args": ["alloc", "exec", "-i", "-job", "mcp-servers", "-task", "experiment-runner", "celery-mcp", "mcp-server"]
      },
      "vibe-check-mcp": {
        "url": "http://vibe-check-mcp.service.consul:3000/sse"
      },
      "arxiv-mcp": {
        "url": "http://arxiv-mcp.service.consul:8000/sse"
      }
    }
  }
}
EOF
        destination = "local/config.json"
      }
    }
  }
}
