# xFormers DevContainer

This directory contains the configuration files for a Visual Studio Code DevContainer. The purpose of this setup is to provide a pre-configured and reproducible development environment for working on the `xFormers` project.

-----

## Quick Start

Follow these steps to get up and running with a pre-built `xFormers` development container using cached layers from Docker Hub.

1. **Fork the official repo**
   Go to [facebookresearch/xformers](https://github.com/facebookresearch/xformers) and create a fork in your own GitHub account.

1. **Clone this devcontainer repo**

   ```bash
   git clone --recursive https://github.com/AlexChesser/xformers-devcontainer.git
   cd xformers-devcontainer
   ```

1. Override the `xFormers` source repo

   modify: `.devcontainer\devcontainer.local.json`

    ```json
    {
      "name": "My GPU Devcontainer",
      "build": 
      {
        "args":
        {
          "XFORMERS_FORK_URL": "https://github.com/<my-github-username>/xformers.git"
        }
      }
    }
    ```

1. **(Future enhancement)** Specify your GPU architecture

   * As of this moment this only supports **Blackwell RTX** (50xx series) cards, with broader coverage coming later. Please reach out if you would like support.
   * Planned: `TORCH_CUDA_ARCH_LIST` will allow selecting a pre-built container optimized for your GPU (e.g. `8.6` for Ampere cards).

1. **Open in VS Code (or Cursor)**

   * Open this folder in VS Code.
   * When prompted, choose **"Reopen in Container"**.
   * Alternatively, open the command pallette and type **"Reopen in Container"**.

1. **Wait for expedited re-linking**
   The container will quickly link your fork of `xFormers` into an editable state.
   Trust me, you're still saving at least a half an hour or more on this.

1. **Validate success**
   within your terminal, execute the command `python3 attention_test.py`

    **expected result:**

    ```bash
    Output shape: torch.Size([2, 4, 8])
    Output tensor: tensor([[[ 2.8512e-01,  2.9201e-01,  8.8733e-01, -1.1101e+00, -5.2147e-01,
              1.1888e-02,  7.4874e-01,  5.9645e-01],
            [ 1.2363e+00, -1.6215e-01, -1.2905e-02, -8.0790e-01,  1.5332e-01,
              6.2791e-01,  8.9705e-01,  7.3038e-01],
            [ 5.7432e-01,  2.8456e-01,  1.4269e-01, -1.0558e+00, -3.7668e-01,
              4.8344e-01,  6.2952e-01,  6.3329e-01],
            [ 2.1043e-01,  2.5813e-01,  5.8684e-01, -3.8768e-01, -7.1655e-01,
              7.4684e-01,  7.7974e-01,  6.6678e-01]],

            [[ 4.2819e-02,  1.7114e-01,  4.0450e-01, -9.3450e-01, -4.9926e-01,
              2.3958e-01,  3.3267e-02, -2.6991e-01],
            [-5.2482e-03,  7.4553e-01,  8.6216e-02, -1.8093e-01, -4.2335e-01,
              -1.2456e-01,  3.4218e-01, -6.8206e-01],
            [-8.0586e-01,  6.5572e-01,  4.6022e-01, -9.4582e-01,  3.8873e-04,
              1.0437e+00, -9.3191e-01, -5.6511e-01],
            [ 3.8173e-01, -3.3154e-01,  5.5937e-01, -1.3190e+00, -7.0505e-01,
              1.3590e-01,  2.3190e-01,  7.3449e-02]]], device='cuda:0')
    vscode@4379dd9714f7:/workspaces/xformers-devcontainer$
    ```

1. **Start developing**
   You’re now inside a GPU-ready, pre-built `xFormers` dev environment.

### Automated Nightly Builds (future enhancement)

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

### enable use selectable list of images built per GPU (future enhancement)
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
