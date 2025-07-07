# Dockerfile for PubNub C-Core Real FreeRTOS/mbedTLS Build Environment
FROM espressif/idf:release-v5.1

# Set working directory
WORKDIR /app

# Install additional dependencies for PubNub C-Core
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Copy the project files
COPY . .

# Copy the build script (created separately to avoid complex escaping)
COPY build_real_freertos.sh /app/build_real_freertos.sh

# Make the build script executable
RUN chmod +x /app/build_real_freertos.sh

# Default command
CMD ["/app/build_real_freertos.sh"]