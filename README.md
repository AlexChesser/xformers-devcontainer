# xformers Dev Container

Pre-configured Visual Studio Code Dev Container for developing against `xformers` with GPU acceleration. The this system will check out an editable install of your fork at first run.

The approximate runtime of a first time setup was ~27 minues on an `AMD Ryzen 7 5800X 8-Core Processor, 3801 Mhz` running under WSL on Windows 11 Pro. 


## What is this?

This repository provides a GPU-ready, reproducible development environment for the `xformers` project. The Dockerfile installs CUDA/PyTorch/Triton toolchains directly and the post-create step clones your fork (with submodules) and installs it in editable mode for rapid iteration.


## Prerequisites

- Docker with Buildx enabled
- VS Code + Dev Containers extension (or Cursor)
- NVIDIA GPU with drivers installed and NVIDIA Container Toolkit configured for Docker
- Windows 11 with WSL2, or a Linux host (macOS works for CPU-only, but GPU passthrough is not supported)
- Sufficient disk space: ~18 GB for base images and caches

Tip for Windows: ensure Docker Desktop has WSL2 integration enabled and that `nvidia-smi` works on the host first.

## Quick start

1) Fork the upstream repository
- Go to `https://github.com/facebookresearch/xformers` and create your fork.

2) Clone this devcontainer repo
```bash
git clone https://github.com/AlexChesser/xformers-devcontainer.git
```

3) Point the devcontainer at your fork
- Edit `.devcontainer/devcontainer.local.json` and set your fork URL. Replace `<my-github-username>` with the github username of your fork (eg: `https://github.com/alexchesser/xformers.git`)

- Optionally, update the `TORCH_CUDA_ARCH_LIST` with the string representing your GPU's architecture. See below for a non-exhaustive list, or you can look in the xformers [setup.py](https://github.com/facebookresearch/xformers/blob/main/setup.py#L179-L186) file for some hints) 

```json
{
    "name": "xFormers DevContainer",
    "build": {
      "dockerfile": "Dockerfile",
      "args": {
        "XFORMERS_FORK_URL": "https://github.com/<my-github-username>/xformers.git",
        "TORCH_CUDA_ARCH_LIST": "12.0"
      }
    },
    "remoteEnv": {
      "XFORMERS_FORK_URL": "https://github.com/<my-github-username>/xformers.git"
    }
  }
```

4) Open in Dev Container
- Open this folder in VS Code, then choose “Reopen in Container”. 
- Note that this step will run a one time `post-create.sh` shell script where the wait time is expected to be around 30 minutes.  Subsequent re-opens will not incur this cost unless you recreate the container.  It is the nature of devcontainers that says you can't get aroud this bit (I've tried, I only made it slower!).

5) Validate
```bash
# Inside the container
nvidia-smi
python -c "import torch; print('CUDA:', torch.cuda.is_available(), torch.cuda.get_device_name(0))"
python3 attention_test.py  # Expect shape torch.Size([2, 4, 8]) and device 'cuda:0'
```

You’re now inside a GPU-ready `xformers` dev environment.

## Configuration

- `XFORMERS_FORK_URL` (required): Your fork of `xformers`.
- `TORCH_CUDA_ARCH_LIST` (optional, default `12.0`): Target GPU architectures. Examples: `8.6` (Ampere, RTX 30xx), `8.9` (Ada, RTX 40xx), `12.0` (Blackwell, RTX 50xx).
- `XFORMERS_FIRST_BUILD_URL` (maintainers): Upstream repo used to seed caches in builder images.
- `BUILDKIT_INLINE_CACHE` (maintainers): Enables cache provenance for downstream reuse.

Example `.devcontainer/devcontainer.local.json` with architecture override:

```json
{
    "name": "xFormers DevContainer",
    "build": {
      "dockerfile": "Dockerfile",
      "args": {
        "XFORMERS_FORK_URL": "https://github.com/<my-github-username>/xformers.git",
        "TORCH_CUDA_ARCH_LIST": "12.0"
      }
    },
    "remoteEnv": {
      "XFORMERS_FORK_URL": "https://github.com/<my-github-username>/xformers.git"
    }
  }
```

Supported architecture values (non-exhaustive):

| Arch number | Name                    | Notes               |
| ----------- | ----------------------- | ------------------- |
| `5.2`       | Maxwell (GTX 9xx)       | Old                 |
| `6.1`       | Pascal (GTX 10xx)       |                     |
| `7.0`       | Volta (V100)            |                     |
| `7.5`       | Turing (RTX 20xx)       |                     |
| `8.0`       | Ampere (A100)           | Datacenter          |
| `8.6`       | Ampere (RTX 30xx)       | Common gaming cards |
| `8.9`       | Ada Lovelace (RTX 40xx) | Recent              |
| `9.0`       | Hopper (H100)           | Datacenter          |
| `12.0`      | Blackwell (RTX 50xx)    | Default here        |

Note: The Dev Containers build GUI may not expose GPUs during the build step; specifying `TORCH_CUDA_ARCH_LIST` ensures binaries are compiled for your target without discovery at build time.

## Validate the environment

If `attention_test.py` runs successfully, you should see output with shape `torch.Size([2, 4, 8])` and a device like `cuda:0`. Tensor values will vary.

Additional quick checks:
```bash
python -c "import xformers, torch; print('xformers ok; CUDA:', torch.cuda.is_available())"
```

## How it works (short)

- Dockerfile: `nvidia/cuda:12.8.0-devel-ubuntu22.04`, sets `TORCH_CUDA_ARCH_LIST` (default `12.0`) and `FORCE_CUDA=1`, installs Python toolchain and `torch/torchvision/torchaudio/triton`.
- Post-create: clones `XFORMERS_FORK_URL` with submodules and runs a single editable install (`pip install -e`).

For the full design, see `/.devcontext/research/02-architectural-research.md`.

## Expected build time

Based on recent benchmarking of the baseline flow, end-to-end first setup typically completes in about 27 minutes on a modern workstation. Subsequent opens are faster since only the editable workspace is refreshed.

## Vision

The `xformers-devcontainer` exists to make contributing effortless, consistent, and fast. We aim to remove friction at every step so you can focus on what matters: _building_.

* **Instant Momentum:** Launch into productive work in minutes with dramatically reduced startup and build times.
* **Zero Guesswork:** Eliminate the "it works on my machine" problem with a consistent environment for every contributor.
* **Effortless Onboarding:** A near "one-click" path for new and external contributors to start building immediately.
* **Future-Proof Foundation:** An environment designed to evolve gracefully, making change safe and sustainable.

**Our North Star:** A frictionless workspace that turns "setup" into "ship it."

