#!/bin/bash

# This script runs Scenario A: Baseline (No Caching)
# Uses scenario-specific files and avoids prebuilt caches.

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
{ time git clone https://github.com/AlexChesser/xformers-devcontainer.git; } 2>> benchmarks/scenario_a_git_clone.txt

cd xformers-devcontainer

# Apply Scenario A files: Dockerfile, devcontainer.local.json, and post-create
echo "Applying Scenario A Dockerfile"
cp benchmarking/scenario_a/Dockerfile.scenario-a .devcontainer/Dockerfile

echo "Applying Scenario A devcontainer.local override"
cp benchmarking/scenario_a/devcontainer.local.scenario-a.json .devcontainer/devcontainer.local.json

echo "Applying Scenario A post-create script"
cp benchmarking/scenario_a/post-create-scenario-a.sh .devcontainer/post-create.sh

# Step 2: Build and run the devcontainer from scratch
{ time devcontainer up --workspace-folder .; } 2>> ../benchmarks/scenario_a_container_up.txt

# Step 3: Run the benchmark script inside the container
{ time devcontainer exec --workspace-folder . python3 attention_test.py; } 2>> ../benchmarks/scenario_a_run_test.txt

# No restoration needed; scenario A edits are in working tree only

echo "--- Scenario A benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..