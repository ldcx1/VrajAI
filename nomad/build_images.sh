#!/bin/bash
set -e

# Usage: ./build_images.sh <PRIMARY_NODE_IP>

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <PRIMARY_NODE_IP>"
    echo "Builds local apps directly on the destination server."
    exit 1
fi

PRIMARY_NODE_IP=$1
echo "Deploying and building local containers on $PRIMARY_NODE_IP..."

# 1. Sync the source code to the Primary Node's temporary build directory
echo "Syncing source code to $PRIMARY_NODE_IP..."
ssh root@$PRIMARY_NODE_IP "mkdir -p /tmp/vrajai_builds"

# Copy all local project directories that have a Dockerfile
# We step out of nomad/ to the parent VrajAI directory to find components
cd ..
DIRS_TO_SYNC=$(find . -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/Dockerfile' \; -print | sed 's|^\./||')

if [ -z "$DIRS_TO_SYNC" ]; then
    echo "No directories with Dockerfiles found in the workspace."
    exit 0
fi

echo "Found the following components to build:"
for dir in $DIRS_TO_SYNC; do
    echo " - $dir"
done

# We use rsync to sync these directories. 
# We build an array of arguments to cleanly pass them to rsync
RSYNC_ARGS=()
for dir in $DIRS_TO_SYNC; do
    RSYNC_ARGS+=("$dir")
done

rsync -avz --exclude='.git' --exclude='node_modules' --exclude='__pycache__' \
    "${RSYNC_ARGS[@]}" \
    root@$PRIMARY_NODE_IP:/tmp/vrajai_builds/

# 2. Run docker build on the remote server for each component
echo "Building images on $PRIMARY_NODE_IP..."
ssh root@$PRIMARY_NODE_IP << 'EOF'
    ROOT_DIR="/tmp/vrajai_builds"

    echo "----------------------------------------"
    echo "--- Building arxiv-mcp-server ---"
    cd "$ROOT_DIR/mcp-servers/arxiv-mcp-server"
    docker build -t arxiv-mcp-server:latest .

    echo "----------------------------------------"
    echo "--- Building nanobot ---"
    cd "$ROOT_DIR/agent/nanobot"
    docker build -t nanobot:latest .

    echo "----------------------------------------"
    echo "--- Building gemini-cli-server ---"
    cd "$ROOT_DIR/services/gemini-cli-server"
    docker build -t gemini-cli-server:latest .

    echo "----------------------------------------"
    echo "--- Building council-router ---"
    cd "$ROOT_DIR/services/council-router"
    docker build -t council-router:latest .

    echo "----------------------------------------"
    echo "--- Building code-graph-rag ---"
    cd "$ROOT_DIR/mcp-servers/code-graph-rag"
    docker build -t code-graph-rag:latest .

    echo "----------------------------------------"
    echo "--- Building rag-anything ---"
    cd "$ROOT_DIR/mcp-servers/RAG-Anything"
    docker build -t rag-anything:latest .

    echo "----------------------------------------"
    echo "--- Building aws-s3-mcp ---"
    cd "$ROOT_DIR/mcp-servers/aws-s3-mcp"
    docker build -t aws-s3-mcp:latest .

    echo "----------------------------------------"
    echo "--- Building celery-mcp ---"
    cd "$ROOT_DIR/mcp-servers/celery-mcp"
    docker build -t celery-mcp:latest .
EOF

echo "Cleaning up build directory..."
ssh root@$PRIMARY_NODE_IP "rm -rf /tmp/vrajai_builds"

echo "Build complete! The latest images are now cached in Docker on the Primary Node."
echo "You can now safely run your nomad jobs from /work/VrajAI/nomad/:"
echo "nomad run jobs/gateways.nomad"
echo "nomad run jobs/mcp-servers.nomad"
echo "nomad run jobs/nanobot.nomad"
