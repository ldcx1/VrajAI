job "monitoring" {
  datacenters = ["dc1"]
  type        = "service"


  group "prometheus" {
    constraint {
      attribute = "${meta.instance_type}"
      value     = "gpu.large"
    }
    count = 1
    network {
      port "http" {
        static = 9090
      }
    }

    service {
      name = "prometheus"
      port = "http"
      check {
        type     = "http"
        path     = "/-/healthy"
        interval = "10s"
        timeout  = "2s"
      }
    }

    volume "prometheus_data" {
      type      = "host"
      source    = "prometheus_data"
      read_only = false
    }


    task "prometheus-server" {
      driver = "docker"
      config {
        image = "prom/prometheus:latest"
        ports = ["http"]
        args = [
          "--config.file=/local/prometheus.yml",
          "--storage.tsdb.path=/prometheus"
        ]
      }

      template {
        data = <<EOF
global:
  scrape_interval: 10s
  evaluation_interval: 10s

scrape_configs:
  - job_name: 'nomad_metrics'
    metrics_path: '/v1/metrics'
    params:
      format: ['prometheus']
    consul_sd_configs:
      - server: '127.0.0.1:8500' # Assuming Consul runs natively on host where prometheus bridges to
        services: ['nomad']

  - job_name: 'council_router'
    metrics_path: '/metrics'
    consul_sd_configs:
      - server: '127.0.0.1:8500'
        services: ['council-router']
EOF
        destination = "local/prometheus.yml"
      }

      resources {
        cpu        = 500
        memory     = 1024
        memory_max = 2048
      }

      volume_mount {
        volume      = "prometheus_data"
        destination = "/prometheus"
        read_only   = false
      }
    }
  }

  group "grafana" {
    count = 1
    network {
      mode = "bridge"
      port "http" {
        to = 3000
      }
    }

    service {
      name = "grafana"
      port = "3000"
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
        path     = "/api/health"
        interval = "10s"
        timeout  = "2s"
      }
    }

    volume "grafana_data" {
      type      = "host"
      source    = "grafana_data"
      read_only = false
    }


    task "grafana-server" {
      driver = "docker"
      config {
        image = "grafana/grafana:latest"
        ports = ["http"]
      }

      env {
        GF_AUTH_ANONYMOUS_ENABLED  = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Viewer"
      }

      template {
        data = <<EOF
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    # Since prometheus is in another group, we use host IP mapping or simple host network routing.
    # Since Prometheus receives data seamlessly from Envoy upstream proxy
    url: http://127.0.0.1:9090
    isDefault: true
EOF
        destination = "local/provisioning/datasources/prometheus.yaml"
      }

      template {
        data = <<EOF
apiVersion: 1
providers:
  - name: "Council Router"
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /local/dashboards
      foldersFromFilesStructure: true
EOF
        destination = "local/provisioning/dashboards/dashboards.yaml"
      }

      template {
        data = <<EOF
{
    "dashboard": {
        "id": null,
        "uid": "council-router",
        "title": "Council Router",
        "tags": [
            "ollama",
            "llm",
            "proxy"
        ],
        "timezone": "browser",
        "panels": [
            {
                "title": "Requests per Second",
                "type": "graph",
                "gridPos": {
                    "h": 8,
                    "w": 12,
                    "x": 0,
                    "y": 0
                },
                "targets": [
                    {
                        "expr": "rate(council_router_requests_total[5m])",
                        "legendFormat": "{{model}} → {{backend}}"
                    }
                ]
            },
            {
                "title": "Request Latency (p95)",
                "type": "graph",
                "gridPos": {
                    "h": 8,
                    "w": 12,
                    "x": 12,
                    "y": 0
                },
                "targets": [
                    {
                        "expr": "histogram_quantile(0.95, rate(council_router_request_duration_seconds_bucket[5m]))",
                        "legendFormat": "p95 {{model}}"
                    }
                ]
            },
            {
                "title": "Tokens per Second",
                "type": "gauge",
                "gridPos": {
                    "h": 8,
                    "w": 8,
                    "x": 0,
                    "y": 8
                },
                "targets": [
                    {
                        "expr": "council_router_tokens_per_second",
                        "legendFormat": "{{model}} @ {{backend}}"
                    }
                ]
            },
            {
                "title": "Backend Status",
                "type": "stat",
                "gridPos": {
                    "h": 8,
                    "w": 8,
                    "x": 8,
                    "y": 8
                },
                "targets": [
                    {
                        "expr": "council_router_backend_status",
                        "legendFormat": "{{backend}} ({{group}})"
                    }
                ]
            },
            {
                "title": "Active Requests",
                "type": "gauge",
                "gridPos": {
                    "h": 8,
                    "w": 8,
                    "x": 16,
                    "y": 8
                },
                "targets": [
                    {
                        "expr": "council_router_active_requests",
                        "legendFormat": "{{backend}}"
                    }
                ]
            },
            {
                "title": "Total Tokens (Prompt + Completion)",
                "type": "graph",
                "gridPos": {
                    "h": 8,
                    "w": 12,
                    "x": 0,
                    "y": 16
                },
                "targets": [
                    {
                        "expr": "rate(council_router_prompt_tokens_total[5m])",
                        "legendFormat": "prompt {{model}}"
                    },
                    {
                        "expr": "rate(council_router_completion_tokens_total[5m])",
                        "legendFormat": "completion {{model}}"
                    }
                ]
            },
            {
                "title": "Fallback Activations",
                "type": "graph",
                "gridPos": {
                    "h": 8,
                    "w": 12,
                    "x": 12,
                    "y": 16
                },
                "targets": [
                    {
                        "expr": "rate(council_router_fallback_used_total[5m])",
                        "legendFormat": "{{requested_model}} → {{fallback_model}}"
                    }
                ]
            }
        ],
        "time": {
            "from": "now-1h",
            "to": "now"
        },
        "refresh": "10s"
    }
}
EOF
        destination     = "local/dashboards/ollama-monitor.json"
        left_delimiter  = "[["
        right_delimiter = "]]"
      }

      resources {
        cpu        = 500
        memory     = 512
        memory_max = 1024
      }

      volume_mount {
        volume      = "grafana_data"
        destination = "/var/lib/grafana"
        read_only   = false
      }
    }
  }
}
