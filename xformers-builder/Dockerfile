# --- STAGE 1: The Builder Stage ---
# This image will be built and pushed separately to a container registry.
# Its purpose is to pre-download large dependencies that can be reused as a
# build cache by other contributors and in CI/CD pipelines.
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Use noninteractive frontend for package installation.
ENV DEBIAN_FRONTEND=noninteractive

# Install core Python and development tools in a single layer to optimize caching.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Set a working directory for downloading packages.
WORKDIR /tmp/downloads

# Use pip download to fetch the wheel files for PyTorch and Triton.
# This creates a single layer with these large dependencies, making the cache
# for this layer highly stable. Any changes to these dependencies would
# invalidate this layer and require a new download.
RUN python3 -m pip install --no-cache-dir \
    --target /tmp/wheels \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    && python3 -m pip install --no-cache-dir --target /tmp/wheels triton