#!/bin/bash
# Patch sageattention core.py to add sm_121 support
# sm_121 (Blackwell GB10) uses the same kernels as sm_120 (sm_90a extension)

set -e

CORE_PY_PATH="$1"

if [ -z "$CORE_PY_PATH" ]; then
    echo "Usage: $0 <path_to_core.py>"
    exit 1
fi

if [ ! -f "$CORE_PY_PATH" ]; then
    echo "Error: File not found: $CORE_PY_PATH"
    exit 1
fi

echo "=========================================="
echo "Patching sageattention core.py"
echo "Target: $CORE_PY_PATH"
echo "=========================================="

# Check if already patched
if grep -q 'elif arch == "sm121":' "$CORE_PY_PATH"; then
    echo "✓ Already patched: sm_121 support exists"
    exit 0
fi

echo "[1/3] Locating sm120 definition..."

# Find the line number of "elif arch == "sm120":"
LINE_NUM=$(grep -n 'elif arch == "sm120":' "$CORE_PY_PATH" | cut -d: -f1)

if [ -z "$LINE_NUM" ]; then
    echo "✗ ERROR: Could not find sm120 definition in $CORE_PY_PATH"
    exit 1
fi

echo "✓ Found sm120 at line $LINE_NUM"

# Find the return statement line (next line after elif)
RETURN_LINE=$((LINE_NUM + 1))

echo "[2/3] Inserting sm_121 support..."

# Create the patch content in a temp file
cat > /tmp/sm121_patch.txt << 'EOF'
    elif arch == "sm121":
        # Blackwell GB10 (compute capability 12.1) uses sm_90a kernels
        # The sm_120a specification handles 12.0 and 12.1 GPU variants
        return sageattn_qk_int8_pv_fp8_cuda(q, k, v, tensor_layout=tensor_layout, is_causal=is_causal, qk_quant_gran="per_warp", sm_scale=sm_scale, return_lse=return_lse, pv_accum_dtype="fp32+fp16")
EOF

# Insert the patch after the sm120 return statement using sed
sed -i "${RETURN_LINE}r /tmp/sm121_patch.txt" "$CORE_PY_PATH"

echo "[3/3] Verifying patch..."

# Verify the patch
if grep -q 'elif arch == "sm121":' "$CORE_PY_PATH"; then
    echo "✓ Successfully patched with sm_121 support"
    rm /tmp/sm121_patch.txt
    echo "=========================================="
    echo "✓ Patch complete!"
    echo "=========================================="
    exit 0
else
    echo "✗ ERROR: Patch verification failed"
    rm /tmp/sm121_patch.txt
    exit 1
fi
