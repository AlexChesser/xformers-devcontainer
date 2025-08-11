#!/bin/bash
set -e

XFORMERS_USERNAME=""
read -p "Enter your GitHub username for the xformers fork [default: alexchesser]: " XFORMERS_USERNAME
XFORMERS_USERNAME=${XFORMERS_USERNAME:-alexchesser}
XFORMERS_FORK_URL="https://github.com/${XFORMERS_USERNAME}/xformers.git"

XFORMERS_PATH="${PWD}/xformers"
echo "Cloning fork: ${XFORMERS_FORK_URL} -> ${XFORMERS_PATH}"
echo "(time git clone --recurse-submodules \"${XFORMERS_FORK_URL}\" \"${XFORMERS_PATH}\")"
{ time git clone --recurse-submodules "${XFORMERS_FORK_URL}" "${XFORMERS_PATH}"; }

echo "Marking git safe directories"
git config --global --add safe.directory "${XFORMERS_PATH}"
git -C "${XFORMERS_PATH}" submodule foreach --recursive 'git config --global --add safe.directory "$sm_path" || true'

echo "Installing xformers in editable mode (single compile)"
echo "(time FORCE_CUDA=1 TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-12.0} python3 -m pip install --no-build-isolation --no-deps -e \"${XFORMERS_PATH}\")"
{ time FORCE_CUDA=1 TORCH_CUDA_ARCH_LIST=${TORCH_CUDA_ARCH_LIST:-12.0} \
  python3 -m pip install --no-build-isolation --no-deps -e "${XFORMERS_PATH}"; }

echo "Installing pre-commit and enabling hooks"
echo "(time python3 -m pip install --no-cache-dir pre-commit)"
{ time python3 -m pip install --no-cache-dir pre-commit; }
pushd "${XFORMERS_PATH}" >/dev/null
pre-commit install
popd >/dev/null

echo "Post-create (Scenario A) completed successfully."


