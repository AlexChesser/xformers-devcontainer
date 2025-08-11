#!/bin/bash
set -e # Exit on error

# Get the base path of the workspace dynamically. This ensures the script works
# regardless of the name a user gives to the cloned repository folder.
# The `PWD` variable holds the current working directory, and we use it to
# construct the path to the `xformers` source directory.
XFORMERS_PATH="${PWD}/xformers"

echo "Cloning xformers fork from $XFORMERS_FORK_URL..."
# Clone without submodules — we will reuse pre-cloned submodules from cache
echo "(time git clone \"$XFORMERS_FORK_URL\" \"$XFORMERS_PATH\")"
{ time git clone "$XFORMERS_FORK_URL" "$XFORMERS_PATH"; }

# Ensure that git is aware of the safe directories for submodules.
# This prevents errors in newer versions of Git related to repository ownership.
# We use the dynamic path to ensure this works for any folder name.
git config --global --add safe.directory "$XFORMERS_PATH"
git config --global --add safe.directory "${XFORMERS_PATH}/third_party/composable_kernel_tiled"
git config --global --add safe.directory "${XFORMERS_PATH}/third_party/cutlass"
git config --global --add safe.directory "${XFORMERS_PATH}/third_party/flash-attention"

# Link cached submodules into the cloned repo to avoid re-downloading large deps.
# The builder stage provides /opt/xformers-src with fully fetched submodules.
echo "Linking submodules from cached source..."
echo "(time rsync -a /opt/xformers-src/third_party/ \"$XFORMERS_PATH/third_party/\")"
{ time rsync -a /opt/xformers-src/third_party/ "$XFORMERS_PATH/third_party/"; }

# Install prebuilt wheel first (this contains compiled CUDA/C++ extensions).
# This makes the following editable install a fast metadata update only.
echo "Installing prebuilt xformers wheel..."
echo "(time python3 -m pip install --no-cache-dir /opt/xformers-wheels/xformers-*.whl)"
{ time python3 -m pip install --no-cache-dir /opt/xformers-wheels/xformers-*.whl; }

echo "Installing xformers in editable mode..."
# This command links the local source code into the container's Python environment
# without rebuilding binaries. This is essential for development but now extremely fast.
echo "(time FORCE_CUDA=1 python3 -m pip install --no-build-isolation --no-deps -e \"$XFORMERS_PATH\")"
{ time FORCE_CUDA=1 \
python3 -m pip install --no-build-isolation --no-deps -e "$XFORMERS_PATH"; }

echo "Installing pre-commit hooks for xformers..."
# Change into the xformers directory
cd "$XFORMERS_PATH"
# Run the pre-commit install command
pre-commit install
# Change back to the parent directory
cd -

# The rest of the setup is handled by the Dockerfile, so we just need to ensure the environment is correct.
echo "Post-create setup completed successfully."