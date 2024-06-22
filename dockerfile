# Use an OpenJDK base image with Java 17 for amd64 architecture
FROM amd64/openjdk:17-slim

# Install Node.js and npm
RUN apt-get update && \
    apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs wget unzip && \
    apt-get clean

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install Ionic, Cordova, and Cordova resources CLI globally
RUN npm install -g @ionic/cli@7 cordova

# Expose the port the app runs on
EXPOSE 8100

# Set up environment variables for Java and Android SDK
ENV JAVA_HOME=/usr/local/openjdk-17
ENV PATH=${JAVA_HOME}/bin:${PATH}

# Set up environment variables for Android SDK
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/platform-tools

# Download and extract Android SDK tools
RUN mkdir -p ${ANDROID_HOME}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -O /tmp/sdk-tools.zip && \
    unzip -q /tmp/sdk-tools.zip -d ${ANDROID_HOME}/cmdline-tools && \
    rm /tmp/sdk-tools.zip && \
    mv ${ANDROID_HOME}/cmdline-tools/cmdline-tools ${ANDROID_HOME}/cmdline-tools/latest

# Accept Android SDK licenses
RUN mkdir -p ${ANDROID_HOME}/licenses && \
    echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > ${ANDROID_HOME}/licenses/android-sdk-license

# Update and install required Android SDK packages
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --update
RUN yes | ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager --licenses
RUN ${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-33" "build-tools;34.0.0"

# Download and install Gradle
RUN wget https://services.gradle.org/distributions/gradle-7.3.3-bin.zip -O /tmp/gradle.zip && \
    unzip -d /opt/gradle /tmp/gradle.zip && \
    rm /tmp/gradle.zip

ENV GRADLE_HOME=/opt/gradle/gradle-7.3.3
ENV PATH=${PATH}:${GRADLE_HOME}/bin

# Clear Gradle cache to avoid corrupted dependencies
RUN rm -rf /root/.gradle/caches

# Copy the entire project to the working directory
COPY . .

RUN npm install

# Build web assets for the Ionic project
RUN npm run build

# Initialize and add Android platform using Cordova
RUN ionic integrations enable cordova
RUN ionic cordova platform add android

# Set environment variable to bypass the AAPT2 issue
ENV ANDROID_DISABLE_DAEMON=true

# Increase JVM memory limits
ENV GRADLE_OPTS="-Dorg.gradle.daemon=false -Xmx4096m"

# Build the Cordova Android project
RUN cordova build android --debug --verbose


# Set the default command to start the Ionic app
CMD ["ionic", "serve", "--host", "0.0.0.0"]
