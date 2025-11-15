# SageAttention Blackwell (sm_121a) Installation

This playbook installs SageAttention with native support for NVIDIA Blackwell GB10 GPUs (compute capability 12.1).

## What It Does

1. **Custom Triton Build**: Builds Triton from main branch (commit 4caa0328) with sm_121a PTX support
2. **SageAttention v2.2.0**: Builds from PR #297 (commit 93b30a3) with native sm_121a CUDA kernels
3. **Dependency Order**: Installs Triton first, then sageattention with `--no-deps` to preserve custom Triton

## Why This Is Required

- **Official Triton 3.5.1**: Does NOT support sm_121a (only up to sm_120)
- **Official SageAttention wheels**: Lack sm_121a CUDA kernels
- **PR #297 Solution**: Adds HAS_SM121 flag and native kernel support to ROOT package

## Technical Details

### Custom Triton
- **Source**: https://github.com/triton-lang/triton
- **Branch**: main
- **Commit**: 4caa0328bf8df64896dd5f6fb9df41b0eb2e750a
- **Why**: PTX compiler support for sm_121a architecture
- **Reference**: vLLM DGX Spark setup repository

### SageAttention v2.2.0
- **Source**: https://github.com/thu-ml/SageAttention
- **Branch**: PR #297
- **Commit**: 93b30a3b27652423508852e77de5f2afb9846b39
- **Features**:
  - `HAS_SM121` flag in setup.py
  - "12.1" added to `SUPPORTED_ARCHS`
  - sm_121a uses sm89 kernels (with bf16 support)
  - `-DENABLE_BF16` compiler flag enabled
  - Preserves standard `sageattn()` API (ComfyUI compatible)

### Build Configuration
- **TORCH_CUDA_ARCH_LIST**: `12.1` (critical for sm_121a kernel compilation)
- **MAX_JOBS**: `20` (parallel build for speed)
- **CMAKE_BUILD_PARALLEL_LEVEL**: `20`
- **TRITON_PTXAS_PATH**: `/usr/local/cuda/bin/ptxas`

## Usage

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/native/09_install_sageattention_blackwell.yml
```

## Verification

After installation, verify:

```bash
# Check versions
/opt/comfyui/venv/bin/pip list | grep -E "triton|sageattention"

# Expected output:
# triton                3.5.0+git4caa0328
# sageattention         2.2.0

# Test import
/opt/comfyui/venv/bin/python -c "from sageattention import sageattn; print('✓ Success')"
```

## What This Fixes

- ❌ **Before**: `missing sm121a` error during video generation
- ❌ **Before**: `ptxas fatal: Value 'sm_121a' is not defined for option 'gpu-name'`
- ✅ **After**: Native sm_121a kernel support
- ✅ **After**: Video generation works on Blackwell GB10 GPUs

## Notes

- No compatibility shim needed (native API compatibility)
- Build takes ~40 minutes total (Triton: ~30 min, SageAttention: ~10 min)
- Must use `--no-deps` when installing sageattention to preserve custom Triton
- The ROOT sageattention package is used (not the sageattention3_blackwell subdirectory)
