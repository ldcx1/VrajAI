#!/bin/bash
set -eo pipefail

echo "================================================="
echo "    HashiStack + Envoy + CNI Setup Script      "
echo "================================================="

# 1. Update and install standard dependencies
echo "[1/6] Installing standard dependencies..."
sudo apt-get update
sudo apt-get install -y wget gpg software-properties-common curl jq

# 2. Add HashiCorp APT Repository
echo "[2/6] Adding HashiCorp APT Repository..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt-get update

# 3. Install HashiStack (Nomad, Consul, Vault)
echo "[3/6] Installing Nomad, Consul, and Vault..."
sudo apt-get install -y nomad consul vault

# 4. Install CNI Plugins (Required for Nomad bridge mode & Consul Connect)
echo "[4/6] Installing Container Networking Interface (CNI) plugins..."
CNI_VERSION="1.3.0"
curl -L -o cni-plugins.tgz "https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-amd64-v${CNI_VERSION}.tgz"
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xzf cni-plugins.tgz
rm cni-plugins.tgz

# Ensure bridge kernel module is loaded and sysctl is set for iptables
echo "[4.5/6] Tuning networking kernel params..."
sudo sysctl -w net.bridge.bridge-nf-call-arptables=1
sudo sysctl -w net.bridge.bridge-nf-call-ip6tables=1
sudo sysctl -w net.bridge.bridge-nf-call-iptables=1

# 5. Install Envoy Proxy (Required for Consul Connect Service Mesh)
echo "[5/6] Installing Envoy Proxy..."
sudo apt-get install -y apt-transport-https gnupg2 curl lsb-release
curl -sL 'https://deb.dl.getenvoy.io/public/gpg.8115BA8E629CC074.key' | sudo gpg --yes --dearmor -o /usr/share/keyrings/getenvoy-keyring.gpg
echo a077cb587a1b622e03aa4bf2f3689de14658a9497a9af2c427bba5f4cc3c4723 /usr/share/keyrings/getenvoy-keyring.gpg | sha256sum --check
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/getenvoy-keyring.gpg] https://deb.dl.getenvoy.io/public/deb/ubuntu $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/getenvoy.list
sudo apt-get update
sudo apt-get install -y getenvoy-envoy

# 6. Basic local "dev" configurations & Systemctl enable
echo "[6/6] Generating local configurations (assuming single node test environment)..."
# In a real multi-node cluster, you must provide proper server/client config HCLs here.
# For now, we print a reminder.
echo ">> Binaries installed successfully!"
echo ">> To run locally: 'nomad agent -dev -bind 0.0.0.0 -network-interface={{ GetPrivateInterfaces | include \"network\" \"10.0.0.0/8\" | attr \"name\" }}'"
echo ">> To run consul: 'consul agent -dev'"
echo ">> To run vault: 'vault server -dev'"

echo "================================================="
echo "    Installation Complete!                     "
echo "================================================="
