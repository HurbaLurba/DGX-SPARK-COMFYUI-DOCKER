# DGX-SPARK-COMFYUI-DOCKER

Enterprise-grade Ansible automation for deploying ComfyUI on NVIDIA DGX Spark with Blackwell GB10 GPUs.

## Overview

This repository provides comprehensive infrastructure-as-code for ComfyUI deployment on NVIDIA DGX Spark platforms. Optimized for Blackwell GB10 architecture (compute capability 12.1) with PyTorch 2.9.1+cu130, sageattention, and production-hardened service management.

**Key Features:**
- Native installation with systemd service management
- Multi-user access control via group permissions
- NFS integration for shared model storage
- Parallel async custom node installation (6x faster)
- 20 optimized CUDA/PyTorch environment variables
- Idempotent playbooks for safe updates
- Sageattention required and compiled for sm_121

## Quick Start

### Prerequisites
- NVIDIA DGX Spark with Blackwell GB10 GPU
- Ubuntu 24.04 LTS with CUDA 13.0
- Ansible 2.9+ on control machine
- SSH access with sudo privileges

### Configuration

1. **Edit configuration:** `ansible/inventory/group_vars/all.yml`
2. **Set inventory:** `ansible/inventory/hosts.ini`

### Deployment

```bash
cd ansible/playbooks/native

# 1. Install ComfyUI with PyTorch cu130 and sageattention
ansible-playbook -i ../../inventory/hosts.ini 01_install_update_comfyui.yml

# 2. Configure NFS symlinks (if using shared storage)
ansible-playbook -i ../../inventory/hosts.ini 02_symlink_models_input_output.yml

# 3. Install custom nodes (34 repos, parallel cloning)
ansible-playbook -i ../../inventory/hosts.ini 03_install_recommended_plugins.yml

# 4. Deploy as systemd service
ansible-playbook -i ../../inventory/hosts.ini 04_run_as_service.yml
```

**Access:** `http://<dgx_spark_ip>:8188`

## Documentation

Complete documentation available in:
- **[Native Deployment Guide](ansible/playbooks/native/README.md)** - Full playbook reference, configuration, troubleshooting

## Repository Structure

```
ansible/
├── inventory/
│   ├── hosts.ini                    # Target host configuration
│   └── group_vars/
│       └── all.yml                  # Centralized configuration (env vars, flags, custom nodes)
└── playbooks/
    └── native/
        ├── 01_install_update_comfyui.yml      # Core installation (idempotent)
        ├── 02_symlink_models_input_output.yml # NFS integration
        ├── 03_install_recommended_plugins.yml # Custom nodes (parallel async)
        ├── 04_run_as_service.yml              # Systemd service deployment
        ├── 05_restart_service.yml             # Service restart
        ├── 06_pause_service.yml               # Disable service
        ├── 07_start_service.yml               # Enable/start service
        ├── 08_stop_remove_service.yml         # Complete removal
        ├── 99_nuke_comfy.yml                  # Clean rebuild testing
        └── README.md                          # Complete documentation
```

## Key Optimizations

- **Sageattention Required:** Compiled for sm_121, mandatory for WAN workflows
- **Parallel Custom Nodes:** 5 minutes vs 30+ minutes (6x speedup)
- **Environment Variables:** 20 optimized CUDA/PyTorch settings for all operations
- **Idempotent Updates:** Safe to run 01 playbook repeatedly without wiping installation
- **Optimized Flags:** Removed unnecessary flags (--cache-classic, --force-non-blocking, --disable-cuda-malloc)

## Production Status

Validated for production workloads:
- ✅ Continuous 10+ hour operation
- ✅ High-resolution image generation
- ✅ Face swap processing (ReActor)
- ✅ No OOM errors or service interruptions
- ✅ 2-3x throughput vs containerized deployment

## License

See [LICENSE](LICENSE) for details.

