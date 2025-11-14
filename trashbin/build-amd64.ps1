#!/usr/bin/env pwsh
# Build script for ComfyUI Docker image (AMD64)

param(
    [string]# Configuration
$VERSION = "0.08",
    [string]$Registry = "local",
    [switch]$NoBuildCache
)

$ErrorActionPreference = "Stop"

Write-Host "=========================================="
Write-Host "Building ComfyUI Docker Image (AMD64)"
Write-Host "Version: $Version"
Write-Host "Registry: $Registry"
Write-Host "=========================================="

# Set build variables
$ImageName = "$Registry/comfyui-dgx"
$Platform = "linux/amd64"
$DockerfilePath = ".\docker\Dockerfile.comfyui-dgx"
$ContextPath = ".\docker"

# Build tags
$Tags = @(
    "${ImageName}:${Version}-amd64",
    "${ImageName}:latest-amd64"
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
    Write-Host "  .\run-local.ps1"
} else {
    Write-Host ""
    Write-Host "=========================================="
    Write-Host "Build failed with exit code: $LASTEXITCODE"
    Write-Host "=========================================="
    exit $LASTEXITCODE
}