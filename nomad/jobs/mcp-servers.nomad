job "mcp-servers" {
  datacenters = ["dc1"]
  type        = "service"


  group "code-graph-rag" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      port "stdio" {}
    }
    task "code-graph-rag-server" {
      driver = "docker"
      config {
        image = "code-graph-rag:latest"
      }
      resources {
        cpu        = 4000
        memory     = 4096
        memory_max = 8192
        device "nvidia/gpu" {
          count = 1
        }
      }
    }
  }

  group "rag-anything" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      port "stdio" {}
    }
    task "rag-anything-server" {
      driver = "docker"
      config {
        image = "rag-anything:latest"
      }
      resources {
        cpu        = 8000
        memory     = 8192
        memory_max = 16384
        device "nvidia/gpu" {
          count = 1
        }
      }
    }
  }

  group "celery-mcp" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      port "stdio" {}
    }

    volume "experiments_data" {
      type      = "host"
      source    = "experiments_data"
      read_only = false
    }

    task "experiment-runner" {
      driver = "docker"
      config {
        image = "celery-mcp:latest"
      }
      env {
        CELERY_BROKER_URL = "redis://127.0.0.1:6379/0"
      }
      resources {
        cpu        = 8000
        memory     = 8192
        memory_max = 16384
        device "nvidia/gpu" {
          count = 1
        }
      }
      volume_mount {
        volume      = "experiments_data"
        destination = "/experiments"
        read_only   = false
      }
    }
  }

  group "vibe-check-mcp" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 3000
      }
    }

    service {
      name = "vibe-check-mcp"
      port = "http"
      tags = [
        "prometheus.io/scrape=true",
        "prometheus.io/port=3000"
      ]
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

    task "server" {
      driver = "docker"
      config {
        image = "vibe-check-mcp-server:latest"
        ports = ["http"]
        # In Nomad, we must pass the explicit node args for this Docker container 
        # as it was built with `CMD ["node", "build/index.js"]`
        args = ["node", "build/index.js", "--http", "--port", "3000"]
      }

      env {
        DEFAULT_LLM_PROVIDER = "openai"
        OPENAI_API_KEY       = "council-proxy"
        OPENAI_BASE_URL      = "http://127.0.0.1:11430/v1"
        DEFAULT_MODEL        = "vraj-ai-advanced"
      }

      resources {
        cpu        = 1000
        memory     = 1024
        memory_max = 2048
      }
    }
  }

  group "arxiv-mcp" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      mode = "bridge"
      port "metrics" {
        to = 8000
      }
    }

    volume "experiments_data" {
      type      = "host"
      source    = "experiments_data"
      read_only = false
    }

    service {
      name = "arxiv-mcp"
      port = "metrics"
      tags = [
        "prometheus.io/scrape=true",
        "prometheus.io/port=8000"
      ]
      connect {
        sidecar_service {}
      }
    }

    task "server" {
      driver = "docker"
      config {
        image = "arxiv-mcp-server:latest"
        ports = ["metrics"]
      }

      env {
        ARXIV_STORAGE_PATH = "/data/papers/arxiv_papers"
      }

      resources {
        cpu        = 1000
        memory     = 1024
        memory_max = 2048
      }
      
      volume_mount {
        volume      = "experiments_data"
        destination = "/data/papers"
        read_only   = false
      }
    }
  }
}
