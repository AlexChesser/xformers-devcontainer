# --- STAGE 2: The Final Dev Container Stage ---
# This stage uses the builder image as a cache and installs the project dependencies.

# Use a specific, lightweight version of the CUDA dev image as the base.
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Set environment variables from the original Dockerfile
ENV DEBIAN_FRONTEND=noninteractive
# this path enables the use of linters and pre-commit hooks for contributions
ENV PATH="/root/.local/bin:$PATH"
ENV TORCH_CUDA_ARCH_LIST="12.0"
ENV FORCE_CUDA=1

# Install core Python and development tools.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip python3-dev git && \
    rm -rf /var/lib/apt/lists/*

# Copy the pre-downloaded wheel files from the builder stage.
# This avoids re-downloading large files like PyTorch and Triton.
COPY --from=alexchesser/xformers-builder:latest /tmp/wheels/ /tmp/wheels/

# Install dependencies, using the local wheels as a source.
# The --find-links flag allows pip to resolve dependencies correctly
# without trying to install two conflicting versions of a single package.
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir \
       --find-links /tmp/wheels \
       numpy black flake8 isort pre-commit \
       torch \
       torchvision \
       torchaudio \
       triton \
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

# Set the final working directory for the user.
WORKDIR /workspace

# Set the entrypoint to keep the container running for development.
ENTRYPOINT [ "tail", "-f", "/dev/null" ]
