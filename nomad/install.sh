#!/bin/bash
set -e

# Usage: ./install.sh <PRIMARY_NODE_IP> <WORKER_NODE_IP>

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <PRIMARY_NODE_IP> <WORKER_NODE_IP>"
    exit 1
fi

PRIMARY_NODE_IP=$1
WORKER_NODE_IP=$2

echo "Starting Nomad setup for VrajAI."
echo "Primary Node IP: $PRIMARY_NODE_IP"
echo "Worker Node IP: $WORKER_NODE_IP"

# Function to install dependencies on a remote server
install_dependencies() {
    local IP=$1
    echo "Installing Docker and Nomad on $IP..."
    ssh -o StrictHostKeyChecking=no root@$IP << 'EOF'
        export DEBIAN_FRONTEND=noninteractive
        apt-get update
        
        # Install Docker if not present
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            apt-get install -y ca-certificates curl gnupg
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        fi

        # Install Nomad and Consul if not present
        if ! command -v nomad &> /dev/null || ! command -v consul &> /dev/null; then
            echo "Installing HashiCorp Nomad and Consul..."
            wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
            apt-get update && apt-get install -y nomad consul
        fi

        # Create directories for host volumes
        mkdir -p /opt/vrajai/experiments
        mkdir -p /opt/vrajai/ollama
        mkdir -p /opt/vrajai/infra
        mkdir -p /opt/vrajai/skills
        chmod -R 755 /opt/vrajai

        systemctl enable docker
        systemctl start docker
EOF
}

setup_primary_node() {
    echo "--- Configuring Primary Node Options --- Configuring Primary Node (Nomad Server + Client)..."
    ssh root@$PRIMARY_NODE_IP "mkdir -p /etc/nomad.d"
    scp config/server.hcl root@$PRIMARY_NODE_IP:/etc/nomad.d/nomad.hcl
    
    ssh root@$PRIMARY_NODE_IP << EOF
        # Ensure bind address is set
        echo "bind_addr = \"0.0.0.0\"" >> /etc/nomad.d/nomad.hcl
        echo "data_dir  = \"/opt/nomad/data\"" >> /etc/nomad.d/nomad.hcl
        
        systemctl enable nomad
        systemctl restart nomad
EOF
}

setup_worker_node() {
    echo "--- Configuring Worker Node Options --- Configuring Worker Node (Nomad Client)..."
    ssh root@$WORKER_NODE_IP "mkdir -p /etc/nomad.d"
    scp config/client.hcl root@$WORKER_NODE_IP:/etc/nomad.d/nomad.hcl
    
    ssh root@$WORKER_NODE_IP << EOF
        echo "bind_addr = \"0.0.0.0\"" >> /etc/nomad.d/nomad.hcl
        echo "data_dir  = \"/opt/nomad/data\"" >> /etc/nomad.d/nomad.hcl
        # Tell the client where the server is
        echo "client {" >> /etc/nomad.d/nomad.hcl
        echo "  server_join {" >> /etc/nomad.d/nomad.hcl
        echo "    retry_join = [\"$PRIMARY_NODE_IP\"]" >> /etc/nomad.d/nomad.hcl
        echo "  }" >> /etc/nomad.d/nomad.hcl
        echo "}" >> /etc/nomad.d/nomad.hcl
        
        systemctl enable nomad
        systemctl restart nomad
EOF
}

# Execute sequence
install_dependencies $PRIMARY_NODE_IP
install_dependencies $WORKER_NODE_IP

setup_primary_node
setup_worker_node

echo "Nomad setup complete!"
echo "You can check the cluster status by logging into the Primary Node and running 'nomad node status'."
