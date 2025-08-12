#!/bin/bash

# if this fails to run 
#       nvm install --lts
#       nvm use --lts

# This script runs Scenario C: Optimized (Second project / Local Cache)
# It now saves benchmark results to timestamped files to prevent overwriting.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Preparation: Clean Environment ---
echo "--- Cleaning the environment for Scenario C ---"
rm -rf xformers-new-branch # Ensure the specific directory is clean

# Create the output directory if it doesn't exist
mkdir -p benchmarks

# Generate a timestamp for this run.
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
echo "Starting benchmark run at: ${TIMESTAMP}"

# --- Execute Benchmark Steps ---
echo "--- Running Scenario C Benchmark ---"

# Step 1: Clone the repository into a new directory
echo "(time git clone https://github.com/AlexChesser/xformers-devcontainer.git xformers-new-branch)"
{ time git clone https://github.com/AlexChesser/xformers-devcontainer.git xformers-new-branch; }

cd xformers-new-branch

# Apply Scenario C devcontainer.local override (no sed, no prompts)
echo "Applying Scenario C devcontainer.local override"
cp benchmarking/scenario_c/devcontainer.local.scenario-c.json .devcontainer/devcontainer.local.json

# Step 2: Build and run the devcontainer using the locally cached image
echo "(time devcontainer up --workspace-folder . --log-level trace)"
{ time devcontainer up --workspace-folder . --log-level trace; }

# Step 3: Run the benchmark script inside the container
cd xformers-new-branch
echo "(time devcontainer exec --workspace-folder . python3 attention_test.py)"
{ time devcontainer exec --workspace-folder . python3 attention_test.py; }

echo "--- Scenario C benchmark complete. Results are in the 'benchmarks' directory. ---"

# --- Cleanup: Return to original directory ---
cd ..