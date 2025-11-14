#!/usr/bin/env pwsh
# Run script for ComfyUI Docker container on local machine (5090)

param(
    [string]$Version = "0.08",
    [string]$Registry = "local",
    [string]$ContainerName = "comfyui-dgx-local",
    [int]$Port = 8188,
    [string]$ModelsPath = "D:\share\comfy\models",
    [string]$InputPath = "E:\temp\ComfyUI\input",
    [string]$OutputPath = "E:\temp\ComfyUI\output",
    [string]$TempPath = "E:\temp\ComfyUI\temp",
    [string]$ComfyUIArgs = "--normalvram --use-sage-attention --disable-cuda-malloc --cache-classic --async-offload --dont-print-server --verbose CRITICAL --log-stdout --disable-mmap --fp16-vae --reserve-vram 2 --preview-method auto --fp8_e4m3fn-text-enc --fp8_e4m3fn-unet --disable-smart-memory",
    [string[]]$ExtraArgs = @()
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Running ComfyUI Docker Container"
Write-Host "Version: $Version"
Write-Host "Container Name: $ContainerName"
Write-Host "Port: $Port"
Write-Host "=========================================="

# Set image name
$ImageName = "${Registry}/comfyui-dgx:${Version}-amd64"

# Check if container already exists
$ExistingContainer = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
if ($ExistingContainer -eq $ContainerName) {
    Write-Host "Stopping and removing existing container: $ContainerName"
    docker stop $ContainerName 2>$null | Out-Null
    docker rm $ContainerName 2>$null | Out-Null
}

# Build docker run arguments
$DockerArgs = @(
    "run"
    "-d"  # Always run in detached mode
)

# Add container name
$DockerArgs += "--name", $ContainerName

# Add GPU support
$DockerArgs += "--gpus", "all"

# Add port mapping
$DockerArgs += "-p", "${Port}:8188"

# Helper function to convert Windows paths to Docker-compatible paths
function Convert-ToDockerPath {
    param([string]$Path)
    if ([string]::IsNullOrEmpty($Path)) { return $Path }
    
    # Resolve to absolute path
    $absPath = (Resolve-Path $Path -ErrorAction SilentlyContinue).Path
    if (-not $absPath) { $absPath = $Path }
    
    # Convert backslashes to forward slashes
    $dockerPath = $absPath -replace '\\', '/'
    
    # Convert drive letter format (C: -> /c)
    if ($dockerPath -match '^([A-Za-z]):(.*)') {
        $dockerPath = "/$($matches[1].ToLower())$($matches[2])"
    }
    
    return $dockerPath
}

# Add volume mounts for custom paths
if ($ModelsPath) {
    $dockerModelsPath = Convert-ToDockerPath $ModelsPath
    Write-Host "Mounting models path: $ModelsPath -> $dockerModelsPath"
    $DockerArgs += "-v", "${dockerModelsPath}:/workspace/ComfyUI/models"
    $DockerArgs += "-e", "MODEL_BASE_PATH=/workspace/ComfyUI/models"
}

if ($InputPath) {
    $dockerInputPath = Convert-ToDockerPath $InputPath
    Write-Host "Mounting input path: $InputPath -> $dockerInputPath"
    $DockerArgs += "-v", "${dockerInputPath}:/workspace/ComfyUI/input"
    $DockerArgs += "-e", "INPUT_DIR=/workspace/ComfyUI/input"
}

if ($OutputPath) {
    $dockerOutputPath = Convert-ToDockerPath $OutputPath
    Write-Host "Mounting output path: $OutputPath -> $dockerOutputPath"
    $DockerArgs += "-v", "${dockerOutputPath}:/workspace/ComfyUI/output"
    $DockerArgs += "-e", "OUTPUT_DIR=/workspace/ComfyUI/output"
}

if ($TempPath) {
    $dockerTempPath = Convert-ToDockerPath $TempPath
    Write-Host "Mounting temp path: $TempPath -> $dockerTempPath"
    $DockerArgs += "-v", "${dockerTempPath}:/workspace/ComfyUI/temp"
    $DockerArgs += "-e", "TEMP_DIR=/workspace/ComfyUI/temp"
}

# Add environment variables
$DockerArgs += "-e", "COMFYUI_PORT=8188"

# Add ComfyUI optimization arguments
if ($ComfyUIArgs) {
    Write-Host "ComfyUI arguments: $ComfyUIArgs"
    $DockerArgs += "-e", "COMFYUI_ARGS=$ComfyUIArgs"
}

# Add restart policy
$DockerArgs += "--restart", "unless-stopped"

# Add image name
$DockerArgs += $ImageName

# Add extra arguments to ComfyUI
if ($ExtraArgs.Count -gt 0) {
    $DockerArgs += $ExtraArgs
}

Write-Host ""
Write-Host "Executing: docker $($DockerArgs -join ' ')"
Write-Host ""

# Run the container
& docker @DockerArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Container started successfully!"
    Write-Host "=========================================="
    Write-Host "ComfyUI is available at: http://localhost:$Port"
    Write-Host ""
    Write-Host "To view logs:"
    Write-Host "  docker logs -f $ContainerName"
    Write-Host ""
    Write-Host "To stop the container:"
    Write-Host "  docker stop $ContainerName"
    Write-Host ""
    Write-Host "To remove the container:"
    Write-Host "  docker rm $ContainerName"
} else {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Failed to start container!"
    Write-Host "Exit code: $LASTEXITCODE"
    Write-Host "=========================================="
    exit $LASTEXITCODE
}