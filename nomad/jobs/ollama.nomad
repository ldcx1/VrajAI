job "ollama" {
  datacenters = ["dc1"]
  type        = "service"

  group "gpu-large" {
    count = 1
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    network {
      port "http" {
        static = 11434
      }
    }

    service {
      name = "ollama-gpu-large"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }


    volume "ollama_data" {
      type      = "host"
      source    = "ollama_data"
      read_only = false
    }

    task "ollama-gpu-large" {
      driver = "docker"
      config {
        image = "ollama/ollama:latest"
        ports = ["http"]
      }
      resources {
        cpu        = 4000
        memory     = 8192
        memory_max = 16384
        device "nvidia/gpu" {
          count = 1
        }
      }
      volume_mount {
        volume      = "ollama_data"
        destination = "/root/.ollama"
        read_only   = false
      }
    }
  }

  group "compute-medium" {
    count = 1
    constraint {
      attribute = "${meta.instance_type}"
      value     = "compute.medium"
    }
    network {
      port "http" {
        static = 11434 # Worker Node also listens on 11434, but its own IP
      }
    }

    service {
      name = "ollama-compute-medium"
      port = "http"
      check {
        type     = "http"
        path     = "/"
        interval = "10s"
        timeout  = "2s"
      }
    }


    volume "ollama_data" {
      type      = "host"
      source    = "ollama_data"
      read_only = false
    }

    task "ollama-compute-medium" {
      driver = "docker"
      config {
        image = "ollama/ollama:latest"
        ports = ["http"]
      }
      resources {
        cpu        = 2000
        memory     = 2048
        memory_max = 4096
        device "nvidia/gpu" {
          count = 1
        }
      }
      volume_mount {
        volume      = "ollama_data"
        destination = "/root/.ollama"
        read_only   = false
      }
    }
  }
}
