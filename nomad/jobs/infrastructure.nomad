job "infrastructure" {
  datacenters = ["dc1"]
  type        = "service"


  group "redis" {
    count = 1
    network {
      mode = "bridge"
      port "redis" {
        to = 6379
      }
    }

    service {
      name = "redis"
      port = "6379"
      connect {
        sidecar_service {}
      }
      check {
        type     = "tcp"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "redis-server" {
      driver = "docker"
      config {
        image = "redis:7-alpine"
        ports = ["redis"]
      }
      resources {
        cpu        = 200
        memory     = 256
        memory_max = 512
      }
    }
  }

  group "qdrant" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 6333
      }
      port "grpc" {
        to = 6334
      }
    }

    volume "infra_data" {
      type      = "host"
      source    = "infra_data"
      read_only = false
    }

    service {
      name = "qdrant"
      port = "6333"
      connect {
        sidecar_service {}
      }
      check {
        type     = "http"
        path     = "/readyz"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "qdrant-server" {
      driver = "docker"
      config {
        image = "qdrant/qdrant:latest"
        ports = ["http", "grpc"]
      }
      env {
        QDRANT__STORAGE__STORAGE_PATH = "/qdrant/storage"
      }
      resources {
        cpu        = 1000
        memory     = 1024
        memory_max = 2048
      }
      volume_mount {
        volume      = "infra_data"
        destination = "/qdrant/storage"
        read_only   = false
      }
    }
  }

  group "minio" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      mode = "bridge"
      port "api" {
        to = 9000
      }
      port "console" {
        to = 9001
      }
    }

    volume "infra_data" {
      type      = "host"
      source    = "infra_data"
      read_only = false
    }

    service {
      name = "minio"
      port = "9000"
      connect {
        sidecar_service {}
      }
      check {
        type     = "http"
        path     = "/minio/health/live"
        interval = "10s"
        timeout  = "2s"
      }
    }

    task "minio-server" {
      driver = "docker"
      config {
        image = "minio/minio:latest"
        args  = ["server", "/data", "--console-address", ":9001"]
        ports = ["api", "console"]
      }
      vault {
        policies = ["infrastructure-read"]
      }

      template {
        data = <<EOF
{{ with secret "secret/data/infrastructure/minio" }}
MINIO_ROOT_USER="{{ .Data.data.root_user }}"
MINIO_ROOT_PASSWORD="{{ .Data.data.root_password }}"
{{ end }}
EOF
        destination = "secrets/minio.env"
        env         = true
      }

      resources {
        cpu        = 2000
        memory     = 2048
        memory_max = 4096
      }
      volume_mount {
        volume      = "infra_data"
        destination = "/data"
        read_only   = false
      }
    }
  }

  group "mlflow" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 5000
      }
    }

    service {
      name = "mlflow"
      port = "5000"
      connect {
        sidecar_service {
          proxy {
            upstreams {
              destination_name = "minio"
              local_bind_port  = 9000
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

    volume "mlflow_data" {
      type      = "host"
      source    = "mlflow_data"
      read_only = false
    }

    task "mlflow-server" {
      driver = "docker"
      config {
        image = "bitnami/mlflow:latest"
        ports = ["http"]
      }
      env {
        MLFLOW_S3_ENDPOINT_URL = "http://127.0.0.1:9000"
      }

      vault {
        policies = ["infrastructure-read"]
      }

      template {
        data = <<EOF
{{ with secret "secret/data/infrastructure/minio" }}
AWS_ACCESS_KEY_ID="{{ .Data.data.root_user }}"
AWS_SECRET_ACCESS_KEY="{{ .Data.data.root_password }}"
{{ end }}
EOF
        destination = "secrets/mlflow.env"
        env         = true
      }

      resources {
        cpu        = 2000
        memory     = 2048
        memory_max = 4096
      }
      
      volume_mount {
        volume      = "mlflow_data"
        destination = "/bitnami/mlflow"
        read_only   = false
      }
    }
  }
}
