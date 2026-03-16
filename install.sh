#!/bin/bash
set -e

# kSuite Universal Installer (Sovereign Node / k-browser)
# This script is designed for fresh Linux servers (Ubuntu/Debian recommended).

echo "------------------------------------------------"
echo "   kSuite Universal Installer v1.0              "
echo "------------------------------------------------"

# 1. Dependency Check (Docker)
if ! command -v docker &> /dev/null; then
    echo "[1/4] Docker not found. Installing..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo systemctl enable --now docker
    rm get-docker.sh
    echo "✅ Docker installed."
else
    echo "✅ Docker is already installed."
fi

# 2. Selection
echo ""
echo "Which kSuite component would you like to install?"
echo "1) ksuite-node (Sovereign Kernel / Gateway)"
echo "2) k-browser    (Sovereign Eye / Vision Agent)"
read -p "Selection [1-2]: " CHOICE < /dev/tty

# 3. Setup Directory
BASE_DIR="$HOME/ksuite"
mkdir -p "$BASE_DIR/config" "$BASE_DIR/data"
cd "$BASE_DIR"

if [ "$CHOICE" == "1" ]; then
    echo "[2/4] Configuring ksuite-node..."
    
    # Generate Environment
    NODE_ID=$(hostname)
    NODE_DID="did:ksuite:$(openssl rand -hex 16)"
    PUBLIC_KEY=$(openssl rand -hex 32)
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    cat <<EOF > .env
KSUITE_DOMAIN=localhost
KSUITE_ZONE=prod
KSUITE_SERVER=localhost
NODE_ID=$NODE_ID
DISPLAY_NAME="Sovereign-Node-$NODE_ID"
NODE_DID=$NODE_DID
PUBLIC_KEY=$PUBLIC_KEY
TIMESTAMP=$TIMESTAMP
KSUITE_WEB_DOOR_PORT=8099
KSUITE_P2P_PORT=4001
AGENTME_WEB_URL=http://localhost:3000
TCB_WEB_URL=http://localhost:3001
CLARITY_WEB_URL=http://localhost:5000
EOF

    cat <<EOF > docker-compose.yml
version: '3.8'
services:
  ksuite-node:
    image: ghcr.io/agentmedev/ksuite-node:latest
    container_name: ksuite-node
    restart: always
    ports:
      - "8099:8099"
      - "4001:4001"
    env_file: .env
    volumes:
      - ./data:/app/data
      - ./config:/app/config
EOF
    SERVICE_NAME="ksuite-node"
    PORT="8099"

elif [ "$CHOICE" == "2" ]; then
    echo "[2/4] Configuring k-browser..."
    
    cat <<EOF > docker-compose.yml
version: '3.8'
services:
  k-browser:
    image: ghcr.io/agentmedev/k-browser:latest
    container_name: k-browser
    ports:
      - "3015:3015"
    environment:
      - PORT=3015
    restart: unless-stopped
EOF
    SERVICE_NAME="k-browser"
    PORT="3015"
else
    echo "❌ Invalid selection. Exiting."
    exit 1
fi

# 4. Launch
echo "[3/4] Pulling images and starting services..."
sudo docker compose pull
sudo docker compose up -d

# 5. Finish
echo "------------------------------------------------"
echo "✅ Installation Complete!"
echo "Service: $SERVICE_NAME"
echo "Port:    $PORT"
echo "Folder:  $BASE_DIR"
echo ""
echo "To view logs, run: cd ~/ksuite && sudo docker compose logs -f"
echo "------------------------------------------------"
