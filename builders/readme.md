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