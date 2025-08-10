# --- STAGE 3: The Final Development Container ---
# This is the final image. It copies the pre-built wheels from the two builder
# stages and installs them, which is a much faster operation than downloading
# or compiling from scratch.
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Use noninteractive frontend for package installation.
ENV DEBIAN_FRONTEND=noninteractive

# Install core Python and development tools.
RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the pre-built wheels from the builder stages.
COPY --from=alexchesser/pytorch-builder /tmp/wheels /tmp/wheels
COPY --from=alexchesser/xformers-builder /usr/local/lib/python3.10/dist-packages /usr/local/lib/python3.10/dist-packages
COPY --from=alexchesser/xformers-builder /usr/local/bin /usr/local/bin

# Install all the packages from the local cache. The git clone and compilation
# steps are no longer needed here.
RUN python3 -m pip install --no-cache-dir --upgrade pip \
    && python3 -m pip install --no-cache-dir \
        --find-links /tmp/wheels \
        numpy black flake8 isort pre-commit \
        torch \
        torchvision \
        torchaudio \
        triton \
    && rm -rf /tmp/wheels

# Create vscode user without switching to it. The remoteUser property in devcontainer.json will handle the switch.
RUN useradd -ms /bin/bash vscode

# Set the final working directory for the user.
WORKDIR /workspace

# Set the entrypoint to keep the container running for development.
ENTRYPOINT [ "tail", "-f", "/dev/null" ]
