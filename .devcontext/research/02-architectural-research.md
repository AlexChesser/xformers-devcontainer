### xformers-devcontainer: Architectural Research

This document summarizes the repository’s architecture with emphasis on the builders and devcontainer workflow. It catalogs the tools, frameworks, and design patterns used, and explains how they compose a fast, reproducible GPU-enabled development environment for `xformers`.

## Scope and Goals
- **Primary goal**: Provide a pre-configured VS Code Dev Container that accelerates onboarding and iterative development for `xformers`, with CUDA/GPU support.
- **Key strategy**: Pre-build and cache heavyweight GPU/ML dependencies and a prebuilt `xformers` wheel, then assemble a minimal, fast final dev image that links a user’s fork in editable mode.

## Key Components

- **Devcontainer configuration**
  - File: `.devcontainer/devcontainer.json`
  - Builds the final image from `.devcontainer/Dockerfile`
  - Passes build args: `BUILDKIT_INLINE_CACHE`, `XFORMERS_FIRST_BUILD_URL`, `XFORMERS_FORK_URL`, `TORCH_CUDA_ARCH_LIST`
  - Uses remote cache: `cacheFrom: ["alexchesser/xformers-devcontainer:latest"]`
  - Features: `ghcr.io/devcontainers/features/docker-in-docker:2.1.0` with GPU support
  - Runtime: `runArgs: ["--gpus", "all"]`
  - Post create: `postCreateCommand: ./.devcontainer/post-create.sh`
  - Editor extensions: Python, Pylance, Jupyter, ESLint

- **Final dev image**
  - File: `.devcontainer/Dockerfile`
  - Base: `nvidia/cuda:12.8.0-devel-ubuntu22.04`
  - Environment: `TORCH_CUDA_ARCH_LIST` (default `12.0`), `FORCE_CUDA=1`
  - Copies pre-downloaded wheels and prebuilt `xformers` artifacts from remote builder images:
    - `COPY --from=alexchesser/xformers-dependency-downloader /tmp/wheels /tmp/wheels`
    - `COPY --from=alexchesser/xformers-builder /opt/wheels /opt/wheels`
    - `COPY --from=alexchesser/xformers-builder /opt/xformers-src /opt/xformers-src`
    - `COPY --from=alexchesser/xformers-builder /opt/xformers-wheels /opt/xformers-wheels`
  - Installs Python dev tools and dependencies strictly from local wheel caches (`--find-links`) to avoid network fetches
  - Adds minimal tools like `rsync`, creates `vscode` user, sets `WORKDIR /workspace`, idle `ENTRYPOINT`

- **Post-create bootstrap**
  - File: `.devcontainer/post-create.sh`
  - Clones user’s fork into `/workspace/xformers` using `XFORMERS_FORK_URL`
  - Marks submodules as safe directories and reuses cached submodules via `rsync` from `/opt/xformers-src/third_party`
  - Installs prebuilt `xformers` wheel, then performs an editable install (`pip install -e .`) for fast iteration
  - Installs `pre-commit` hooks

- **Builder images (cache priming)**
  - Directory: `builders/`
  - Script: `builders/build_and_push.sh` builds and pushes either:
    - `alexchesser/xformers-dependency-downloader` from `builders/Dockerfile.downloader`
    - `alexchesser/xformers-builder` from `builders/Dockerfile.xformers-builder`
  - `builders/Dockerfile.downloader`:
    - Base: `nvidia/cuda:12.8.0-devel-ubuntu22.04`
    - Downloads wheels for PyTorch (`torch`, `torchvision`, `torchaudio`) pinned to CUDA 12.8 index, `triton`, and a suite of `nvidia-*-cu12` libraries, plus common deps, into `/tmp/wheels`
  - `builders/Dockerfile.xformers-builder`:
    - Base: `nvidia/cuda:12.8.0-devel-ubuntu22.04`
    - Copies wheel cache from a prior image (`COPY --from=alexchesser/xformers-dependency-downloader /tmp/wheels /tmp/wheels`)
    - Clones `xformers` (arg: `XFORMERS_FIRST_BUILD_URL`, default upstream), initializes submodules
    - Installs from cached wheels and builds a wheel into `/opt/xformers-wheels` (also mirrored to `/opt/wheels`)

- **Benchmarking helpers**
  - Directory: `benchmarking/`
  - `benchmarking-plan.md` with three scenarios: Baseline (no cache), Optimized (Docker Hub), Optimized (local cache)
  - Shell scripts `scenario_a.sh`, `scenario_b.sh`, `scenario_c.sh` demonstrating end-to-end startup timing using Dev Container CLI

- **Sanity test**
  - `attention_test.py` validates GPU-enabled `xformers.ops.memory_efficient_attention`

## Tools and Frameworks

- **Containerization and GPU**
  - Docker, BuildKit/Buildx, multi-stage builds
  - NVIDIA CUDA base images (`12.8.0-devel-ubuntu22.04`)
  - VS Code Dev Containers + Dev Container CLI
  - `docker-in-docker` feature with GPU enablement

- **ML/Compute stack**
  - PyTorch (`torch`, `torchvision`, `torchaudio`) via CUDA 12.8 wheels
  - Triton
  - NVIDIA CUDA/cuDNN/cuBLAS/NCCL and related `cu12` libraries
  - `xformers` from Git (upstream or fork), editable install for dev

- **Developer tooling**
  - Python toolchain: `pip`, `pre-commit`, `black`, `flake8`, `isort`
  - System build tools: `build-essential`, `cmake`, `git`, `rsync`
  - Editor extensions: Python, Pylance, Jupyter, ESLint
  - Shell/CLI: `devcontainer` CLI, `time`, `sed`, Docker CLI

## Workflow Overview

1) Build and publish cache images (rarely)
- Use `builders/build_and_push.sh` to build and push:
  - `xformers-dependency-downloader`: caches heavyweight wheels for CUDA/PyTorch/Triton
  - `xformers-builder`: clones and builds a prebuilt `xformers` wheel; also ships cached source and third-party submodules
- Result: Stable, reusable layers hosted in a registry to be consumed by downstream builds.

2) Build the devcontainer image (often via VS Code)
- `.devcontainer/devcontainer.json` builds `.devcontainer/Dockerfile` and uses `cacheFrom` to leverage `alexchesser/xformers-devcontainer:latest` plus `COPY --from` to pull artifacts directly from `xformers-dependency-downloader` and `xformers-builder`.
- The Dockerfile installs dependencies strictly from local wheel caches for speed and reproducibility, then creates a minimal dev runtime.

3) First-run project bootstrap (post-create)
- `post-create.sh` clones the user’s fork (`XFORMERS_FORK_URL`), links submodules from cached source, installs the prebuilt wheel, then switches to an editable install to enable rapid code iteration without recompiling CUDA extensions unless necessary.

4) Day-to-day development
- Open in VS Code, GPU available via `--gpus all` and docker-in-docker feature.
- Edit code in the forked `xformers` repo; Python sees it via editable install.
- Optionally run `attention_test.py` to validate environment and GPU.

## Design Patterns

- **Multi-stage build and cache priming**
  - Split heavy, low-churn steps (PyTorch/CUDA wheels) from project-specific build (xformers wheel), then assemble a lightweight dev image consuming those layers.
  - Remote-cache pattern via `cacheFrom` and `COPY --from` ensures teams and CI can reuse prebuilt artifacts.

- **Editable install with prebuilt wheel seed**
  - Install prebuilt `xformers` wheel first to provide compiled CUDA/C++ artifacts, then `pip install -e .` to make local changes instant without full rebuilds.

- **Devcontainer feature composition**
  - Combine `docker-in-docker` feature and `--gpus all` run args to expose host GPUs to the dev environment.

- **Configuration via build args and remote env**
  - `XFORMERS_FIRST_BUILD_URL` (upstream) for the initial heavy build; `XFORMERS_FORK_URL` (user fork) for the editable workspace.
  - `TORCH_CUDA_ARCH_LIST` used to preconfigure CUDA arch compatibility and skip runtime GPU detection.

- **Benchmark-driven validation**
  - Scripts and plan files to quantify time savings across baseline, first-time optimized, and local-cache scenarios.

## Notable Considerations and Nuances

- **CUDA architecture targeting**
  - Default `TORCH_CUDA_ARCH_LIST` is `12.0` (Blackwell RTX 50xx). Support for additional architectures can be added; future work aims at providing selectable, pre-optimized images per GPU arch.

- **Image size and host requirements**
  - Prebuilt layers are large (documented ~10.79GB for an image in notes). Intended for machines with sufficient disk, RAM, and GPU resources.

- **Security and Git config**
  - `post-create.sh` adds `safe.directory` entries for `xformers` and its third-party submodules to prevent Git ownership warnings.

- **Reproducibility**
  - Prefer `--find-links` installations from curated wheel caches; avoids transient upstream index changes, increases determinism.

## Future Enhancements (as hinted in repo docs)

- Nightly CI builds to refresh cached images and keep security patches current.
- Published image variants per `TORCH_CUDA_ARCH_LIST` for broader GPU coverage.
- Additional automation around submodule syncing and validation.

## Quick Map of Relevant Files

- Devcontainer: `.devcontainer/devcontainer.json`, `.devcontainer/Dockerfile`, `.devcontainer/post-create.sh`
- Builders: `builders/Dockerfile.downloader`, `builders/Dockerfile.xformers-builder`, `builders/build_and_push.sh`, `builders/readme.md`
- Benchmarks: `benchmarking/benchmarking-plan.md`, `benchmarking/scenario_a.sh`, `benchmarking/scenario_b.sh`, `benchmarking/scenario_c.sh`
- Validation: `attention_test.py`
