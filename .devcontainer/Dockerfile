FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

ARG TORCH_CUDA_ARCH_LIST="12.0"
ENV DEBIAN_FRONTEND=noninteractive \
    FORCE_CUDA=1 \
    TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST}

RUN apt-get update && apt-get install -y \
    python3-pip python3-dev build-essential git cmake ninja-build rsync \
  && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --no-cache-dir --upgrade pip \
  && python3 -m pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cu128 \
    torch torchvision torchaudio triton \
  && python3 -m pip install --no-cache-dir pre-commit

RUN useradd -ms /bin/bash vscode
WORKDIR /workspace
ENTRYPOINT [ "tail", "-f", "/dev/null" ]