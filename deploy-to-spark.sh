#!/bin/bash
# Deploy ComfyUI to DGX Spark using Ansible

set -e

echo "=========================================="
echo "Deploying ComfyUI to DGX Spark"
echo "=========================================="

# Check if we're in WSL or native Linux
if [ -n "$WSL_DISTRO_NAME" ]; then
    echo "Running in WSL: $WSL_DISTRO_NAME"
fi

# Check if ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "ERROR: ansible-playbook not found"
    echo "Install with: sudo apt update && sudo apt install ansible"
    exit 1
fi

echo "Ansible version: $(ansible --version | head -n1)"
echo ""

# Check if inventory file exists
INVENTORY_FILE="ansible/inventory/hosts.ini"
if [ ! -f "$INVENTORY_FILE" ]; then
    echo "ERROR: Inventory file not found: $INVENTORY_FILE"
    exit 1
fi

# Check if playbook exists
PLAYBOOK_FILE="ansible/playbooks/deploy-comfyui-spark-docker.yml"
if [ ! -f "$PLAYBOOK_FILE" ]; then
    echo "ERROR: Playbook file not found: $PLAYBOOK_FILE"
    exit 1
fi

echo "Using inventory: $INVENTORY_FILE"
echo "Using playbook: $PLAYBOOK_FILE"
echo ""

echo "This will:"
echo "  1. Copy files to DGX Spark (spark-3712.local)"
echo "  2. Build Docker image (15-25 minutes)"
echo "  3. Start ComfyUI container with your NFS mounts"
echo ""

# Run the ansible playbook
echo "Executing: ansible-playbook -i $INVENTORY_FILE $PLAYBOOK_FILE"
echo ""

ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Deployment completed successfully!"
    echo "=========================================="
    echo ""
    echo "ComfyUI should now be accessible at:"
    echo "  http://spark-3712.local:8188"
    echo ""
    echo "Useful commands on DGX Spark:"
    echo "  docker logs -f comfyui-dgx-spark"
    echo "  docker stop comfyui-dgx-spark"
    echo "  docker restart comfyui-dgx-spark"
else
    echo ""
    echo "=========================================="
    echo "Deployment failed!"
    echo "Exit code: $?"
    echo "=========================================="
    exit 1
fi