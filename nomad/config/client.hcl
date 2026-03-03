# /work/VrajAI/nomad/config/client.hcl
client {
  enabled = true

  host_volume "ollama_data" {
    path      = "/opt/vrajai/ollama"
    read_only = false
  }

  host_volume "skills_data" {
    path      = "/opt/vrajai/skills"
    read_only = true
  }

  host_volume "prometheus_data" {
    path      = "/opt/vrajai/prometheus"
    read_only = false
  }

  host_volume "grafana_data" {
    path      = "/opt/vrajai/grafana"
    read_only = false
  }

  host_volume "openweb_data" {
    path      = "/opt/vrajai/openweb"
    read_only = false
  }

  host_volume "mlflow_data" {
    path      = "/opt/vrajai/mlflow"
    read_only = false
  }

  meta {
    node_type = "small"
  }
}

plugin "docker" {
  config {
    volumes {
      enabled = true
    }
  }
}

telemetry {
  publish_allocation_metrics = true
  publish_node_metrics       = true
  prometheus_metrics         = true
}
