#!/bin/bash
set -e

echo "=========================================="
echo "ComfyUI Container Starting"
echo "Version: 0.15"
echo "=========================================="

# Print GPU information
if command -v nvidia-smi &> /dev/null; then
    echo "GPU Information:"
    nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
    echo "=========================================="
fi

# Print PyTorch and CUDA information
echo "PyTorch Version: $(python -c 'import torch; print(torch.__version__)')"
echo "CUDA Available: $(python -c 'import torch; print(torch.cuda.is_available())')"
if python -c 'import torch; exit(0 if torch.cuda.is_available() else 1)'; then
    echo "CUDA Version: $(python -c 'import torch; print(torch.version.cuda)')"
    echo "GPU Count: $(python -c 'import torch; print(torch.cuda.device_count())')"
fi
echo "=========================================="

# Setup model paths if custom path is provided
if [ -n "$MODEL_BASE_PATH" ]; then
    echo "Setting up custom model path: $MODEL_BASE_PATH"
    cat > /workspace/ComfyUI/extra_model_paths.yaml << EOF
comfyui:
  base_path: $MODEL_BASE_PATH
  is_default: true
  checkpoints: checkpoints
  clip: clip
  clip_vision: clip_vision
  configs: configs
  controlnet: controlnet
  diffusion_models: |
    diffusion_models
    unet
  embeddings: embeddings
  loras: loras
  text_encoders: text_encoders
  upscale_models: upscale_models
  vae: vae
  reactor: reactor
EOF
fi

# Build command arguments
ARGS="--listen 0.0.0.0 --disable-xformers"

# Add optimization flags from environment variable
if [ -n "$COMFYUI_ARGS" ]; then
    ARGS="$ARGS $COMFYUI_ARGS"
fi

# Add port
if [ -n "$COMFYUI_PORT" ]; then
    ARGS="$ARGS --port $COMFYUI_PORT"
else
    ARGS="$ARGS --port 8188"
fi

# Add custom directories if provided
if [ -n "$INPUT_DIR" ]; then
    ARGS="$ARGS --input-directory $INPUT_DIR"
fi

if [ -n "$OUTPUT_DIR" ]; then
    ARGS="$ARGS --output-directory $OUTPUT_DIR"
fi

if [ -n "$TEMP_DIR" ]; then
    ARGS="$ARGS --temp-directory $TEMP_DIR"
fi

# Add any custom parameters passed to the container
if [ $# -gt 0 ]; then
    ARGS="$ARGS $@"
fi

echo "Starting ComfyUI with arguments: $ARGS"
echo "=========================================="

# Start ComfyUI
cd /workspace/ComfyUI
exec python main.py $ARGS