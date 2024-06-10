#!/bin/bash

# Variables
IMAGE_NAME="my-ionic-app"
CONTAINER_NAME="my-ionic-container"
APK_SOURCE_PATH="/app/platforms/android/app/build/outputs/apk/debug/app-debug.apk"
APK_DEST_PATH="./apk/app-debug.apk"

# Build the Docker image
echo "Building Docker image..."
docker build -t $IMAGE_NAME .

# Run the Docker container
echo "Running Docker container..."
docker run -d --name $CONTAINER_NAME $IMAGE_NAME

# Ensure the destination directory exists
echo "Creating destination directory..."
mkdir -p $(dirname $APK_DEST_PATH)

chmod 777 ./apk

# Wait for the build process to complete (adjust the sleep time as needed)
echo "Waiting for the APK build process to complete..."
sleep 60  # Adjust this sleep time based on your build time

# Copy the APK file from the container to the local machine
echo "Copying APK file..."
docker cp $CONTAINER_NAME:$APK_SOURCE_PATH $APK_DEST_PATH

# Stop and remove the Docker container
echo "Stopping and removing Docker container..."
docker stop $CONTAINER_NAME
docker rm $CONTAINER_NAME

echo "APK file copied to $APK_DEST_PATH"
