# xFormers DevContainer

This directory contains the configuration files for a Visual Studio Code DevContainer. The purpose of this setup is to provide a pre-configured and reproducible development environment for working on the `xFormers` project.

-----

## Workflow Rationale: Fast Development with Pre-built Components

This development environment is designed to give you the best of both worlds: fast startup times and an efficient development workflow. It achieves this through a two-step installation process and smart caching.

**Why This Approach:**

We want to avoid long build times every time you start the container or make code changes. To solve this, we do most of the heavy lifting *beforehand* and then quickly link your local code into the container.

**The Two-Step Process:**

1. **Pre-installation:** During the initial container build, we install all the major dependencies (PyTorch, Triton, and a complete version of `xFormers`). **This includes installing several sub-repositories (composable_kernel_tiled, cutlass, flash-attention) and their dependencies. This pre-installation step is critical as it handles a significant amount of compilation and setup, saving considerable time later.** Think of this as preparing all the ingredients, including some complex recipes.
2. **Editable Install:** Once the container is running, we "connect" your local `xFormers` code. This is done using `pip install -e .`, which creates a link between your local files and the environment inside the container. This step is essential to ensure your code changes are immediately reflected inside the container.

Because we've already pre-installed almost everything in step 1, this second step is very fast in relative terms.

**How Caching Makes it Faster:**

To further speed up the initial container build, we use a caching strategy. The container reuses pre-built components from a remote image, so it doesn't have to download and install everything from scratch every time. This significantly reduces the initial build time.

**In Summary:**

The two-step installation, combined with caching, allows us to create a development environment that is both fast to start and responsive to your code changes. You get the benefit of pre-compiled components without sacrificing the ability to instantly see the results of your work.

-----

## Getting Started

1. **Clone the repository:**
    ```bash

    git clone --recurse-submodules https://github.com/alexchesser/xformers-devcontainer.git
    cd xformers-devcontainer
    ```

2. **Open in VS Code:**
* Open the `xformers-devcontainer` folder in Visual Studio Code.
* VS Code will prompt you to "Reopen in Container." Click this to start the build process.

### For Contributors: Working with Your Own Fork (Optional)

If you are a contributor working on your own fork of `xformers`, you have two primary options.

#### Option A: Use the Cached Build (Recommended)

**This is the fastest approach.** As long as your fork is based on a recent merge from the upstream `facebookresearch/xformers` repository and you haven't made significant changes to the C++ or CUDA kernel code, you don't need to rebuild the image from your fork.

In this case, you would **leave the `XFORMERS_FIRST_BUILD_URL` fields unchanged** in your local `.devcontainer.json` file. The container will build instantly from the cached layers, and the `post-create.sh` script will correctly link your local fork's code.

#### Option B: Rebuild from Your Fork

You should only choose this option if your fork has diverged significantly from the upstream repository or if you have made changes to the C++ or CUDA kernel code that require recompilation.

1. **Open `.devcontainer.json`:** Open the file located in the `.devcontainer` folder.

2. **Update both URL fields:** Change the URL in both the `build` and `remoteEnv` sections to your fork's URL.

   ```json

  {
   "name": "xFormers DevContainer",
   "build": {
       "dockerfile": "Dockerfile",
       "args": {
         "GPU": "true",
         "XFORMERS_FIRST_BUILD_URL": "https://github.com/your-username/xformers.git"
       }
     },
     "remoteEnv": {
       "XFORMERS_FORK_URL": "https://github.com/your-username/xformers.git"
     },
     // ... (rest of your configuration)
   }

   ```json


3. **Rebuild the Container:** After making this change, you will be prompted to "Rebuild and Reopen in Container." This will cause a **cache miss** on the build step for `xformers`, forcing a full rebuild from your fork. While this is slower, it is a necessary one-time step to ensure your base image is correctly configured for your development.

Yes, that's an excellent approach. You're thinking about a continuous integration strategy, which is the perfect way to maintain a fresh, cached image for a team. Updating the README with instructions for this workflow is a great idea.

-----

### Manual Build and Push for Caching

You can and should build the `Dockerfile` and push the resulting image to Docker Hub to maintain the cache. This is a manual process that you or a team lead would perform periodically (e.g., weekly or whenever a major dependency is updated).

Here's a simple set of commands you could include in the README:

1.  **Build the image locally:** This command builds the image and tags it with your Docker Hub repository name and a specific tag, like `latest`. Replace `your_dockerhub_repo` with your actual repository.

    ```bash
    docker build -t your_dockerhub_repo/xformers-devcontainer:latest .
    ```

2.  **Push the image to Docker Hub:** This command uploads the locally built image to your repository, making its layers available for others to use via the `cacheFrom` instruction.

    ```bash
    docker push your_dockerhub_repo/xformers-devcontainer:latest
    ```

-----

### Automated Nightly Builds

For a more robust solution, a **nightly build** is ideal for teams. This would involve a CI/CD platform (like GitHub Actions) that automatically builds and pushes a new image to Docker Hub every night. This ensures that the cached image is always up-to-date with the latest dependencies and security patches.

You could have a GitHub Actions workflow that:

  * Triggers on a schedule (e.g., every day at 1:00 AM).
  * Checks out the repository.
  * Runs the `docker buildx build --push` command to build and push the new image.

This fully automates the process and guarantees that your team always has a fast-starting devcontainer.


```
docker buildx build \
  --cache-from alexchesser/xformers-devcontainer:latest \
  --tag alexchesser/xformer \
  s-devcontainer:latest \
  -f .devcontainer/Dockerfile .
```


for `TORCH_CUDA_ARCH_LIST` this will skip the driver check in the VSCODE build process.
the vscode devcontainer build process does not support `GPUs --all` so in order to enable compilaiton for your RTX card, you need to update the dockerfile to support your architecture.

will work on a fix for this later - in the meantime I just want to get this working for my 5060.  Does anyone actually develop on an H100?! 

| Arch number | Name                    | Notes               |
| ----------- | ----------------------- | ------------------- |
| `5.2`       | Maxwell (GTX 9xx)       | Old                 |
| `6.1`       | Pascal (GTX 10xx)       |                     |
| `7.0`       | Volta (V100)            |                     |
| `7.5`       | Turing (RTX 20xx)       |                     |
| `8.0`       | Ampere (A100)           | datacenter          |
| `8.6`       | Ampere (RTX 30xx)       | common gaming cards |
| `8.9`       | Ada Lovelace (RTX 40xx) | recent              |
| `9.0`       | Hopper (H100)           | datacenter          |
| `12.0`      | Blackwell  (RTX 50xx)   |                     |
