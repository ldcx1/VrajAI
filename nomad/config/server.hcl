# /work/VrajAI/nomad/config/server.hcl
server {
  enabled          = true
  bootstrap_expect = 1
}

client {
  enabled = true
  
  host_volume "experiments_data" {
    path      = "/opt/vrajai/experiments"
    read_only = false
  }

  host_volume "skills_data" {
    path      = "/opt/vrajai/skills"
    read_only = true
  }

  host_volume "gemini_config" {
    path      = "/home/dlese/.gemini"
    read_only = true
  }

  host_volume "ollama_data" {
    path      = "/opt/vrajai/ollama"
    read_only = false
  }

  host_volume "infra_data" {
    path      = "/opt/vrajai/infra"
    read_only = false
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
    node_type = "big"
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
