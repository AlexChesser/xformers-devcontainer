# **Build and Push xformers-builder**

This script is designed to automate the process of building and pushing the xformers-builder Docker image to a container registry.

### **Purpose**

The xformers-builder image acts as a **build cache** for the xformers project. It contains pre-downloaded dependencies, such as PyTorch and Triton, which are often large and time-consuming to download.

By building and pushing this image to a registry, you create a remote cache that can be used by other team members and in CI/CD pipelines. This significantly speeds up subsequent builds by allowing Docker to reuse the cached layers instead of re-downloading everything.

When measured against the full build time, this download step alone represented approximately 30% of the total duration (471.4 seconds out of 1565.8 seconds). Since these dependencies are large and rarely change, isolating them in a dedicated, stable layer significantly improves the efficiency and speed of the build workflow.

### **Prerequisites**

* **Docker:** You must have Docker installed and running on your system.  
* **Docker Hub Account:** You need a Docker Hub account and to be logged in via the command line.

### **Usage**

1. Place this script (build\_and\_push.sh) in the same directory as your Dockerfile.  
2. Make the script executable by running chmod \+x build\_and\_push.sh.  
3. Execute the script from your terminal: ./build\_and\_push.sh.

The script will automatically prompt you to log in to Docker Hub if you haven't already. It will then build the image, tag it as alexchesser/xformers-builder:latest, and push it to the registry.

## Runtime Summaries

### xformers-builder

The key timing you're saving here is the compilation time of `2764.0s` or roughly 45 minutes. Timing based on execution on a `Processor	AMD Ryzen 7 5800X 8-Core Processor, 3801 Mhz, 8 Core(s), 16 Logical Processor(s)` on Windows 11 Pro WSL with 64 GB RAM. 
The resulting artifact is `10.79GB` so be warned. I suppose that if you are woking on training LLMs you're on a beefy machine. This probably isn't suitable for a typical laptop. 

```bash
[+] Building 2918.0s (11/11) FINISHED                                                  docker:default 
 => [internal] load build definition from Dockerfile.xformers-builder                            0.0s 
 => => transferring dockerfile: 1.03kB                                                           0.0s 
 => [internal] load metadata for docker.io/alexchesser/pytorch-builder:latest                    0.0s 
 => [internal] load metadata for docker.io/nvidia/cuda:12.8.0-devel-ubuntu22.04                  0.0s 
 => [internal] load .dockerignore                                                                0.0s 
 => => transferring context: 2B                                                                  0.0s 
 => CACHED [xformers-builder 1/5] FROM docker.io/nvidia/cuda:12.8.0-devel-ubuntu22.04            0.0s 
 => CACHED FROM docker.io/alexchesser/pytorch-builder:latest                                     0.0s
 => [xformers-builder 2/5] RUN apt-get update     && apt-get install -y         python3-dev     23.8s
 => [xformers-builder 3/5] COPY --from=alexchesser/pytorch-builder /tmp/wheels /tmp/wheels      84.8s
 => [xformers-builder 4/5] WORKDIR /tmp/xformers                                                 0.4s
 => [xformers-builder 5/5] RUN git clone https://github.com/facebookresearch/xformers.git .   2764.0s
 => exporting to image                                                                          44.4s
 => => exporting layers                                                                         44.2s
 => => writing image sha256:bb7df5c5cfb9a6f0c743ff1d8c4c722a379a3fe9255bd005b98aee3adbf450ef     0.0s
 => => naming to docker.io/alexchesser/xformers-builder:latest                                   0.0s
```
