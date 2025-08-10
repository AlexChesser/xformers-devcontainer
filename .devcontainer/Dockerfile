# --- STAGE 2: Final Image Stage ---
# This is the final image that will be used. It's built on a clean base.
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Set environment variables from the original Dockerfile
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:$PATH"
ENV TORCH_CUDA_ARCH_LIST="12.0"
ENV FORCE_CUDA=1

# Install base packages for Python and Git in a single RUN command to optimize layers.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip python3-dev git && \
    rm -rf /var/lib/apt/lists/*

# Copy the downloaded wheel files from the 'builder' stage.
# This happens instantly because the files are already on the local Docker host.
COPY --from=alexchesser/xformers-builder:latest /tmp/wheels/ /tmp/wheels/

# Install the Python packages from the locally cached wheel files and then immediately clean up.
# This crucial step ensures the temporary wheel files do not remain in the final image's layer.
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir numpy black flake8 isort pre-commit \
    && python3 -m pip install --no-cache-dir /tmp/wheels/* \
    && rm -rf /tmp/wheels

# Build xFormers without GPU detection
ARG XFORMERS_FIRST_BUILD_URL="https://github.com/facebookresearch/xformers.git"
WORKDIR /tmp/xformers
RUN git clone $XFORMERS_FIRST_BUILD_URL . \
    && git submodule update --init --recursive \
    && python3 -m pip install --no-cache-dir . \
    && rm -rf /tmp/xformers

# Create vscode user without switching to it. The remoteUser property in devcontainer.json will handle the switch.
RUN useradd -ms /bin/bash vscode

WORKDIR /workspace