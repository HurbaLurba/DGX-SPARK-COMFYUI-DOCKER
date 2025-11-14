#!/bin/bash
# Deploy ComfyUI natively on DGX Spark using Ansible

set -e

INVENTORY_FILE="ansible/inventory/hosts.ini"

echo "=========================================="
echo "ComfyUI Native Deployment on DGX Spark"
echo "=========================================="
echo ""
echo "Available playbooks:"
echo "  1. Install/Update ComfyUI"
echo "  2. Run as systemd service"
echo "  3. Stop/Remove service"
echo "  4. Install recommended plugins"
echo "  5. Symlink models/input/output to NFS"
echo "  6. Full deployment (1+2+4+5)"
echo ""
read -p "Select option (1-6): " option

case $option in
    1)
        echo "Installing/Updating ComfyUI..."
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/01_install_update_comfyui.yml
        ;;
    2)
        echo "Setting up ComfyUI as systemd service..."
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/02_run_as_service.yml
        ;;
    3)
        echo "Stopping and removing ComfyUI service..."
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/03_stop_remove_service.yml
        ;;
    4)
        echo "Installing recommended plugins..."
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/04_install_recommended_plugins.yml
        ;;
    5)
        echo "Symlinking directories to NFS..."
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/05_symlink_models_output_input.yml
        ;;
    6)
        echo "Running full deployment..."
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/01_install_update_comfyui.yml
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/05_symlink_models_output_input.yml
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/04_install_recommended_plugins.yml
        ansible-playbook -i "$INVENTORY_FILE" ansible/playbooks/native/02_run_as_service.yml
        ;;
    *)
        echo "Invalid option"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Operation completed!"
echo "=========================================="
