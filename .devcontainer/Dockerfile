# --- STAGE 3: The Final Development Container ---
# This is the final image. It copies the pre-built wheels from the two builder
# stages and installs them, which is a much faster operation than downloading
# or compiling from scratch.
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Use noninteractive frontend for package installation.
ENV DEBIAN_FRONTEND=noninteractive

# Force CUDA arch list to skip GPU detection
ARG TORCH_CUDA_ARCH_LIST="12.0"
ENV TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}
ENV FORCE_CUDA=1

# Install core Python and development tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3-pip \
        python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy cached PyTorch deps from Stage 1 and xformers wheel from Stage 2
COPY --from=alexchesser/xformers-downloader /tmp/wheels /tmp/wheels
COPY --from=alexchesser/xformers-builder /opt/wheels /opt/wheels
COPY --from=alexchesser/xformers-builder /opt/xformers-src /opt/xformers-src
COPY --from=alexchesser/xformers-builder /opt/xformers-wheels /opt/xformers-wheels

# I'm unclear on whether these are still required, but I'd love to get back to "actually working" before I try deleting again
COPY --from=alexchesser/xformers-builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=alexchesser/xformers-builder /usr/local/bin /usr/local/bin

# Upgrade pip and install all dependencies from local cache ONLY (no fallback),
# using the pre-downloaded wheels for max speed.
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir \
        --prefer-binary \
        --find-links /tmp/wheels \
        numpy black flake8 isort pre-commit \
        torch \
        torchvision \
        torchaudio \
        triton \
    && python3 -m pip install --no-cache-dir \
        --prefer-binary \
        --find-links /opt/wheels \
        /opt/wheels/*.whl \
    && rm -rf /tmp/wheels /opt/wheels

# Create vscode user (devcontainer.json handles remoteUser switch)
RUN useradd -ms /bin/bash vscode

# Set the final working directory for the user.
WORKDIR /workspace

# Set the entrypoint to keep the container running for development.
ENTRYPOINT [ "tail", "-f", "/dev/null" ]