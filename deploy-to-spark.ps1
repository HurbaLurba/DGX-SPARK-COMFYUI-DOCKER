#!/usr/bin/env pwsh
# Deploy ComfyUI to DGX Spark using Ansible

param(
    [string]$InventoryFile = "ansible/inventory/hosts.ini",
    [switch]$CheckOnly,
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Deploying ComfyUI to DGX Spark"
Write-Host "=========================================="

# Check if ansible is installed
try {
    $ansibleVersion = ansible --version 2>$null
    if (-not $ansibleVersion) {
        throw "Ansible not found"
    }
    Write-Host "Ansible is installed"
} catch {
    Write-Host "ERROR: Ansible is not installed or not in PATH"
    Write-Host ""
    Write-Host "To install Ansible on Windows:"
    Write-Host "  1. Install WSL2 if not already installed"
    Write-Host "  2. In WSL: sudo apt update && sudo apt install ansible"
    Write-Host ""
    Write-Host "Or use Docker:"
    Write-Host "  docker run --rm -v ${PWD}:/work -w /work cytopia/ansible ansible-playbook -i $InventoryFile ansible/playbooks/deploy-comfyui-spark-docker.yml"
    exit 1
}

# Build ansible-playbook command
$AnsibleArgs = @(
    "-i", $InventoryFile,
    "ansible/playbooks/deploy-comfyui-spark-docker.yml"
)

if ($CheckOnly) {
    Write-Host "Running in check mode (dry-run)..."
    $AnsibleArgs += "--check"
}

if ($Verbose) {
    $AnsibleArgs += "-vvv"
}

Write-Host ""
Write-Host "Executing: ansible-playbook $($AnsibleArgs -join ' ')"
Write-Host ""
Write-Host "This will:"
Write-Host "  1. Copy files to DGX Spark"
Write-Host "  2. Build Docker image (15-25 minutes)"
Write-Host "  3. Start ComfyUI container"
Write-Host ""

# Run ansible-playbook
& ansible-playbook @AnsibleArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Deployment completed successfully!"
    Write-Host "=========================================="
    Write-Host ""
    Write-Host "ComfyUI should now be accessible on your DGX Spark"
    Write-Host "Check the output above for the access URL"
} else {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Deployment failed!"
    Write-Host "Exit code: $LASTEXITCODE"
    Write-Host "=========================================="
    exit $LASTEXITCODE
}
