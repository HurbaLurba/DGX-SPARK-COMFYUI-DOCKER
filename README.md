# ComfyUI on NVIDIA DGX Spark

Production-grade Ansible automation for deploying ComfyUI on NVIDIA DGX Spark systems with Blackwell GB10 GPU architecture.

## What This Does

This repo automates the entire ComfyUI setup process on DGX Spark hardware. It handles everything from installing Python and CUDA dependencies to setting up a systemd service that runs on boot. The whole thing is built around Ansible playbooks so you can deploy consistently across multiple machines.

The native installation path is production-ready and has been running stable for 10+ hours straight with heavy workloads (face swaps, high-res generation, complex workflows). Docker deployment is still WIP and not ready yet.

## Why Native vs Docker?

Short answer: performance. The native install is 2-3x faster than containerized setups and doesn't have the memory overhead. For production workloads on expensive GPU hardware, that matters.

## What's Optimized Here

This setup is tuned specifically for the Blackwell GB10 architecture with unified memory fabric (compute capability 12.1):

**Precision & Attention (The Key):**
- **FP16 precision** - Force FP16 for unet/vae/text encoder (enables SageAttention, 2x smaller than FP32)
- **SageAttention enabled** - Fast attention for Blackwell tensor cores (requires FP16/BF16)
- **Flash Attention** - Included by default for standard workloads
- **No attention upcasting** - Keeps attention operations in FP16 for maximum speed

**Memory Management (Embrace the Fabric):**
- **Default caching enabled** - Let ComfyUI use natural caching behavior
- **Default memory mapping** - Allow mmap for model loading
- **No pinned memory** - `--disable-pinned-memory` reduces overhead on unified fabric
- **Let it breathe** - Unified memory works best when you don't force GPU-only mode

**CUDA Tuning:**
- **Disabled CUDA/PyTorch caching** - `CUDA_CACHE_DISABLE=1`, `PYTORCH_NO_CUDA_MEMORY_CACHING=1`
- **Managed memory force** - `CUDA_MANAGED_FORCE_DEVICE_ALLOC=1` for GPU-preferred allocation
- **Single CUDA connection** - `CUDA_DEVICE_MAX_CONNECTIONS=1`, 4 copy connections
- **OpenMP threads** - `OMP_NUM_THREADS=20` for parallel CPU work
- **EAGER module loading** - Immediate kernel loading for predictable performance
- **PyTorch 2.9.1 with CUDA 13.0** - Latest stable with Blackwell support

**System-level GPU optimizations** - Locked clocks, vboost, memory tuning, I/O optimizations (see `ansible/scripts/`)

**Performance Results:**
- Model loading: **Fast and instant** (natural caching works)
- Sampler speed: **Significantly faster** than forced GPU-only configs
- Power efficiency: Lower power draw with better performance
- Unified memory fabric: Works best when you embrace RAM offload, not fight it

## Quick Start

**What you need:**
- DGX Spark with Blackwell GB10 GPU
- Ubuntu 24.04 with CUDA 13.0 drivers installed
- Ansible on your local machine (WSL works fine)
- SSH access to the DGX with sudo

**Installation steps:**

```bash
cd ansible/playbooks/native

# 1. Install ComfyUI with PyTorch and flash-attention
ansible-playbook -i ../../inventory/hosts.ini 01_install_update_comfyui.yml

# 2. (Optional) Set up NFS storage for models - skip if using local storage
ansible-playbook -i ../../inventory/hosts.ini 02_symlink_models_input_output.yml

# 3. Install custom nodes (ComfyUI-Manager, Impact Pack, etc.)
ansible-playbook -i ../../inventory/hosts.ini 03_install_recommended_plugins.yml

# 4. Set up as a systemd service (auto-starts on boot)
ansible-playbook -i ../../inventory/hosts.ini 04_run_as_service.yml

# 5. (Optional) Install SageAttention - recommended for FLUX and large models
ansible-playbook -i ../../inventory/hosts.ini 09_install_sageattention_blackwell.yml

# 6. (Optional but recommended) Apply GPU optimizations for max performance
ansible-playbook -i ../../inventory/hosts.ini 10_complete_optimize.yml
```

Then open `http://<your-dgx-ip>:8188` and you're good to go.

**After reboots:** GPU clocks reset due to hardware limitations. Re-apply with:
```bash
ansible-playbook -i ../../inventory/hosts.ini 11_apply_non_persistent.yml
```

## Configuration

Everything is controlled through `ansible/inventory/group_vars/all.yml`:

**Core Settings:**
- Installation paths and Python/CUDA versions
- Service configuration (port, user, etc.)

**ComfyUI Flags (Optimized for Grace-Blackwell Unified Memory):**
```yaml
- "--use-sage-attention"    # Blackwell-optimized attention
- "--fp16-unet/vae/text-enc" # FP16 precision for SageAttention
- "--force-fp16"            # Enforce FP16 everywhere
- "--dont-upcast-attention" # Keep attention in FP16 for speed
- "--disable-pinned-memory" # Reduce overhead on unified fabric
# Default caching and mmap enabled - let the fabric work naturally
```

**CUDA Environment (Tuned for Unified Memory Fabric):**
```yaml
CUDA_CACHE_DISABLE: "1"                       # No CUDA kernel caching
PYTORCH_NO_CUDA_MEMORY_CACHING: "1"           # No PyTorch memory caching
CUDA_DEVICE_MAX_CONNECTIONS: "1"              # Single CUDA connection
CUDA_DEVICE_MAX_COPY_CONNECTIONS: "4"         # 4 copy connections for throughput
CUDA_MODULE_LOADING: "EAGER"                  # Immediate kernel loading
CUDA_MANAGED_FORCE_DEVICE_ALLOC: "1"          # Prefer GPU allocation
OMP_NUM_THREADS: "20"                         # OpenMP parallelism
CUBLAS_WORKSPACE_CONFIG: ":0:0"               # Minimal workspace overhead
```

**Why These Settings Matter:**
Unified memory architecture is fundamentally different from discrete GPUs. The key insight: **embrace the RAM offload, don't fight it**. Forcing everything GPU-side (--gpu-only, --cache-none) actually hurts performance because you're fighting the fabric's natural flow. Instead, use FP16 precision to enable SageAttention, disable pinned memory to reduce overhead, and let the unified memory fabric handle the rest. The result is faster model loading, faster sampling, and lower power consumption.

Check the [Native Deployment Guide](ansible/playbooks/native/README.md) for all configuration options.

## What's Working

This has been tested and validated for:

## What's Working

This setup has been tested and works reliably with:

- **10+ hour continuous runs** without crashes or memory leaks
- **High-resolution image generation** (no OOM errors)
- **Complex workflows** with face swapping (ReActor nodes), upscaling, etc.
- **Parallel custom node installation** (5 minutes vs 30+ sequential)
- **System-level optimizations** for locked GPU clocks, memory tuning, I/O performance

## Where This Is At

**Current Status:** Native installation is solid and production-ready. This is as tuned as we're going to get for bare-metal deployment.

**Next Steps:** Docker packaging is next on the roadmap, but for now the native install works great and gives better performance anyway.

**GPU Optimization:** There's a full GPU optimization suite in `ansible/scripts/` with playbooks for locking clocks, tuning memory/I/O, and making it all persistent. Check the [GPU Optimization README](ansible/scripts/README.md) for details.

## File Structure

```
ansible/
├── inventory/
│   ├── hosts.ini                              # Your DGX Spark IPs
│   └── group_vars/all.yml                     # All the config knobs
├── playbooks/native/
│   ├── 01_install_update_comfyui.yml          # Main install
│   ├── 02_symlink_models_input_output.yml     # Storage setup
│   ├── 03_install_recommended_plugins.yml     # Custom nodes
│   ├── 04_run_as_service.yml                  # Systemd service
│   ├── 05-08_*.yml                            # Service management utils
│   ├── 09_install_sageattention_blackwell.yml # Optional FLUX optimization
│   ├── 10_complete_optimize.yml               # GPU/system tuning
│   ├── 11_apply_non_persistent.yml            # Post-reboot GPU restore
│   ├── 99_nuke_comfy.yml                      # Clean uninstall
│   └── README.md                              # Detailed docs
└── scripts/
    ├── gpu_optimize.sh                        # GPU clock locking, vboost
    ├── system_optimize.sh                     # Memory, I/O, network tuning
    ├── make_persistent.sh                     # Persistence configs
    └── README.md                              # Optimization guide

docker/                                         # WIP, not ready yet
```

## Docs

- **[Native Deployment Guide](ansible/playbooks/native/README.md)** - Full installation guide with all the details
- **[GPU Optimization README](ansible/scripts/README.md)** - Performance tuning for GB10
- **[SageAttention Installation](ansible/playbooks/native/09_install_sageattention_blackwell.md)** - Building sage attention for Blackwell

## Notes

**Unified Memory Architecture - The Real Discovery:** Grace-Blackwell's unified memory fabric is fundamentally different from discrete GPUs. The breakthrough: **don't force GPU-only mode**. Let the fabric naturally flow between GPU and RAM. Forcing everything GPU-side (--gpu-only, --cache-none, --disable-mmap) fights the architecture and hurts performance. Instead, use FP16 precision for SageAttention, disable pinned memory to reduce overhead, and embrace default caching/mmap behavior. The fabric knows what it's doing.

**SageAttention:** Requires FP16 or BF16 precision. FP32 will fall back to slow PyTorch attention. The `--force-fp16` config enables full SageAttention acceleration on Blackwell tensor cores.

**Model Loading Speed:** With natural caching and memory mapping enabled, model loading is instant. Fighting the fabric with --cache-none actually made it slower (30-40s). Let it breathe.

**The Magic Combo:** 
- FP16 everywhere (--force-fp16, --fp16-unet/vae/text-enc)
- SageAttention enabled
- Don't upcast attention (--dont-upcast-attention)
- Disable pinned memory (--disable-pinned-memory)
- Default caching/mmap (no --cache-none, no --disable-mmap)
- Let unified memory manage GPU/RAM flow naturally

**GPU Clock Persistence:** Clock settings don't persist across reboots due to GB10 firmware behavior. Run playbook 11 after each boot (~5 seconds) to restore max clocks and vboost.

**Docker Status:** Docker deployment is in progress but not ready. Native install is production-ready and delivers better performance on unified memory architecture.

## License

See [LICENSE](LICENSE).

