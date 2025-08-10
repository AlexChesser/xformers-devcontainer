#!/bin/bash

# This script runs Scenario C: Optimized (Second project / Local Cache)
# It assumes a cached Docker image is already available from a prior test.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Preparation: Clean Environment ---
echo "--- Cleaning the environment for Scenario C ---"
rm -rf xformers-devcontainer
rm -rf xformers-new-branch # Ensure the specific directory is clean

# Create the output directory if it doesn't exist
mkdir -p benchmarks

# --- Execute Benchmark Steps ---
echo "--- Running Scenario C Benchmark ---"
# Step 1: Clone the repository into a new directory
echo \(time git clone https://github.com/AlexChesser/xformers-devcontainer.git xformers-new-branch\) 2>> benchmarks/scenario_c_git_clone.txt
(time git clone https://github.com/AlexChesser/xformers-devcontainer.git xformers-new-branch) 2>> benchmarks/scenario_c_git_clone.txt

cd xformers-new-branch

# Prompt user for GitHub username and update the devcontainer configuration
read -p "Enter your GitHub username for the xformers fork: " github_username
echo "Updating devcontainer configuration with username: $github_username"
echo sed -i -e "s/<my-github-username>/$github_username/g" .devcontainer/devcontainer.local.json
sed -i -e "s/<my-github-username>/$github_username/g" .devcontainer/devcontainer.local.json

# Step 2: Build and run the devcontainer using the locally cached image
echo \(time devcontainer up --workspace-folder .\) 2>> ../benchmarks/scenario_c_container_up.txt
(time devcontainer up --workspace-folder .) 2>> ../benchmarks/scenario_c_container_up.txt

# Step 3: Run the benchmark script inside the container
echo \(time devcontainer exec --workspace-folder . python3 attention_test.py\) 2>> ../benchmarks/scenario_c_run_test.txt
(time devcontainer exec --workspace-folder . python3 attention_test.py) 2>> ../benchmarks/scenario_c_run_test.txt

echo "--- Scenario C benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..