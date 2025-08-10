#!/bin/bash

# This script runs Scenario B: Optimized (First-time user / Docker Hub Download)

set -e # Exit immediately if a command exits with a non-zero status.

# --- Preparation: Clean Environment ---
echo "--- Cleaning the environment for Scenario B ---"
rm -rf xformers-devcontainer
docker image rm -f $(docker images -q alexchesser/xformers-devcontainer:latest) || true

# Create the output directory if it doesn't exist
mkdir -p benchmarks

# --- Execute Benchmark Steps ---
echo "--- Running Scenario B Benchmark ---"
# Step 1: Clone the repository
(time git clone https://github.com/AlexChesser/xformers-devcontainer.git) 2>> benchmarks/scenario_b_git_clone.txt

cd xformers-devcontainer

# Replace the placeholder in the local devcontainer configuration
echo "Updating devcontainer configuration with correct GitHub username..."
sed -i '' -e 's/<my-github-username>/alexchesser/g' .devcontainer/devcontainer.local.json

# Step 2: Build and run the devcontainer using the cached image from Docker Hub
(time devcontainer up --workspace-folder .) 2>> ../benchmarks/scenario_b_container_up.txt

# Step 3: Run the benchmark script inside the container
(time devcontainer exec --workspace-folder . python3 attention_test.py) 2>> ../benchmarks/scenario_b_run_test.txt

echo "--- Scenario B benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..
