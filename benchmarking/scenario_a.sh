#!/bin/bash

# This script runs Scenario A: Baseline (No Caching)
# It temporarily modifies devcontainer.json to disable the image cache.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Preparation: Clean Environment ---
echo "--- Cleaning the environment for Scenario A ---"
rm -rf xformers-devcontainer
docker image rm -f $(docker images -q alexchesser/xformers-devcontainer:latest) || true

# Create the output directory if it doesn't exist
mkdir -p benchmarks

# --- Execute Benchmark Steps ---
echo "--- Running Scenario A Benchmark ---"
# Step 1: Clone the repository
(time git clone https://github.com/AlexChesser/xformers-devcontainer.git) 2>> benchmarks/scenario_a_git_clone.txt

cd xformers-devcontainer

# Prompt user for GitHub username and update the devcontainer configuration
read -p "Enter your GitHub username for the xformers fork: " github_username
echo "Updating devcontainer configuration with username: $github_username"
sed -i '' -e "s/<my-github-username>/$github_username/g" .devcontainer/devcontainer.local.json

# Modify devcontainer.json to remove the image and cacheFrom properties
echo "Disabling devcontainer image cache for baseline test..."
sed -i '' -e '/"image":/d' devcontainer.json
sed -i '' -e '/"cacheFrom":/d' devcontainer.json

# Step 2: Build and run the devcontainer from scratch
(time devcontainer up --workspace-folder .) 2>> ../benchmarks/scenario_a_container_up.txt

# Step 3: Run the benchmark script inside the container
(time devcontainer exec --workspace-folder . python3 attention_test.py) 2>> ../benchmarks/scenario_a_run_test.txt

# Restore the original devcontainer.json after the benchmark is complete
echo "Restoring original devcontainer.json..."
git checkout devcontainer.json

echo "--- Scenario A benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..