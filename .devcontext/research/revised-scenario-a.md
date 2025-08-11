### Revised Scenario A Benchmark Plan

This plan proposes a rigorous, cache-free baseline for Scenario A that compiles `xformers` exactly once, avoids any prebuilt wheels or builder images, and reflects a fair “new developer, fresh machine” experience while remaining practical for day-to-day work.

## Why revise Scenario A
- Builders and cache layers have evolved; the original script may now pull in optimizations that bias the baseline.
- Current flow can cause duplicate compilation (Dockerfile seeds prebuilt wheel, then post-create installs in editable mode again).
- We want a single, honest compile without relying on prebuilt caches or COPY-from builder images.

## Goals and ground rules
- No remote cache hints: remove `image` and `cacheFrom` in the devcontainer configuration for Scenario A.
- No COPY-from builder images; do not reference `xformers-dependency-downloader` or `xformers-builder`.
- No `pip download`/wheel prefetch stages; install dependencies directly from package indexes.
- Compile `xformers` exactly once.
- Keep the developer workflow natural (devcontainer up -> environment ready for development).

## Approaches considered

- Option 1: All-in-Dockerfile (clone + install -e at build time)
  - Pros: Single-step during image build; post-create becomes a no-op.
  - Cons: Devcontainer mounts the workspace on top of container paths at runtime; cloning into a mount path in the Dockerfile is overwritten. Cloning elsewhere (e.g., `/opt/xformers-src`) complicates the editing workflow and can cause a mismatch between compiled artifacts and workspace sources.
  - Verdict: Not recommended for a typical devcontainer workflow.

- Option 2: Minimal Dockerfile + post-create does the single compile (recommended)
  - Dockerfile: Base CUDA image + system build tools + Python + PyTorch (cu128) + Triton. No caching, no prebuilt wheels.
  - Post-create: Clone fork into the workspace with `--recurse-submodules` and perform one editable install (`-e`) with `FORCE_CUDA=1`.
  - Pros: Mirrors real contributor experience; compile happens exactly once in a place users will work (workspace). Easy to parameterize fork URL and username.
  - Cons: Longer `devcontainer up` time is expected by design for baseline.

- Option 3: Dockerfile builds a non-editable wheel; post-create flips to editable
  - Duplicates work and undermines the “compile once” constraint.
  - Verdict: Not recommended.

## Recommended design

1) Add a minimal Scenario A Dockerfile (no caches, no builder images)
- Path: `.devcontainer/Dockerfile.scenario-a`
- Key elements:
  - Base: `nvidia/cuda:12.8.0-devel-ubuntu22.04`
  - Install: `python3-pip python3-dev build-essential git cmake ninja-build rsync`
  - pip: upgrade `pip`, then install runtime/build deps directly (no wheel cache):
    - `torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128`
    - `triton`
  - Create `vscode` user, set `WORKDIR /workspace`, add `ENTRYPOINT` to keep container alive if needed.
  - Do NOT clone `xformers` or install it here to avoid duplication and mount issues.

2) Add a Scenario A post-create script that compiles once
- Path: `.devcontainer/post-create-scenario-a.sh`
- Behavior:
  - Prompt for GitHub username (default to `alexchesser`), derive `XFORMERS_FORK_URL`.
  - Clone fork into `${PWD}/xformers` with `--recurse-submodules`.
  - Mark submodules as git safe directories.
  - Compile/install once in editable mode:
    - `FORCE_CUDA=1 TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-12.0} pip install --no-build-isolation --no-deps -e xformers`
  - Install `pre-commit` and run `pre-commit install` in the repo.

3) Update `benchmarking/scenario_a.sh`
- Create a dedicated scenario directory (e.g., `xformers-devcontainer-scenario-a`), do NOT delete the base repo folder.
- Remove local images that could shortcut the build (devcontainer image and any builder/downloader images).
- Copy `devcontainer.json` into the scenario directory and modify for Scenario A:
  - Remove `image` and `cacheFrom` properties.
  - Set `build.dockerfile` to `.devcontainer/Dockerfile.scenario-a`.
  - Set `postCreateCommand` to `.devcontainer/post-create-scenario-a.sh`.
- Prefer timestamped logs and echo commands before running (align with Scenario B/C).
- If Dev Container CLI supports it, build with no cache (e.g., `devcontainer build --no-cache`), otherwise rely on image removals.

## Example snippets (illustrative)

- Dockerfile (Scenario A minimal)
```Dockerfile
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    FORCE_CUDA=1

RUN apt-get update && apt-get install -y \
    python3-pip python3-dev build-essential git cmake ninja-build rsync \
  && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --upgrade pip \
  && python3 -m pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    triton

RUN useradd -ms /bin/bash vscode
WORKDIR /workspace
ENTRYPOINT ["tail","-f","/dev/null"]
```

- Post-create (Scenario A compile-once)
```bash
#!/bin/bash
set -e

XFORMERS_USERNAME=""
read -p "Enter your GitHub username for the xformers fork [default: alexchesser]: " XFORMERS_USERNAME
XFORMERS_USERNAME=${XFORMERS_USERNAME:-alexchesser}
XFORMERS_FORK_URL="https://github.com/${XFORMERS_USERNAME}/xformers.git"

XFORMERS_PATH="${PWD}/xformers"
git clone --recurse-submodules "${XFORMERS_FORK_URL}" "${XFORMERS_PATH}"

git config --global --add safe.directory "${XFORMERS_PATH}"
git -C "${XFORMERS_PATH}" submodule foreach --recursive 'git config --global --add safe.directory "$sm_path" || true'

python3 -m pip install --no-cache-dir pre-commit
FORCE_CUDA=1 TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-12.0} \
  python3 -m pip install --no-build-isolation --no-deps -e "${XFORMERS_PATH}"

pushd "${XFORMERS_PATH}" >/dev/null
pre-commit install
popd >/dev/null
```

- `scenario_a.sh` high-level changes
```bash
# Use xformers-devcontainer-scenario-a dir; echo commands; timestamped logs
# Remove local images: devcontainer, xformers-dependency-downloader, xformers-builder
# Copy and edit devcontainer.json to point to Dockerfile.scenario-a and post-create-scenario-a.sh
# Run: (time devcontainer up --workspace-folder .) and then attention_test.py
```

## Fairness considerations
- Network effects: Torch/Triton wheel downloads reflect real-world first-time cost; acceptable for baseline.
- Docker layer cache: Prefer no-cache builds where possible; otherwise remove local images to reduce reuse.
- Single compilation: Only `pip install -e` once in post-create.
- GPU access: Not required for build/compile; CUDA toolkit in the base image suffices. Runtime test (`attention_test.py`) should use `--gpus all` per devcontainer runArgs.

## Risks and mitigations
- Long runtime: Baseline will be slow by design; document expectations and keep logs timestamped.
- Toolchain gaps: Ensure `cmake` and `ninja-build` are present to avoid C++/CUDA build issues.
- Workspace overlay: Avoid cloning in Dockerfile to prevent mount conflicts; do it in post-create.

## Acceptance criteria
- Scenario A runs with no references to builder/downloader images or caches.
- Exactly one `xformers` compilation occurs.
- Benchmark logs are captured with timestamps and commands echoed.
- `attention_test.py` runs successfully inside the container.


