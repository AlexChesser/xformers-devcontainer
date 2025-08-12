#!/bin/bash

# This script runs Scenario A: Baseline (No Caching)
# Best-practice aligned with scenario_b.sh: timestamped outputs, echo commands,
# dedicated working directory, and minimal impact outside the scenario directory.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Preparation: Clean Environment ---
echo "--- Cleaning the environment for Scenario A (Baseline, No Caching) ---"

# Use a dedicated directory for Scenario A to avoid touching any base repo folder
SCENARIO_DIR="xformers-devcontainer-scenario-a"
echo "Removing previous scenario directory if present: ${SCENARIO_DIR}"
rm -rf "${SCENARIO_DIR}" || true

# Remove local cached images that could influence the baseline
echo "Removing local cached image alexchesser/xformers-devcontainer:latest if present"
docker image rm -f $(docker images -q alexchesser/xformers-devcontainer:latest) || true
echo "Removing local cached image alexchesser/xformers-dependency-downloader:latest if present"
docker image rm -f $(docker images -q alexchesser/xformers-dependency-downloader:latest) || true
echo "Removing local cached image alexchesser/xformers-builder:latest if present"
docker image rm -f $(docker images -q alexchesser/xformers-builder:latest) || true

# Create the output directory if it doesn't exist
mkdir -p benchmarks

# Generate a timestamp for this run
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Starting benchmark run at: ${TIMESTAMP}"

# --- Execute Benchmark Steps ---
echo "--- Running Scenario A Benchmark ---"

# Step 1: Clone the repository into the scenario directory
echo "(time git clone https://github.com/AlexChesser/xformers-devcontainer.git ${SCENARIO_DIR})"
{ time git clone https://github.com/AlexChesser/xformers-devcontainer.git "${SCENARIO_DIR}"; }

cd "${SCENARIO_DIR}"

# Apply Scenario A files: Dockerfile, devcontainer.local.json, and post-create
echo "Applying Scenario A Dockerfile"
cp benchmarking/scenario_a/Dockerfile.scenario-a .devcontainer/Dockerfile

echo "Applying Scenario A devcontainer.local override"
cp benchmarking/scenario_a/devcontainer.local.scenario-a.json .devcontainer/devcontainer.local.json

echo "Applying Scenario A post-create script"
# Copy to the exact path referenced by devcontainer.local.scenario-a.json to avoid prompts/mismatch
cp benchmarking/scenario_a/post-create-scenario-a.sh .devcontainer/post-create-scenario-a.sh

# Step 2: Build and run the devcontainer from scratch
echo "(time devcontainer up --workspace-folder . --log-level trace)"
{ time devcontainer up --workspace-folder . --log-level trace; }

# Step 3: Run the benchmark script inside the container
echo "(time devcontainer exec --workspace-folder . python3 attention_test.py)"
{ time devcontainer exec --workspace-folder . python3 attention_test.py; }

echo "--- Scenario A benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..