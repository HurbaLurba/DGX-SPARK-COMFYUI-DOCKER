# Quick Start Guide - ComfyUI Docker

## Test on RTX 5090 (Windows/AMD64)

### Step 1: Build the Image

```powershell
.\build-amd64.ps1
```

Expected output:
```
Building ComfyUI Docker Image (AMD64)
Version: 0.01
...
Build completed successfully!
```

### Step 2: Run Without Custom Paths (Test)

```powershell
.\run-local.ps1 -Detach
```

Access ComfyUI at: http://localhost:8188

### Step 3: Run With Custom Paths

First, create directories for your models, inputs, and outputs:

```powershell
# Create directories (adjust paths as needed)
New-Item -ItemType Directory -Path "D:\ComfyUI\models" -Force
New-Item -ItemType Directory -Path "D:\ComfyUI\input" -Force
New-Item -ItemType Directory -Path "D:\ComfyUI\output" -Force
New-Item -ItemType Directory -Path "D:\ComfyUI\temp" -Force
```

Then run with mounted volumes:

```powershell
.\run-local.ps1 `
    -ModelsPath "D:\ComfyUI\models" `
    -InputPath "D:\ComfyUI\input" `
    -OutputPath "D:\ComfyUI\output" `
    -TempPath "D:\ComfyUI\temp" `
    -Detach
```

### Step 4: Verify Everything Works

Check logs:
```powershell
docker logs -f comfyui-dgx-local
```

Look for:
- GPU detection: "GPU Information: ..."
- CUDA availability: "CUDA Available: True"
- Server starting: "Starting ComfyUI..."

### Step 5: Stop and Clean Up

```powershell
docker stop comfyui-dgx-local
docker rm comfyui-dgx-local
```

---

## Deploy on DGX Spark (Linux/ARM64)

### Step 1: Transfer Files to DGX Spark

```powershell
# From Windows machine, copy files to DGX Spark
scp -r docker/ user@dgx-spark:/path/to/comfyui-docker/
scp build-arm64.ps1 user@dgx-spark:/path/to/comfyui-docker/
scp run-local-arm64.sh user@dgx-spark:/path/to/comfyui-docker/
```

### Step 2: SSH to DGX Spark

```bash
ssh user@dgx-spark
cd /path/to/comfyui-docker
```

### Step 3: Build ARM64 Image

```bash
chmod +x build-arm64.ps1 run-local-arm64.sh
./build-arm64.ps1
```

### Step 4: Run on DGX Spark

Create shared directories:

```bash
sudo mkdir -p /mnt/cache/comfy/{models,input,output,temp}
sudo chmod -R 777 /mnt/cache/comfy
```

Run with mounted volumes:

```bash
MODELS_PATH="/mnt/cache/comfy/models" \
INPUT_PATH="/mnt/cache/comfy/input" \
OUTPUT_PATH="/mnt/cache/comfy/output" \
TEMP_PATH="/mnt/cache/comfy/temp" \
./run-local-arm64.sh
```

### Step 5: Verify on DGX Spark

```bash
docker logs -f comfyui-dgx-spark
```

Access ComfyUI at: http://dgx-spark-ip:8188

---

## Common Commands

### View Running Containers

```bash
docker ps
```

### View All Containers

```bash
docker ps -a
```

### View Images

```bash
docker images | grep comfyui
```

### Remove All Stopped Containers

```bash
docker container prune
```

### Remove Unused Images

```bash
docker image prune -a
```

### Interactive Shell Inside Container

```bash
docker exec -it comfyui-dgx-local bash
```

---

## Testing Checklist

- [ ] Image builds successfully (AMD64)
- [ ] Container starts without errors
- [ ] GPU is detected inside container
- [ ] ComfyUI web interface loads
- [ ] Can generate images with default workflow
- [ ] Custom nodes are available (check Manager)
- [ ] Custom model path works (if using external storage)
- [ ] Output images save to correct location
- [ ] Image builds successfully (ARM64) on DGX Spark
- [ ] Container runs on DGX Spark
- [ ] Network access works from other machines

---

## Troubleshooting Quick Fixes

### Container immediately exits

```bash
docker logs comfyui-dgx-local
```

Check for Python errors or missing dependencies.

### Can't access web interface

1. Check if container is running: `docker ps`
2. Check if port is available: `netstat -an | findstr 8188` (Windows) or `netstat -tulpn | grep 8188` (Linux)
3. Try a different port: `.\run-local.ps1 -Port 8889`

### GPU not detected

```bash
# Test NVIDIA runtime
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi

# If fails, reinstall NVIDIA Container Toolkit
```

### Out of memory errors

Add to run command:
```powershell
-ExtraArgs @("--normalvram")
```

Or for very large models:
```powershell
-ExtraArgs @("--lowvram")
```
