job "gateways" {
  datacenters = ["dc1"]
  type        = "service"


  group "gemini-cli-server" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 11435
      }
    }

    volume "gemini_config" {
      type      = "host"
      source    = "gemini_config_data"
      read_only = true
    }

    volume "experiments_data" {
      type      = "host"
      source    = "experiments_data"
      read_only = false
    }

    service {
      name = "gemini-cli-server"
      port = "11435"
      connect {
        sidecar_service {}
      }
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "proxy" {
      driver = "docker"
      config {
        # Assuming the image is built locally or pushed to a registry
        image = "gemini-cli-server:latest"
        ports = ["http"]
      }
      env {
        GEMINI_CLI_HOST = "0.0.0.0"
        GEMINI_CLI_PORT = "11435"
      }
      resources {
        cpu        = 2000
        memory     = 2048
        memory_max = 4096
      }
      volume_mount {
        volume      = "gemini_config"
        destination = "/root/.gemini" # Container respects this path for CLI cache
        read_only   = true
      }
      volume_mount {
        volume      = "experiments_data"
        destination = "/opt/vrajai/experiments"
        read_only   = false
      }
    }
  }

  group "council-router" {
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 11430
      }
    }

    service {
      name = "council-router"
      port = "11430"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "prometheus"
              local_bind_port  = 9090
            }
          }
        }
      }
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "proxy" {
      driver = "docker"
      config {
        image = "council-router:latest"
        ports = ["http"]
      }
      env {
        PROMETHEUS_URL = "http://127.0.0.1:9090"
      }
      resources {
        cpu        = 4000
        memory     = 4096
        memory_max = 8192
      }
    }
  group "openwebui" {
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 8080
      }
    }

    volume "openweb_data" {
      type      = "host"
      source    = "openweb_data"
      read_only = false
    }

    service {
      name = "openwebui"
      port = "8080"
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
      check {
        type     = "http"
        path     = "/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "ui" {
      driver = "docker"
      config {
        image = "ghcr.io/open-webui/open-webui:main"
        ports = ["http"]
      }

      env {
        # Configure connections fully bound to council-router via Envoy proxy
        OPENAI_API_BASE_URL = "http://127.0.0.1:11430/v1"
        OPENAI_API_KEY      = "council-proxy"
        ENABLE_OLLAMA_API   = "false"
        PORT                = "8080"
      }
      resources {
        cpu        = 1000
        memory     = 1024
        memory_max = 2048
      }
      volume_mount {
        volume      = "openweb_data"
        destination = "/app/backend/data"
        read_only   = false
      }
    }
  }
}
