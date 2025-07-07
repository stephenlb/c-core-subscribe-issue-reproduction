# Dockerfile for PubNub C-Core FreeRTOS/mbedTLS Build Environment
FROM alpine:latest

# Set working directory
WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    cmake \
    git \
    wget \
    curl \
    tar \
    linux-headers \
    mbedtls-dev \
    mbedtls-static

# Copy the project files
COPY . .

# Create build script for FreeRTOS/mbedTLS
RUN echo '#!/bin/sh\n\
set -e\n\
echo "=== Building PubNub C-Core with FreeRTOS/mbedTLS ==="\n\
cd /app\n\
\n\
# Check if pubnub-c-core exists, if not download it\n\
if [ ! -d "pubnub-c-core" ]; then\n\
    echo "Downloading PubNub C-Core v5.1.1..."\n\
    wget -q https://github.com/pubnub/c-core/archive/refs/tags/v5.1.1.tar.gz\n\
    tar -xzf v5.1.1.tar.gz\n\
    mv c-core-5.1.1 pubnub-c-core\n\
    rm v5.1.1.tar.gz\n\
fi\n\
\n\
# Copy the FreeRTOS reproduction program\n\
if [ -f "pubnub_subscribe_bug_reproduction_freertos.c" ]; then\n\
    cp pubnub_subscribe_bug_reproduction_freertos.c pubnub-c-core/core/samples/\n\
fi\n\
\n\
cd pubnub-c-core\n\
\n\
# Use POSIX build with mbedTLS as a simulation of FreeRTOS/mbedTLS\n\
cd posix\n\
\n\
# Build basic library first\n\
make -f posix.mk clean\n\
make -f posix.mk pubnub_sync_sample\n\
\n\
# Compile the FreeRTOS reproduction program with mbedTLS flags\n\
if [ -f "../core/samples/pubnub_subscribe_bug_reproduction_freertos.c" ]; then\n\
    echo "Compiling FreeRTOS reproduction program with mbedTLS..."\n\
    gcc -o pubnub_subscribe_bug_reproduction_freertos \\\n\
        -I.. -I. -I../lib/base64 -I../posix -I../core \\\n\
        -DPUBNUB_CRYPTO_API=0 \\\n\
        -DPUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE \\\n\
        -DPUBNUB_ONLY_PUBSUB_API=0 \\\n\
        -DPUBNUB_PROXY_API=1 \\\n\
        -DPUBNUB_RECEIVE_GZIP_RESPONSE=1 \\\n\
        -DPUBNUB_THREADSAFE=1 \\\n\
        -DPUBNUB_USE_ACTIONS_API=1 \\\n\
        -DPUBNUB_USE_ADVANCED_HISTORY=1 \\\n\
        -DPUBNUB_USE_AUTO_HEARTBEAT=1 \\\n\
        -DPUBNUB_USE_FETCH_HISTORY=1 \\\n\
        -DPUBNUB_USE_GRANT_TOKEN_API=0 \\\n\
        -DPUBNUB_USE_GZIP_COMPRESSION=1 \\\n\
        -DPUBNUB_USE_IPV6=0 \\\n\
        -DPUBNUB_USE_OBJECTS_API=1 \\\n\
        -DPUBNUB_USE_RETRY_CONFIGURATION=0 \\\n\
        -DPUBNUB_USE_REVOKE_TOKEN_API=0 \\\n\
        -DPUBNUB_USE_SSL=1 \\\n\
        -DPUBNUB_BLOCKING_IO_SETTABLE=0 \\\n\
        -DPUBNUB_USE_SUBSCRIBE_EVENT_ENGINE=0 \\\n\
        -DPUBNUB_USE_SUBSCRIBE_V2=1 \\\n\
        -DPUBNUB_USE_LOG_CALLBACK=0 \\\n\
        -DFREERTOS_SIMULATION=1 \\\n\
        ../core/samples/pubnub_subscribe_bug_reproduction_freertos.c \\\n\
        pubnub_sync.a -lmbedtls -lmbedx509 -lmbedcrypto -lpthread\n\
    echo "✓ FreeRTOS reproduction program compiled successfully"\n\
fi\n\
\n\
echo "✓ Build completed successfully"\n\
' > /app/build_freertos_mbedtls.sh

# Make the build script executable
RUN chmod +x /app/build_freertos_mbedtls.sh

# Default command
CMD ["/app/build_freertos_mbedtls.sh"]