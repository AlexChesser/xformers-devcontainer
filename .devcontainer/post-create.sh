#!/bin/bash
set -e # Exit on error

# Get the base path of the workspace dynamically. This ensures the script works
# regardless of the name a user gives to the cloned repository folder.
# The `PWD` variable holds the current working directory, and we use it to
# construct the path to the `xformers` submodule.
XFORMERS_PATH="${PWD}/xformers"

# Ensure that git is aware of the safe directories for submodules.
# This prevents errors in newer versions of Git related to repository ownership.
# We use the dynamic path to ensure this works for any folder name.
git config --global --add safe.directory "$XFORMERS_PATH"
git config --global --add safe.directory "${XFORMERS_PATH}/third_party/composable_kernel_tiled"
git config --global --add safe.directory "${XFORMERS_PATH}/third_party/cutlass"
git config --global --add safe.directory "${XFORMERS_PATH}/third_party/flash-attention"

# Update submodules for the local repository. This is an essential step
# to ensure all nested submodules are correctly cloned and configured.
echo "Updating submodules for the local xformers repository..."
cd "$XFORMERS_PATH"
git submodule update --init --recursive
cd ..

# -----------------------------------------------------------------------------------
# Automated Fork Setup
# If the XFORMERS_FORK_URL environment variable is set, automatically update
# the submodule's remote URL. This is intended for contributors working on their own fork.
# -----------------------------------------------------------------------------------
if [ -n "$XFORMERS_FORK_URL" ]; then
    echo "Updating xformers submodule remote to $XFORMERS_FORK_URL"
    git submodule set-url -- xformers "$XFORMERS_FORK_URL"
fi
# -----------------------------------------------------------------------------------


echo "Installing xformers in editable mode..."
# This command is necessary to link the local source code into the
# container's Python environment. This step is inescapable for a working
# development setup. However, because we already installed xformers in the
# Dockerfile, this command will be extremely fast (in relative terms),
# as it primarily registers the project in editable mode and skips the
# time-consuming compilation of C++/CUDA kernels.
# Set environment variables for a CUDA-enabled editable install
FORCE_CUDA=1 \
python3 -m pip install -e "$XFORMERS_PATH"

echo "Installing pre-commit hooks for xformers..."
# Change into the xformers submodule directory
cd "$XFORMERS_PATH"
# Run the pre-commit install command
pre-commit install
# Change back to the parent directory
cd -

# The rest of the setup is handled by the Dockerfile, so we just need to ensure the environment is correct.
echo "Post-create setup completed successfully."