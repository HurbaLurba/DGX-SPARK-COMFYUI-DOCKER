#!/bin/bash
# Run script for ComfyUI Docker container on DGX Spark (ARM64)

set -e

VERSION="${VERSION:-0.08}"
REGISTRY="${REGISTRY:-local}"
CONTAINER_NAME="${CONTAINER_NAME:-comfyui-dgx-spark}"
PORT="${PORT:-8188}"
MODELS_PATH="${MODELS_PATH:-}"
INPUT_PATH="${INPUT_PATH:-}"
OUTPUT_PATH="${OUTPUT_PATH:-}"
TEMP_PATH="${TEMP_PATH:-}"

echo "=========================================="
echo "Running ComfyUI Docker Container (ARM64)"
echo "Version: $VERSION"
echo "Container Name: $CONTAINER_NAME"
echo "Port: $PORT"
echo "=========================================="

# Set image name
IMAGE_NAME="${REGISTRY}/comfyui-dgx:${VERSION}-arm64"

# Check if container already exists
if docker ps -a --filter "name=$CONTAINER_NAME" --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping and removing existing container: $CONTAINER_NAME"
    docker stop "$CONTAINER_NAME" 2>/dev/null || true
    docker rm "$CONTAINER_NAME" 2>/dev/null || true
fi

# Build docker run arguments
DOCKER_ARGS=(
    "run"
    "-d"
    "--name" "$CONTAINER_NAME"
    "--gpus" "all"
    "-p" "${PORT}:8188"
    "--restart" "unless-stopped"
)

# Add volume mounts for custom paths
if [ -n "$MODELS_PATH" ]; then
    echo "Mounting models path: $MODELS_PATH"
    DOCKER_ARGS+=("-v" "${MODELS_PATH}:/workspace/ComfyUI/models")
    DOCKER_ARGS+=("-e" "MODEL_BASE_PATH=/workspace/ComfyUI/models")
fi

if [ -n "$INPUT_PATH" ]; then
    echo "Mounting input path: $INPUT_PATH"
    DOCKER_ARGS+=("-v" "${INPUT_PATH}:/workspace/ComfyUI/input")
    DOCKER_ARGS+=("-e" "INPUT_DIR=/workspace/ComfyUI/input")
fi

if [ -n "$OUTPUT_PATH" ]; then
    echo "Mounting output path: $OUTPUT_PATH"
    DOCKER_ARGS+=("-v" "${OUTPUT_PATH}:/workspace/ComfyUI/output")
    DOCKER_ARGS+=("-e" "OUTPUT_DIR=/workspace/ComfyUI/output")
fi

if [ -n "$TEMP_PATH" ]; then
    echo "Mounting temp path: $TEMP_PATH"
    DOCKER_ARGS+=("-v" "${TEMP_PATH}:/workspace/ComfyUI/temp")
    DOCKER_ARGS+=("-e" "TEMP_DIR=/workspace/ComfyUI/temp")
fi

# Add environment variables
DOCKER_ARGS+=("-e" "COMFYUI_PORT=8188")

# Add image name
DOCKER_ARGS+=("$IMAGE_NAME")

# Add any extra arguments passed to this script
if [ $# -gt 0 ]; then
    DOCKER_ARGS+=("$@")
fi

echo ""
echo "Executing: docker ${DOCKER_ARGS[*]}"
echo ""

# Run the container
docker "${DOCKER_ARGS[@]}"

if [ $? -eq 0 ]; then
    echo ""
    echo "=========================================="
    echo "Container started successfully!"
    echo "=========================================="
    echo "ComfyUI is available at: http://localhost:$PORT"
    echo ""
    echo "To view logs:"
    echo "  docker logs -f $CONTAINER_NAME"
    echo ""
    echo "To stop the container:"
    echo "  docker stop $CONTAINER_NAME"
    echo ""
    echo "To remove the container:"
    echo "  docker rm $CONTAINER_NAME"
else
    echo ""
    echo "=========================================="
    echo "Failed to start container!"
    echo "=========================================="
    exit 1
fi