#!/bin/bash

# Usage: benchmarking/scenario_runner.sh benchmarking/scenario_c.sh
# Captures full logs (stdout+stderr) into a single timestamped file and
# measures total elapsed time, including container build and post-create.

set -euo pipefail

SCENARIO_SCRIPT_PATH="${1:-}"
if [[ -z "${SCENARIO_SCRIPT_PATH}" ]]; then
  echo "Usage: $0 <path-to-scenario-script>" >&2
  exit 1
fi

if [[ ! -f "${SCENARIO_SCRIPT_PATH}" ]]; then
  echo "Scenario script not found: ${SCENARIO_SCRIPT_PATH}" >&2
  exit 1
fi

mkdir -p benchmarks
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCENARIO_NAME=$(basename "${SCENARIO_SCRIPT_PATH}" .sh)
LOG_FILE="benchmarks/${TIMESTAMP}_${SCENARIO_NAME}.log"

# Redirect all output (stdout and stderr) to tee so we persist a full transcript
exec > >(tee -a "${LOG_FILE}") 2>&1

echo "--- Scenario Runner ---"
echo "Scenario: ${SCENARIO_SCRIPT_PATH}"
echo "Log file: ${LOG_FILE}"
echo "Start: $(date -Is)"

START_TIME=$(date +%s)

# Run scenario script
bash "${SCENARIO_SCRIPT_PATH}"

END_TIME=$(date +%s)
ELAPSED=$(( END_TIME - START_TIME ))

echo "End: $(date -Is)"
echo "Total elapsed seconds: ${ELAPSED}"


