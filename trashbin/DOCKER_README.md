# ComfyUI Docker for DGX Spark & High-End GPUs

Optimized Docker image for running ComfyUI on NVIDIA DGX Spark (ARM64) and high-end GPUs like RTX 6000 Pro Blackwell and RTX 5090 (AMD64).

## Features

- **Base Image**: NVIDIA PyTorch 25.10 (includes PyTorch, CUDA, and all dependencies)
- **Multi-Architecture**: Supports both AMD64 (x86_64) and ARM64 (aarch64)
- **Pre-installed Custom Nodes**:
  - ComfyUI-Manager
  - rgthree-comfy
  - ComfyUI_ExtraModels
  - ComfyUI-GGUF
- **Optimized for Performance**: GPU-accelerated with proper CUDA settings
- **Version Control**: Proper tagging and versioning (starting with v0.01)
- **Flexible Storage**: Support for external model/input/output/temp directories

## Version History

- **v0.01** (Initial Release)
  - Base image: nvcr.io/nvidia/pytorch:25.10-py3
  - AMD64 and ARM64 support
  - 4 custom nodes pre-installed
  - Configurable directory mounts

## Architecture Support

| Platform | Architecture | Tested On |
|----------|--------------|-----------|
| AMD64    | linux/amd64  | RTX 5090, RTX 6000 Pro Blackwell |
| ARM64    | linux/arm64  | NVIDIA DGX Spark |

## Prerequisites

- Docker Engine 20.10+
- NVIDIA Container Toolkit
- NVIDIA GPU with CUDA support
- PowerShell 7+ (for Windows) or Bash (for Linux)

## Building the Image

### For AMD64 (RTX 5090, RTX 6000 Pro Blackwell)

```powershell
# On Windows with PowerShell
.\build-amd64.ps1

# With custom version
.\build-amd64.ps1 -Version "0.02"

# Without cache (clean build)
.\build-amd64.ps1 -NoBuildCache
```

### For ARM64 (DGX Spark)

```bash
# On DGX Spark or ARM64 system
chmod +x build-arm64.ps1
./build-arm64.ps1

# With custom version
./build-arm64.ps1 -Version "0.02"
```

## Running the Container

### Quick Start (Default Settings)

```powershell
# On Windows/AMD64
.\run-local.ps1
```

```bash
# On DGX Spark/ARM64
chmod +x run-local-arm64.sh
./run-local-arm64.sh
```

ComfyUI will be available at: `http://localhost:8188`

### With Custom Storage Paths

```powershell
# On Windows/AMD64
.\run-local.ps1 `
    -ModelsPath "D:\ComfyUI\models" `
    -InputPath "D:\ComfyUI\input" `
    -OutputPath "D:\ComfyUI\output" `
    -TempPath "D:\ComfyUI\temp" `
    -Port 8188 `
    -Detach
```

```bash
# On DGX Spark/ARM64
MODELS_PATH="/mnt/cache/comfy/models" \
INPUT_PATH="/mnt/cache/comfy/input" \
OUTPUT_PATH="/mnt/cache/comfy/output" \
TEMP_PATH="/mnt/cache/comfy/temp" \
PORT=8188 \
./run-local-arm64.sh
```

### Advanced Options

```powershell
# Run with specific version and custom ComfyUI parameters
.\run-local.ps1 `
    -Version "0.01" `
    -ContainerName "my-comfyui" `
    -Port 8888 `
    -ExtraArgs @("--normalvram", "--cuda-malloc")
```

## Container Management

### View Logs

```bash
docker logs -f comfyui-dgx-local
```

### Stop Container

```bash
docker stop comfyui-dgx-local
```

### Restart Container

```bash
docker restart comfyui-dgx-local
```

### Remove Container

```bash
docker stop comfyui-dgx-local
docker rm comfyui-dgx-local
```

### Execute Commands Inside Container

```bash
docker exec -it comfyui-dgx-local bash
```

## Directory Structure

```
/workspace/ComfyUI/
├── models/           # AI models (can be mounted externally)
├── input/            # Input images (can be mounted externally)
├── output/           # Generated outputs (can be mounted externally)
├── temp/             # Temporary files (can be mounted externally)
├── custom_nodes/     # Custom node extensions
│   ├── ComfyUI-Manager/
│   ├── rgthree-comfy/
│   ├── ComfyUI_ExtraModels/
│   └── ComfyUI-GGUF/
└── extra_model_paths.yaml  # Model path configuration
```

## Environment Variables

The container supports the following environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `COMFYUI_PORT` | Port ComfyUI listens on | `8188` |
| `MODEL_BASE_PATH` | Base path for models | `/workspace/ComfyUI/models` |
| `INPUT_DIR` | Input directory | `/workspace/ComfyUI/input` |
| `OUTPUT_DIR` | Output directory | `/workspace/ComfyUI/output` |
| `TEMP_DIR` | Temporary directory | `/workspace/ComfyUI/temp` |

## Performance Optimization

The image includes optimized environment variables for GPU performance:

- `CUDA_LAUNCH_BLOCKING=1`
- `CUBLAS_WORKSPACE_CONFIG=:16:8`
- `PYTORCH_JIT_LOG_LEVEL=FATAL`
- And more...

## Custom Nodes

The following custom nodes are pre-installed:

1. **ComfyUI-Manager**: Node package manager for ComfyUI
2. **rgthree-comfy**: Enhanced workflow management nodes
3. **ComfyUI_ExtraModels**: Support for additional model formats
4. **ComfyUI-GGUF**: GGUF model format support

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker logs comfyui-dgx-local
```

### GPU Not Detected

Verify NVIDIA Container Toolkit:
```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

### Permission Issues with Mounted Volumes

Ensure mounted directories have proper permissions:
```bash
chmod -R 777 /path/to/mounted/directory
```

### Port Already in Use

Change the port mapping:
```powershell
.\run-local.ps1 -Port 8889
```

## Image Tags

| Tag Pattern | Description | Example |
|-------------|-------------|---------|
| `local/comfyui-dgx:0.01-amd64` | Specific version, AMD64 | `0.01-amd64` |
| `local/comfyui-dgx:0.01-arm64` | Specific version, ARM64 | `0.01-arm64` |
| `local/comfyui-dgx:latest-amd64` | Latest AMD64 | `latest-amd64` |
| `local/comfyui-dgx:latest-arm64` | Latest ARM64 | `latest-arm64` |

## Future Enhancements

- [ ] Multi-node cluster support
- [ ] Pre-downloaded common models
- [ ] Docker Compose configurations
- [ ] Automated model management
- [ ] Performance monitoring dashboard
- [ ] Additional custom nodes

## License

See main project LICENSE file.

## Support

For issues and questions, please open an issue on the GitHub repository.