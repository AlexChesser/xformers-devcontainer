# xformers Dev Container

Pre-configured Visual Studio Code Dev Container for developing against `xformers` with GPU acceleration. It uses prebuilt and cached layers to make onboarding fast and reproducible.

## What is this?

This repository provides a GPU-ready, reproducible development environment for the `xformers` project. It assembles a minimal final dev image from prebuilt layers (PyTorch/CUDA wheels and an `xformers` wheel) and then links your fork in editable mode for rapid iteration.

See the deeper architectural overview in `/.devcontext/research/02-architectural-research.md`.

## Prerequisites

- Docker with Buildx enabled
- VS Code + Dev Containers extension (or Cursor)
- NVIDIA GPU with drivers installed and NVIDIA Container Toolkit configured for Docker
- Windows 11 with WSL2, or a Linux host (macOS works for CPU-only, but GPU passthrough is not supported)
- Sufficient disk space: ~50 GB for base images and caches

Tip for Windows: ensure Docker Desktop has WSL2 integration enabled and that `nvidia-smi` works on the host first.

## Quick start

1) Fork the upstream repository
- Go to `https://github.com/facebookresearch/xformers` and create your fork.

2) Clone this devcontainer repo
```bash
git clone --recursive https://github.com/AlexChesser/xformers-devcontainer.git
cd xformers-devcontainer
```

3) Point the devcontainer at your fork
- Create or edit `.devcontainer/devcontainer.local.json` and set your fork URL:

```json
{
  "build": {
    "args": {
      "XFORMERS_FORK_URL": "https://github.com/<your-github-username>/xformers.git"
    }
  }
}
```

4) Open in Dev Container
- Open this folder in VS Code, then choose “Reopen in Container”.

5) Validate
```bash
# Inside the container
nvidia-smi
python -c "import torch; print('CUDA:', torch.cuda.is_available(), torch.cuda.get_device_name(0))"
python3 attention_test.py  # Expect shape torch.Size([2, 4, 8]) and device 'cuda:0'
```

You’re now inside a GPU-ready, prebuilt `xformers` dev environment. Most contributors will never need to run the heavy builder images locally.

## Configuration

- `XFORMERS_FORK_URL` (required): Your fork of `xformers`.
- `TORCH_CUDA_ARCH_LIST` (optional, default `12.0`): Target GPU architectures. Examples: `8.6` (Ampere, RTX 30xx), `8.9` (Ada, RTX 40xx), `12.0` (Blackwell, RTX 50xx).
- `XFORMERS_FIRST_BUILD_URL` (maintainers): Upstream repo used to seed caches in builder images.
- `BUILDKIT_INLINE_CACHE` (maintainers): Enables cache provenance for downstream reuse.

Example `.devcontainer/devcontainer.local.json` with architecture override:

```json
{
  "build": {
    "args": {
      "XFORMERS_FORK_URL": "https://github.com/<your-github-username>/xformers.git",
      "TORCH_CUDA_ARCH_LIST": "8.9"
    }
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

- Multi-stage builder images pre-download CUDA/PyTorch wheels and build an `xformers` wheel.
- The final devcontainer image copies those artifacts and installs from local wheel caches for speed and determinism.
- On first run, your fork is cloned and installed in editable mode for fast iteration.

For the full design, see `/.devcontext/research/02-architectural-research.md`.

## Troubleshooting

- GPU not visible in container
  - Ensure Docker is configured with the NVIDIA Container Toolkit and that `nvidia-smi` works on the host.
  - Confirm your devcontainer has `--gpus all` run args (set in `.devcontainer/devcontainer.json`).

- Install hits the network unexpectedly
  - The image is intended to install from local wheel caches via `--find-links`. If you see network fetches, cache layers may be missing; reopen to rebuild or update the base image.

- Git safe.directory warnings
  - The post-create step marks repositories as safe. If needed, re-run `.devcontainer/post-create.sh` inside the container.

- Slow builds
  - Verify remote cache usage is configured (e.g., `cacheFrom: ["alexchesser/xformers-devcontainer:latest"]`). Ensure Buildx is enabled.

## Benchmarks

See `benchmarking/benchmarking-plan.md` and the scripts in `benchmarking/` for end-to-end startup timing across baseline and cached scenarios.

## Roadmap / future enhancements

- Automated nightly builds to keep cached images fresh. Example command used by CI:

```bash
docker buildx build \
  --cache-from=alexchesser/xformers-devcontainer:latest \
  --tag alexchesser/xformers-devcontainer:latest \
  -f .devcontainer/Dockerfile .
```

- Published variants per `TORCH_CUDA_ARCH_LIST` to cover a range of GPU architectures.

## Vision

The `xformers-devcontainer` exists to make contributing effortless, consistent, and fast. We aim to remove friction at every step so you can focus on what matters: _building_.

* **Instant Momentum:** Launch into productive work in minutes with dramatically reduced startup and build times.
* **Zero Guesswork:** Eliminate the "it works on my machine" problem with a consistent environment for every contributor.
* **Effortless Onboarding:** A near "one-click" path for new and external contributors to start building immediately.
* **Future-Proof Foundation:** An environment designed to evolve gracefully, making change safe and sustainable.

**Our North Star:** A frictionless workspace that turns "setup" into "ship it."

