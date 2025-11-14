#!/usr/bin/env pwsh
# Build script for ComfyUI Docker image (ARM64)
# NOTE: This should be run on an ARM64 system like the DGX Spark

param(
    [string]# Configuration
$VERSION = "0.08",
    [string]$Registry = "local",
    [switch]$NoBuildCache
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Building ComfyUI Docker Image (ARM64)"
Write-Host "Version: $Version"
Write-Host "Registry: $Registry"
Write-Host "=========================================="

# Set build variables
$ImageName = "$Registry/comfyui-dgx"
$Platform = "linux/arm64"
$DockerfilePath = "./docker/Dockerfile.comfyui-dgx"
$ContextPath = "./docker"

# Build tags
$Tags = @(
    "${ImageName}:${Version}-arm64",
    "${ImageName}:latest-arm64"
)

# Build tag arguments
$TagArgs = @()
foreach ($Tag in $Tags) {
    $TagArgs += "-t"
    $TagArgs += $Tag
}

# Build cache argument
$CacheArgs = @()
if ($NoBuildCache) {
    $CacheArgs += "--no-cache"
}

Write-Host "Building image with tags:"
foreach ($Tag in $Tags) {
    Write-Host "  - $Tag"
}
Write-Host ""

# Build the image
$BuildArgs = @(
    "build",
    "--platform", $Platform,
    "-f", $DockerfilePath
) + $TagArgs + $CacheArgs + @($ContextPath)

Write-Host "Executing: docker $($BuildArgs -join ' ')"
Write-Host ""

& docker @BuildArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Build completed successfully!"
    Write-Host "=========================================="
    Write-Host "Available tags:"
    foreach ($Tag in $Tags) {
        Write-Host "  - $Tag"
    }
    Write-Host ""
    Write-Host "To run the container:"
    Write-Host "  ./run-local-arm64.sh"
} else {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Build failed with exit code: $LASTEXITCODE"
    Write-Host "=========================================="
    exit $LASTEXITCODE
}