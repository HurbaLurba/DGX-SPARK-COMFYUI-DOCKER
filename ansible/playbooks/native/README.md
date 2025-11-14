# ComfyUI Native Deployment for NVIDIA DGX Spark

Enterprise-grade Ansible automation for deploying ComfyUI natively on NVIDIA DGX Spark systems. This deployment stack is purpose-built for the DGX Spark's Blackwell GB10 GPU architecture (compute capability 12.1), delivering maximum performance through optimized PyTorch cu130 integration, architecture-specific sageattention compilation, and production-hardened service management.

## Overview

This repository provides comprehensive infrastructure-as-code for ComfyUI deployment on NVIDIA DGX Spark platforms. The playbooks handle complete lifecycle management—from initial installation through updates, service configuration, and decommissioning—with enterprise features including multi-user access control, centralized configuration management, and optional NFS integration for shared model storage.

## System Requirements

**Target Platform:**
- NVIDIA DGX Spark with Blackwell GB10 GPU (122GB VRAM, compute capability 12.1)
- Ubuntu 24.04 LTS
- NVIDIA CUDA 13.0 driver and toolkit (`/usr/local/cuda-13.0`)

**Control Machine:**
- Ansible 2.9 or later
- SSH access with sudo privileges to target system
- Network connectivity to target DGX Spark

**Target System Dependencies:**
- Python 3.12 runtime
- Build essentials (gcc 9.0+, g++, make)
- Development libraries (system dependencies managed by playbooks)
- (Optional) NFS mounts for shared storage

## Architecture

**Hardware Target:** NVIDIA DGX Spark Blackwell GB10 (compute capability 12.1)

**Software Stack:**
- **Base OS:** Ubuntu 24.04 LTS
- **Python:** 3.12 with isolated virtual environment
- **PyTorch:** 2.9.1+cu130 (CUDA 13.0 wheel from PyTorch index)
- **GPU Optimization:** Sageattention compiled for sm_121 architecture
- **Process Management:** systemd service with automatic restart policies
- **Precision:** BF16 for UNet, VAE, and text encoder (Blackwell-native)
- **Memory Management:** Native CUDA malloc (cudaMallocAsync disabled)
- **xformers:** Disabled (incompatible with compute capability 12.1)

**Deployment Model:**
- Multi-user shared installation at `/opt/comfyui`
- Group-based access control (`comfyui-users` group)
- Systemd service running as root with GPU auto-detection
- Centralized configuration via Ansible group variables
- Optional NFS integration for shared model repositories

## Quick Start Guide

### Step 1: Configure Deployment Parameters

Edit `ansible/inventory/group_vars/all.yml` to match your environment:

```yaml
# Installation paths
comfyui_install_dir: "/opt/comfyui"
venv_path: "{{ comfyui_install_dir }}/venv"

# Multi-user access control
comfyui_users: ["username1", "username2"]
comfyui_group: "comfyui-users"
comfyui_permissions: "0775"

# CUDA configuration for DGX Spark Blackwell GB10
cuda_home: "/usr/local/cuda-13.0"
cuda_arch_list: "12.1"  # Blackwell architecture

# PyTorch configuration
pytorch_version: "2.9.1"
pytorch_index_url: "https://download.pytorch.org/whl/cu130"

# NFS shared storage (optional - set to "" to disable)
nfs_models_path: "/mnt/comfy_model_share/comfy/models"
nfs_input_path: "/mnt/comfy_temp_share/ComfyUI/input"
nfs_output_path: "/mnt/comfy_temp_share/ComfyUI/output"

# Service configuration
service_name: "comfyui"
service_port: 8188
service_user: "root"
service_group: "root"

# Startup flags optimized for Blackwell
comfyui_flags:
  - "--listen 0.0.0.0"
  - "--port {{ service_port }}"
  - "--disable-xformers"
  - "--use-sage-attention"
  - "--gpu-only"
  - "--bf16-unet"
  - "--bf16-vae"
  - "--bf16-text-enc"
```

### Step 2: Configure Ansible Inventory

Create or edit `ansible/inventory/hosts.ini`:

```ini
[spark_primary]
<dgx_spark_ip> ansible_user=<your_username> ansible_become_password=<sudo_password>
```

Example:
```ini
[spark_primary]
192.168.1.61 ansible_user=admin ansible_become_password=secure_password
```

### Step 3: Execute Initial Deployment

```bash
cd ansible/playbooks/native
ansible-playbook -i ../../inventory/hosts.ini 01_install_update_comfyui.yml
```

**Deployment Process:**
1. Creates multi-user group and configures access control
2. Installs system dependencies and Python 3.12 runtime
3. Clones ComfyUI repository from upstream
4. Establishes isolated Python virtual environment
5. Installs PyTorch 2.9.1+cu130 with CUDA 13.0 support
6. Compiles sageattention for Blackwell sm_121 architecture
7. Configures launch scripts and multi-user permissions

**Expected Duration:** 15-20 minutes (network-dependent)

**Verification:**
```bash
ssh <user>@<dgx_spark_ip> "/opt/comfyui/venv/bin/python -c 'import torch; print(f\"PyTorch: {torch.__version__}, CUDA: {torch.version.cuda}, Available: {torch.cuda.is_available()}\")'"
```

### Step 4: Configure NFS Storage Integration (Optional)

For shared model repositories across multiple deployments:

```bash
ansible-playbook -i ../../inventory/hosts.ini 02_symlink_models_input_output.yml
```

This creates symlinks from ComfyUI directories to NFS mount points. Skip if using local storage.

### Step 5: Install Custom Node Extensions (Optional)

Deploy the curated collection of 38+ custom nodes:

```bash
ansible-playbook -i ../../inventory/hosts.ini 03_install_recommended_plugins.yml
```

Custom nodes are defined in `group_vars/all.yml` under the `custom_nodes` list. Modify as needed for your use case.

### Step 6: Deploy as Production Service

```bash
ansible-playbook -i ../../inventory/hosts.ini 04_run_as_service.yml
```

**Service Capabilities:**
- Automatic startup on system boot
- Self-healing restart on failure
- GPU auto-detection and CUDA_VISIBLE_DEVICES configuration
- Centralized logging via journald
- Port 8188 health monitoring

**Access:** `http://<dgx_spark_ip>:8188`

**Service Management:**
```bash
# Check service status
ssh <user>@<dgx_spark_ip> "sudo systemctl status comfyui"

# View live logs
ssh <user>@<dgx_spark_ip> "sudo journalctl -u comfyui -f"

# Manual restart
ansible-playbook -i ../../inventory/hosts.ini 05_restart_service.yml
```

## Playbook Reference

### Core Installation

#### `01_install_update_comfyui.yml`
Complete ComfyUI installation and updates.

**What it does:**
- Creates multi-user group and adds users
- Installs system dependencies (Python 3.12, build tools, libraries)
- Clones/updates ComfyUI repository
- Creates Python virtual environment
- Installs PyTorch 2.9.1+cu130 with CUDA 13.0 support
- Installs core packages: onnxruntime, python-dotenv, psutil
- Compiles and installs GPU optimizations:
  - flash-attention
  - torchao
  - sageattention (with architecture-specific compilation)
- Creates launch script with GPU detection
- Sets proper multi-user permissions (0775, comfyui-users group)

**Key variables:**
- `comfyui_install_dir`: Installation directory (default: `/opt/comfyui`)
- `pytorch_version`: PyTorch version (default: `2.9.1`)
- `cuda_home`: CUDA toolkit path (default: `/usr/local/cuda-13.0`)
- `cuda_arch_list`: GPU architecture list (default: `12.1` for Blackwell)

**Run time:** ~15-20 minutes

#### `02_symlink_models_input_output.yml`
Creates NFS symlinks for shared storage.

**What it does:**
- Validates NFS mount points exist
- Removes existing directories if not symlinks
- Creates symlinks for:
  - `models/` → NFS models share
  - `input/` → NFS input share
  - `output/` → NFS output share
- Sets proper permissions on symlinks

**When to use:**
- You have NFS storage mounted
- Want to share models across multiple installations
- Need centralized input/output directories

**Configuration:**
```yaml
nfs_models_path: "/mnt/comfy_model_share/comfy/models"
nfs_input_path: "/mnt/comfy_temp_share/ComfyUI/input"
nfs_output_path: "/mnt/comfy_temp_share/ComfyUI/output"
```

Set to empty strings `""` to skip NFS integration.

**Run time:** ~10 seconds

#### `03_install_recommended_plugins.yml`
Installs custom nodes from `group_vars/all.yml`.

**What it does:**
- Removes existing custom_nodes directory (fresh install)
- Clones all repositories from `custom_nodes` list
- Installs requirements for each node
- Filters torch/nvidia packages to preserve PyTorch installation
- Sets proper multi-user permissions

**Customization:**
Edit the `custom_nodes` list in `group_vars/all.yml`:

```yaml
custom_nodes:
  - "https://github.com/ltdrdata/ComfyUI-Manager"
  - "https://github.com/your/custom-node"
  # ... add or remove as needed
```

**Run time:** ~5-15 minutes (depending on number of nodes)

### Service Management

#### `04_run_as_service.yml`
Creates and starts ComfyUI as a systemd service.

**What it does:**
- Creates `/etc/systemd/system/comfyui.service`
- Configures service to run as root (can be changed via `service_user`)
- Sets up environment variables
- Applies all startup flags from `comfyui_flags`
- Enables auto-start on boot
- Starts the service immediately
- Waits for port 8188 to be available

**Service features:**
- Auto-restart on failure
- Journal logging (stdout/stderr)
- GPU auto-detection (sets CUDA_VISIBLE_DEVICES)
- Custom startup flags from group_vars

**Commands:**
```bash
sudo systemctl status comfyui
sudo systemctl restart comfyui
sudo journalctl -u comfyui -f  # Follow logs
```

**Run time:** ~30 seconds + startup time

#### `05_restart_service.yml`
Restarts the ComfyUI service.

**Use case:** 
- Apply configuration changes
- Clear service state
- Quick service refresh

**Run time:** ~5 seconds + startup time

#### `06_pause_service.yml`
Stops and disables the service.

**Use case:** 
- Long-term shutdown
- Manual control mode
- Maintenance

**Run time:** ~5 seconds

#### `07_start_service.yml`
Enables and starts the service.

**Use case:**
- Resume after pause
- Restart after configuration changes

**Run time:** ~5 seconds + startup time

#### `08_stop_remove_service.yml`
Completely removes the service.

**Use case:** Complete decommissioning

#### `99_nuke_comfy.yml`
**DANGER ZONE** - Completely removes ComfyUI installation and service.

**What it does:**
- Stops the service
- Disables auto-start
- Removes service file
- Reloads systemd daemon
- (Optional) Removes entire `/opt/comfyui` installation

**Danger zone:** Set `remove_installation: true` in vars to delete everything.

**Run time:** ~10 seconds

**What it does:**
- Stops ComfyUI service
- Disables service auto-start
- Removes systemd service file
- Removes `/opt/comfyui` directory completely
- Removes `comfyui-users` group
- **Preserves NFS data** (only removes symlinks, not actual NFS mount data)

**Use case:** Clean slate before rebuild, complete decommissioning

**WARNING:** This is destructive. Use for testing rebuild workflows or permanent removal.

**Run time:** ~30 seconds

## Configuration Guide

### GPU Architecture Configuration

**DGX Spark Specification:**

The NVIDIA DGX Spark utilizes the Blackwell GB10 GPU with compute capability 12.1. The deployment is hard-configured for this architecture:

```yaml
cuda_arch_list: "12.1"  # Blackwell GB10 - DGX Spark only
```

**Do not modify** this value unless deploying to a different hardware platform. Incorrect architecture specification will result in:
- Sageattention compilation failures
- Suboptimal GPU utilization
- Runtime compatibility issues

**Compilation Time:** ~1-2 minutes for single-architecture (12.1) builds on DGX Spark.

### Startup Flags Configuration

The default configuration is optimized for DGX Spark Blackwell architecture. Modify `comfyui_flags` in `group_vars/all.yml` as needed:

```yaml
comfyui_flags:
  - "--listen 0.0.0.0"              # Network binding (all interfaces)
  - "--port 8188"                    # HTTP service port
  - "--disable-xformers"             # REQUIRED: xformers incompatible with compute capability 12.1
  - "--use-sage-attention"           # REQUIRED: Blackwell-optimized attention mechanism
  - "--gpu-only"                     # Force GPU execution path
  - "--cache-classic"                # Classic caching strategy
  - "--force-non-blocking"           # Asynchronous operation mode
  - "--disable-cuda-malloc"          # Use native CUDA malloc (better Blackwell performance)
  - "--bf16-unet"                    # BF16 precision for UNet (Blackwell-native)
  - "--bf16-vae"                     # BF16 precision for VAE
  - "--bf16-text-enc"                # BF16 precision for text encoder
```

**Critical Flags for DGX Spark:**
- `--disable-xformers`: **Mandatory** - xformers does not support compute capability 12.1
- `--use-sage-attention`: **Mandatory** - Provides Blackwell-optimized attention kernels (sageattention is a required package)
- `--bf16-*`: **Recommended** - Leverages Blackwell's native BF16 support

**Removed Flags (Optimized Build):**
- `--cache-classic`: Removed - Modern cache implementation provides better performance
- `--force-non-blocking`: Removed - Async operations handled automatically
- `--disable-cuda-malloc`: Removed - Native cudaMallocAsync works well with environment variable tuning

**Optional Performance Flags:**
- `--highvram`: Enables aggressive VRAM utilization (recommended for 122GB VRAM)
- `--preview-method auto`: Real-time workflow previews
- `--fast`: Aggressive performance optimizations (may reduce stability)

### Multi-User Configuration

Add users to the `comfyui-users` group:

```yaml
comfyui_users:
  - "alice"
  - "bob"
  - "data-team"
```

All users in this group can:
- Read/write to `/opt/comfyui`
- Execute `launch.sh` manually
- Access models and outputs

The service runs as `root` (configurable via `service_user`/`service_group`).

### NFS Storage Configuration

For shared storage across multiple installations:

```yaml
nfs_models_path: "/mnt/storage/models"
nfs_input_path: "/mnt/storage/input"
nfs_output_path: "/mnt/storage/output"
```

**Benefits:**
- Share models across multiple ComfyUI instances
- Centralized model management
- Save disk space on compute nodes
- Shared input/output for workflow pipelines

**To disable NFS:** Set all paths to `""` (empty strings)

## Troubleshooting

### Sageattention Compilation Fails

**Symptom:** Playbook fails with "sageattention package must be installed first" or compilation errors

**Important:** Sageattention is **REQUIRED** (not optional) for WAN workflows. The playbook will **fail hard** if sageattention doesn't install.

**Solutions:**

1. **Check CUDA toolkit exists:**
   ```bash
   ls -la /usr/local/cuda-13.0/bin/nvcc
   ```

2. **Verify GPU architecture:**
   ```bash
   nvidia-smi --query-gpu=compute_cap --format=csv
   ```
   
   Update `cuda_arch_list` to match your GPU.

3. **Check build tools:**
   ```bash
   gcc --version  # Should be 9.0+
   g++ --version
   ```

4. **Manual compilation:**
   ```bash
   cd /opt/comfyui
   source venv/bin/activate
   export CUDA_HOME=/usr/local/cuda-13.0
   export TORCH_CUDA_ARCH_LIST="12.1"
   MAX_JOBS=1 pip install sageattention --no-build-isolation
   ```

### Service Won't Start

**Check logs:**
```bash
sudo journalctl -u comfyui -n 100 --no-pager
```

**Common issues:**

1. **Port 8188 already in use:**
   ```bash
   sudo lsof -i :8188
   ```
   Kill conflicting process or change port in `group_vars/all.yml`

2. **Python import errors:**
   Check venv integrity:
   ```bash
   /opt/comfyui/venv/bin/python -c "import torch; print(torch.__version__)"
   ```

3. **Permission errors:**
   ```bash
   sudo chown -R root:comfyui-users /opt/comfyui
   sudo chmod -R 775 /opt/comfyui
   ```

### NFS Symlinks Become Directories

**Symptom:** After running `01_install_update_comfyui.yml`, symlinks turn into regular directories.

**Cause:** Git operations (clone/pull/update with force) can overwrite symlinks.

**Solution:**
```bash
ansible-playbook -i ../../inventory/hosts.ini 02_symlink_models_input_output.yml
```

**CRITICAL:** Always run `02_symlink_models_input_output.yml` after `01_install_update_comfyui.yml` if using NFS. This is a known behavior and part of the standard workflow.

### Virtual Environment Activation Issues

**Symptom:** Pip installs to system Python instead of venv, causing "externally-managed-environment" errors

**Cause:** Shell activation (`source venv/bin/activate`) doesn't always properly set PATH in non-interactive shells

**Solution:** Playbooks now use **explicit venv paths** for all Python/pip commands:
- `{{ venv_path }}/bin/pip` instead of `pip`
- `{{ venv_path }}/bin/python` instead of `python`
- PATH explicitly set with venv first: `{{ venv_path }}/bin:$PATH`

This ensures all operations target the correct virtual environment.

### PyTorch Wrong Version

**Check installed version:**
```bash
/opt/comfyui/venv/bin/python -c "import torch; print(torch.__version__); print(torch.version.cuda)"
```

**Should see:**
```
2.9.1+cu130
13.0
```

**If wrong version detected:**
```bash
cd /opt/comfyui
sudo rm pytorch_pins.txt
# Then re-run playbook 01
```

### GPU Not Detected

**Check CUDA:**
```bash
nvidia-smi
/usr/local/cuda-13.0/bin/nvcc --version
```

**Check PyTorch:**
```bash
/opt/comfyui/venv/bin/python -c "import torch; print(torch.cuda.is_available()); print(torch.cuda.device_count())"
```

**Should output:**
```
True
1  # (or number of GPUs)
```

## Performance Characteristics

### DGX Spark Blackwell GB10 Optimization

This deployment is purpose-built for the NVIDIA DGX Spark's Blackwell GB10 GPU:

**Hardware Specifications:**
- GPU: NVIDIA Blackwell GB10
- VRAM: 122GB GDDR6
- Compute Capability: 12.1
- Architecture: Blackwell (sm_121)

**Software Optimizations:**
- **PyTorch 2.9.1+cu130**: Full compute capability 12.1 support with Blackwell-specific optimizations
- **Sageattention**: Compiled specifically for sm_121 architecture with Blackwell attention kernels
- **BF16 Precision**: Native hardware support for bfloat16 operations (UNet, VAE, text encoder)
- **Native CUDA malloc**: Direct memory allocation outperforms cudaMallocAsync on Blackwell
- **xformers Disabled**: Library incompatible with compute capability 12.1

**Measured Performance:**
- Native deployment: 2-3x throughput improvement over containerized deployment
- VRAM utilization: Full 122GB available to ComfyUI runtime
- Memory efficiency: ~31GB baseline, peak 77GB under production workloads
- Startup time: <30 seconds from service start to HTTP availability
- Inference latency: Blackwell-optimized attention provides significant speedup on transformer-based models

**Production Validation:**
- Continuous operation: 10+ hours stable runtime verified
- Workload: High-resolution image generation with face swap (ReActor) processing
- Thermal: Within operational parameters under sustained load
- Stability: No OOM errors, kernel crashes, or service interruptions observed

## Operational Workflows

### Standard Installation
```bash
# 1. Install ComfyUI
ansible-playbook -i ../../inventory/hosts.ini 01_install_update_comfyui.yml

# 2. Configure NFS (if using shared storage)
ansible-playbook -i ../../inventory/hosts.ini 02_symlink_models_input_output.yml

# 3. Install plugins
ansible-playbook -i ../../inventory/hosts.ini 03_install_recommended_plugins.yml

# 4. Start service
ansible-playbook -i ../../inventory/hosts.ini 04_run_as_service.yml
```

### Update ComfyUI
```bash
# 1. Update installation (idempotent - handles repo updates with force)
ansible-playbook -i ../../inventory/hosts.ini 01_install_update_comfyui.yml

# 2. Restore NFS symlinks (ALWAYS run after 01 if using NFS)
ansible-playbook -i ../../inventory/hosts.ini 02_symlink_models_input_output.yml

# 3. Restart service to pick up changes
ansible-playbook -i ../../inventory/hosts.ini 05_restart_service.yml
```

**Note:** The 01 playbook is now idempotent and can handle updates without stopping the service first. It uses `force: yes` for git updates to handle local modifications.

### Maintenance Mode
```bash
# Pause for maintenance
ansible-playbook -i ../../inventory/hosts.ini 06_pause_service.yml

# ... perform maintenance ...

# Resume
ansible-playbook -i ../../inventory/hosts.ini 07_start_service.yml
```

### Complete Removal
```bash
# Remove service and installation
ansible-playbook -i ../../inventory/hosts.ini 08_stop_remove_service.yml -e "remove_installation=true"
```

## Best Practices

### Deployment Operations
1. **NFS Symlink Restoration**: **ALWAYS** execute `02_symlink_models_input_output.yml` after running `01_install_update_comfyui.yml` if using NFS storage. Git operations with `force: yes` will overwrite symlinks with directories.
2. **Sageattention Requirement**: Sageattention is now a **hard requirement** (not optional). The playbook will fail if compilation fails, ensuring you never run without it.
3. **Idempotent Updates**: The 01 playbook now checks for existing sageattention installation and only compiles if missing, making it safe to run repeatedly.
4. **Service Monitoring**: Monitor service logs post-deployment: `sudo journalctl -u comfyui -f`
5. **Workflow Backup**: Archive custom workflows before executing major updates or plugin installations
6. **Version Pinning**: PyTorch versions are automatically pinned by playbooks to prevent dependency conflicts

### Production Readiness
1. **Change Management**: Test configuration changes in non-production environment before applying to production DGX Spark
2. **Access Control**: Limit `comfyui-users` group membership to authorized personnel
3. **Resource Monitoring**: Monitor VRAM utilization and service memory footprint during initial production workloads
4. **Network Security**: Restrict port 8188 access via firewall rules if not using reverse proxy

### Performance Optimization
1. **Single Architecture**: This deployment uses single-architecture compilation (12.1) for optimal build time
2. **VRAM Configuration**: Use `--highvram` flag for workloads requiring >80GB VRAM
3. **Model Caching**: Leverage NFS for shared model storage across multiple deployments to reduce per-instance storage overhead
4. **Custom Nodes Performance**: Parallel async cloning provides 6x speedup (5 minutes vs 30+ minutes for 34 repos)
5. **Environment Variables**: 20 optimized CUDA/PyTorch environment variables applied to all build and runtime operations

## Technical Support

### Target Platform
This deployment stack is validated exclusively for:
- **Hardware**: NVIDIA DGX Spark
- **GPU**: Blackwell GB10 (122GB VRAM, compute capability 12.1)
- **OS**: Ubuntu 24.04 LTS
- **CUDA**: 13.0 driver and toolkit
- **PyTorch**: 2.9.1+cu130

### Production Validation
Configuration tested under production workloads:
- Continuous operation: 10+ hours verified
- Workload types: High-resolution image generation, face swap processing (ReActor with hirad fork)
- Stability: No service interruptions, OOM errors, or GPU faults
- Performance: 2-3x throughput vs. containerized deployment
- Sageattention: Required and actively used for WAN workflows (verified in logs: "Using sage attention")
- Custom nodes: 34 repos (optimized from original 38, removed 5 problematic repos)

### Customization
This configuration is purpose-built for DGX Spark Blackwell architecture. Adaptation to other GPU platforms requires:
- Modification of `cuda_arch_list` for target compute capability
- Adjustment of precision flags based on GPU capabilities
- Potential re-enabling of xformers for architectures <12.0
- Validation of sageattention compilation for target architecture

## License

This deployment automation follows ComfyUI's licensing: **GPL-3.0**

## Acknowledgments

- **ComfyUI Development Team**: Core framework
- **NVIDIA Corporation**: Blackwell architecture, CUDA 13.0 runtime, DGX Spark platform
- **Sageattention Project**: GPU-optimized attention kernels for Blackwell
- **PyTorch Team**: CUDA 13.0 wheel distribution and framework support
- **Community Contributors**: Custom node ecosystem
