#!/bin/bash

# This script builds and pushes a specified Docker image to a container registry.
# Usage: ./build_and_push.sh [pytorch|xformers]

set -e # Exit immediately if a command exits with a non-zero status.

# Define image names and Dockerfiles
DOWNLOADER_IMAGE_NAME="alexchesser/xformers-dependency-downloader"
DOWNLOADER_DOCKERFILE="Dockerfile.downloader"
XFORMERS_IMAGE_NAME="alexchesser/xformers-builder"
XFORMERS_DOCKERFILE="Dockerfile.xformers-builder"

# Validate command line argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 [downloader|xformers]"
    exit 1
fi

case "$1" in
    "downloader")
        IMAGE_NAME="${DOWNLOADER_IMAGE_NAME}"
        DOCKERFILE="${DOWNLOADER_DOCKERFILE}"
        ;;
    "xformers")
        IMAGE_NAME="${XFORMERS_IMAGE_NAME}"
        DOCKERFILE="${XFORMERS_DOCKERFILE}"
        ;;
    *)
        echo "Invalid argument: '$1'"
        echo "Usage: $0 [pytorch|xformers]"
        exit 1
        ;;
esac

IMAGE_TAG="latest"

# Build the image.
echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG} using ${DOCKERFILE}"
docker buildx build \
    --platform linux/amd64 \
    --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
    -f "${DOCKERFILE}" \
    .

# Check if the build was successful
if [ $? -ne 0 ]; then
    echo "Docker build failed. Exiting."
    exit 1
fi

# Log in to Docker Hub
echo "Logging in to Docker Hub..."
docker login

# Check if login was successful
if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting."
    exit 1
fi

# Push the image to Docker Hub
echo "Pushing Docker image: ${IMAGE_NAME}:${IMAGE_TAG} to Docker Hub"
docker push "${IMAGE_NAME}:${IMAGE_TAG}"

# Check if push was successful
if [ $? -ne 0 ]; then
    echo "Docker push failed. Exiting."
    exit 1
fi

echo "Successfully built and pushed ${IMAGE_NAME}:${IMAGE_TAG}"
