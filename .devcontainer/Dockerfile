FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/root/.local/bin:$PATH"

# Force CUDA arch list to skip GPU detection
ENV TORCH_CUDA_ARCH_LIST="12.0"
ENV FORCE_CUDA=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip python3-dev git && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip \
    # Dev tools
    && python3 -m pip install --no-cache-dir \
        numpy \
        black \
        flake8 \
        isort \
        pre-commit \
    # PyTorch + CUDA
    && python3 -m pip install --no-cache-dir \
        torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 \
    # Triton
    && python3 -m pip install --no-cache-dir triton

# Build xFormers without GPU detection
ARG XFORMERS_FIRST_BUILD_URL="https://github.com/facebookresearch/xformers.git"
WORKDIR /tmp/xformers
RUN git clone $XFORMERS_FIRST_BUILD_URL . \ 
    && git submodule update --init --recursive \
    && python3 -m pip install --no-cache-dir . \
    && rm -rf /tmp/xformers

# Create vscode user
RUN useradd -ms /bin/bash vscode
USER vscode
WORKDIR /workspace