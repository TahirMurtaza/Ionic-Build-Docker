# Use an official Node.js runtime as a base image
FROM node:20-alpine

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install Ionic CLI globally
RUN npm install -g @ionic/cli@7

# Install dependencies using clean install
RUN npm ci --only=prod

# Expose the port the app runs on
EXPOSE 8100

# Install OpenJDK and Android SDK dependencies
RUN apk add --no-cache openjdk8-jre wget unzip

# Set up environment variables
ENV ANDROID_HOME /opt/android-sdk
ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Download and extract Android SDK tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -O /tmp/sdk-tools.zip && \
    unzip -q /tmp/sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm /tmp/sdk-tools.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

# Accept Android SDK licenses
RUN mkdir -p ${ANDROID_HOME}/licenses && \
    echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > ${ANDROID_HOME}/licenses/android-sdk-license

# Install required Android SDK packages
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses && \
    ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platforms;android-30" "build-tools;30.0.3"

# Copy the entire project to the working directory
COPY . .

# Build APK in debug mode with detailed logging
RUN ionic cordova build android --debug || exit 1

# List files in the project directory for inspection
RUN ls -la

# Verify the directory structure for Android builds
RUN ls -la platforms/android/app

# Verify if APK file was generated
RUN if [ ! -d "platforms/android/app/build" ]; then echo "Error: Build directory not found"; exit 1; fi

# List files in the build directory for inspection
RUN ls -la platforms/android/app/build

# Copy APK to a directory
RUN mkdir -p /app/apk
RUN cp platforms/android/app/build/outputs/apk/debug/app-debug.apk /app/apk/app-debug.apk