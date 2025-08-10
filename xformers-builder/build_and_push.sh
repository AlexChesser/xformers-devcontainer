#!/bin/bash

# Define the image name and tag
IMAGE_NAME="alexchesser/xformers-builder"
IMAGE_TAG="latest"

# Build the image using the Dockerfile.builder file.
# The --platform flag ensures it's built for your specific architecture.
# The --tag flag applies the correct tag to the built image.
echo "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
docker buildx build \
    --platform linux/amd64 \
    --tag "${IMAGE_NAME}:${IMAGE_TAG}" \
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
