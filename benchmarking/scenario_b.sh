#!/bin/bash

# This script runs Scenario B: Optimized (First-time user / Docker Hub Download)
# Best-practice aligned with scenario_c.sh: timestamped outputs, echo commands,
# dedicated working directory, and no deletion of the base repo.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Preparation: Clean Environment ---
echo "--- Cleaning the environment for Scenario B ---"

# Use a dedicated directory for Scenario B to avoid touching any base repo folder
SCENARIO_DIR="xformers-devcontainer-scenario-b"
echo "Removing previous scenario directory if present: ${SCENARIO_DIR}"
rm -rf "${SCENARIO_DIR}" || true

# Force pulling the images from Docker Hub by removing any local copies
echo "Removing local cached image alexchesser/xformers-devcontainer:latest if present"
docker image rm -f $(docker images -q alexchesser/xformers-devcontainer:latest) || true
echo "Removing local cached image alexchesser/xformers-dependency-downloader:latest if present"
docker image rm -f $(docker images -q alexchesser/xformers-dependency-downloader:latest) || true
echo "Removing local cached image alexchesser/xformers-builder:latest if present"
docker image rm -f $(docker images -q alexchesser/xformers-builder:latest) || true

# Create the output directory if it doesn't exist
mkdir -p benchmarks

# Generate a timestamp for this run.
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Starting benchmark run at: ${TIMESTAMP}"

# --- Execute Benchmark Steps ---
echo "--- Running Scenario B Benchmark ---"

# Step 1: Clone the repository into the scenario directory
echo "(time git clone https://github.com/AlexChesser/xformers-devcontainer.git ${SCENARIO_DIR}) 2>> benchmarks/${TIMESTAMP}_scenario_b_01_git_clone.txt"
{ time git clone https://github.com/AlexChesser/xformers-devcontainer.git "${SCENARIO_DIR}"; } 2>> "benchmarks/${TIMESTAMP}_scenario_b_01_git_clone.txt"

cd "${SCENARIO_DIR}"

# Apply Scenario B devcontainer.local override (no sed, no prompts)
echo "Applying Scenario B devcontainer.local override"
cp benchmarking/scenario_b/devcontainer.local.scenario-b.json .devcontainer/devcontainer.local.json

# Step 2: Build and run the devcontainer using the cached image from Docker Hub
echo "(time devcontainer up --workspace-folder .) 2>> ../benchmarks/${TIMESTAMP}_scenario_b_02_container_up.txt"
{ time devcontainer up --workspace-folder .; } 2>> "../benchmarks/${TIMESTAMP}_scenario_b_02_container_up.txt"

# Step 3: Run the benchmark script inside the container
echo "(time devcontainer exec --workspace-folder . python3 attention_test.py) 2>> ../benchmarks/${TIMESTAMP}_scenario_b_03_run_test.txt"
{ time devcontainer exec --workspace-folder . python3 attention_test.py; } 2>> "../benchmarks/${TIMESTAMP}_scenario_b_03_run_test.txt"

echo "--- Scenario B benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..
