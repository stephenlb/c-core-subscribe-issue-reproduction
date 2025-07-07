#!/bin/bash

# PubNub C-Core Subscribe Bug Reproduction Setup Script (FreeRTOS/mbedTLS)
# This script downloads PubNub C-Core and compiles the reproduction case using Docker

set -e  # Exit on any error

echo "=== PubNub C-Core Subscribe Bug Reproduction Setup (FreeRTOS/mbedTLS) ==="
echo

# Check if we have the necessary tools
check_dependencies() {
    echo "Checking dependencies..."
    
    if ! command -v docker &> /dev/null; then
        echo "ERROR: Docker not found. Please install Docker to build with FreeRTOS/mbedTLS."
        echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
        exit 1
    fi
    
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        echo "ERROR: Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    echo "✓ Dependencies check passed (Docker available)"
    echo
}

# Download PubNub C-Core
download_pubnub() {
    if [ -d "pubnub-c-core" ]; then
        echo "PubNub C-Core directory already exists. Skipping download..."
        echo "✓ Using existing PubNub C-Core v5.1.1"
        echo
        return 0
    fi
    
    echo "Downloading PubNub C-Core v5.1.1..."
    
    echo "Downloading tarball..."
    if command -v wget &> /dev/null; then
        wget https://github.com/pubnub/c-core/archive/refs/tags/v5.1.1.tar.gz
    elif command -v curl &> /dev/null; then
        curl -L -o v5.1.1.tar.gz https://github.com/pubnub/c-core/archive/refs/tags/v5.1.1.tar.gz
    else
        echo "ERROR: Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    tar -xzf v5.1.1.tar.gz
    mv c-core-5.1.1 pubnub-c-core
    rm v5.1.1.tar.gz
    
    echo "✓ PubNub C-Core v5.1.1 downloaded"
    echo
}

# Build Docker image and compile the reproduction program
compile_program() {
    echo "Building Docker image for FreeRTOS/mbedTLS environment..."
    
    # Build Docker image
    docker build -t pubnub-freertos-mbedtls .
    
    echo "✓ Docker image built successfully"
    echo
    
    echo "Compiling the reproduction program with FreeRTOS/mbedTLS..."
    
    # Check if we already have a properly prepared FreeRTOS file
    if [ -f "pubnub_subscribe_bug_reproduction_freertos.c" ] && grep -q "freertos/FreeRTOS.h" pubnub_subscribe_bug_reproduction_freertos.c; then
        echo "Using existing FreeRTOS reproduction file with simulation support..."
    else
        echo "Preparing reproduction file for FreeRTOS build..."
        # Only create the FreeRTOS file if it doesn't exist or needs updating
        if [ ! -f "pubnub_subscribe_bug_reproduction_freertos.c" ]; then
            echo "Creating FreeRTOS reproduction file from POSIX version..."
            cp pubnub_subscribe_bug_reproduction.c pubnub_subscribe_bug_reproduction_freertos.c
        fi
        
        # Fix the includes for FreeRTOS platform
        echo "Updating includes for FreeRTOS platform..."
        sed -i '' 's|#include "pubnub-c-core/posix/pubnub_sync.h"|#include "freertos/pubnub_sync.h"|g' pubnub_subscribe_bug_reproduction_freertos.c
        sed -i '' 's|#include "pubnub-c-core/core/pubnub_helper.h"|#include "core/pubnub_helper.h"|g' pubnub_subscribe_bug_reproduction_freertos.c
        sed -i '' 's|#include "pubnub-c-core/core/pubnub_timers.h"|#include "core/pubnub_timers.h"|g' pubnub_subscribe_bug_reproduction_freertos.c
        sed -i '' 's|#include "pubnub-c-core/core/pubnub_log.h"|#include "core/pubnub_log.h"|g' pubnub_subscribe_bug_reproduction_freertos.c
        sed -i '' 's|#include "pubnub_coreapi.h"|#include "core/pubnub_coreapi.h"|g' pubnub_subscribe_bug_reproduction_freertos.c
        sed -i '' 's|#include "pubnub_memory_block.h"|#include "core/pubnub_memory_block.h"|g' pubnub_subscribe_bug_reproduction_freertos.c
        
        # Add FreeRTOS includes only if not already present
        if ! grep -q "freertos/FreeRTOS.h" pubnub_subscribe_bug_reproduction_freertos.c; then
            sed -i '' '1i\
#include "freertos/FreeRTOS.h"\
#include "freertos/task.h"\
#include "freertos/semphr.h"\
' pubnub_subscribe_bug_reproduction_freertos.c
        fi
        
        # Fix the log level setting function call
        echo "Fixing log level function call..."
        sed -i '' 's|pubnub_set_log_level(PUBNUB_LOG_LEVEL_TRACE);|printf("Log level set to TRACE at compile time...\\n");|g' pubnub_subscribe_bug_reproduction_freertos.c
        sed -i '' 's|printf("Setting log level to TRACE...");|printf("Log level set to TRACE at compile time...");|g' pubnub_subscribe_bug_reproduction_freertos.c
    fi
    
    # Build in Docker container
    echo "Building PubNub library with FreeRTOS/mbedTLS in Docker container..."
    docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c "
        echo '=== Building PubNub C-Core with FreeRTOS/mbedTLS ==='
        cd /app/pubnub-c-core/posix

        echo 'Cleaning and building PubNub library...'
        make -f posix.mk clean
        make -f posix.mk pubnub_sync_sample

        echo 'Compiling FreeRTOS reproduction program with mbedTLS...'
        gcc -o pubnub_subscribe_bug_reproduction_freertos \\
            -I.. -I. -I../lib/base64 -I../posix -I../core \\
            -DPUBNUB_CRYPTO_API=0 \\
            -DPUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE \\
            -DPUBNUB_ONLY_PUBSUB_API=0 \\
            -DPUBNUB_PROXY_API=1 \\
            -DPUBNUB_RECEIVE_GZIP_RESPONSE=1 \\
            -DPUBNUB_THREADSAFE=1 \\
            -DPUBNUB_USE_ACTIONS_API=1 \\
            -DPUBNUB_USE_ADVANCED_HISTORY=1 \\
            -DPUBNUB_USE_AUTO_HEARTBEAT=1 \\
            -DPUBNUB_USE_FETCH_HISTORY=1 \\
            -DPUBNUB_USE_GRANT_TOKEN_API=0 \\
            -DPUBNUB_USE_GZIP_COMPRESSION=1 \\
            -DPUBNUB_USE_IPV6=0 \\
            -DPUBNUB_USE_OBJECTS_API=1 \\
            -DPUBNUB_USE_RETRY_CONFIGURATION=0 \\
            -DPUBNUB_USE_REVOKE_TOKEN_API=0 \\
            -DPUBNUB_USE_SSL=1 \\
            -DPUBNUB_BLOCKING_IO_SETTABLE=0 \\
            -DPUBNUB_USE_SUBSCRIBE_EVENT_ENGINE=0 \\
            -DPUBNUB_USE_SUBSCRIBE_V2=1 \\
            -DPUBNUB_USE_LOG_CALLBACK=0 \\
            -DFREERTOS_SIMULATION=1 \\
            /app/pubnub_subscribe_bug_reproduction_freertos.c \\
            pubnub_sync.a -lmbedtls -lmbedx509 -lmbedcrypto -lpthread

        echo '✓ FreeRTOS reproduction program compiled successfully'
        echo '✓ Build completed successfully'
    "
    
    echo "✓ Program compiled successfully with FreeRTOS/mbedTLS"
    echo
}

# Run the reproduction test
run_test() {
    echo "Running the reproduction test with FreeRTOS/mbedTLS..."
    echo "This will attempt to reproduce the subscribe bug in v5.1.1 using FreeRTOS/mbedTLS"
    echo "The program should hang at 'Step 6: Calling pubnub_subscribe...'"
    echo "Press Ctrl+C if it hangs for more than 15 seconds"
    echo
    echo "Starting test in 3 seconds..."
    sleep 3
    
    # Run the test in Docker container
    echo "Running test in Docker container..."
    docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c "
        if [ -f '/app/pubnub-c-core/posix/pubnub_subscribe_bug_reproduction_freertos' ]; then
            cd /app/pubnub-c-core/posix
            ./pubnub_subscribe_bug_reproduction_freertos
        else
            echo 'ERROR: FreeRTOS reproduction program not found. Compilation may have failed.'
            exit 1
        fi
    "
}

# Main execution
main() {
    check_dependencies
    download_pubnub
    compile_program
    
    echo "Setup completed successfully!"
    echo
    echo "To run the reproduction test:"
    echo "  docker run --rm -v \"$(pwd):/app\" pubnub-freertos-mbedtls sh -c 'cd /app/pubnub-c-core/posix && ./pubnub_subscribe_bug_reproduction_freertos'"
    echo
    echo "To run with the setup script:"
    echo "  $0 --run"
    echo
    
    # Check if --run flag was passed
    if [ "$1" = "--run" ]; then
        run_test
    fi
}

# Parse command line arguments
case "${1:-}" in
    --run)
        if [ ! -f "pubnub-c-core/posix/pubnub_subscribe_bug_reproduction_freertos" ]; then
            echo "Program not found. Running full setup first..."
            main --run
        else
            run_test
        fi
        ;;
    --help)
        echo "PubNub C-Core Subscribe Bug Reproduction Setup Script"
        echo
        echo "Usage:"
        echo "  $0              # Download and compile only"
        echo "  $0 --run        # Download, compile, and run test"
        echo "  $0 --help       # Show this help message"
        echo
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
