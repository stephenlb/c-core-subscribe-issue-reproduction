#!/bin/bash

# PubNub C-Core Subscribe Bug Reproduction Setup Script
# This script downloads PubNub C-Core and compiles the reproduction case

set -e  # Exit on any error

echo "=== PubNub C-Core Subscribe Bug Reproduction Setup ==="
echo

# Check if we have the necessary tools
check_dependencies() {
    echo "Checking dependencies..."
    
    if ! command -v gcc &> /dev/null; then
        echo "ERROR: gcc not found. Please install a C compiler."
        exit 1
    fi
    
    if ! command -v make &> /dev/null; then
        echo "ERROR: make not found. Please install GNU Make."
        exit 1
    fi
    
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        echo "ERROR: Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    echo "✓ Dependencies check passed"
    echo
}

# Download PubNub C-Core
download_pubnub() {
    echo "Downloading PubNub C-Core v5.1.1..."
    
    if [ -d "pubnub-c-core" ]; then
        echo "pubnub-c-core directory already exists. Removing..."
        rm -rf pubnub-c-core
    fi
    
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

# Compile the reproduction program
compile_program() {
    echo "Compiling the reproduction program..."
    
    # Copy the reproduction file to the samples directory with correct includes
    echo "Copying reproduction file to PubNub samples directory..."
    cp pubnub_subscribe_bug_reproduction.c pubnub-c-core/core/samples/
    
    # Fix the includes for the samples directory structure
    echo "Fixing include paths for samples directory..."
    sed -i '' 's|#include "pubnub-c-core/posix/pubnub_sync.h"|#include "pubnub_sync.h"|g' pubnub-c-core/core/samples/pubnub_subscribe_bug_reproduction.c
    sed -i '' 's|#include "pubnub-c-core/core/pubnub_helper.h"|#include "core/pubnub_helper.h"|g' pubnub-c-core/core/samples/pubnub_subscribe_bug_reproduction.c
    sed -i '' 's|#include "pubnub-c-core/core/pubnub_timers.h"|#include "core/pubnub_timers.h"|g' pubnub-c-core/core/samples/pubnub_subscribe_bug_reproduction.c
    sed -i '' 's|#include "pubnub-c-core/core/pubnub_log.h"|#include "core/pubnub_log.h"|g' pubnub-c-core/core/samples/pubnub_subscribe_bug_reproduction.c
    
    # Fix the log level setting function call
    echo "Fixing log level function call..."
    sed -i '' 's|pubnub_set_log_level(PUBNUB_LOG_LEVEL_TRACE);|printf("Log level set to TRACE at compile time...\\n");|g' pubnub-c-core/core/samples/pubnub_subscribe_bug_reproduction.c
    sed -i '' 's|printf("Setting log level to TRACE...");|printf("Log level set to TRACE at compile time...");|g' pubnub-c-core/core/samples/pubnub_subscribe_bug_reproduction.c
    
    # Build using PubNub's build system
    echo "Building PubNub library..."
    cd pubnub-c-core/posix
    make -f posix.mk pubnub_sync_sample
    
    echo "Compiling reproduction program..."
    cc -opubnub_subscribe_bug_reproduction -Wall \
       -I.. -I. -I../lib/base64 -I../posix \
       -D PUBNUB_CRYPTO_API=0 \
       -D PUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE \
       -D PUBNUB_ONLY_PUBSUB_API=0 \
       -D PUBNUB_PROXY_API=1 \
       -D PUBNUB_RECEIVE_GZIP_RESPONSE=1 \
       -D PUBNUB_THREADSAFE=1 \
       -D PUBNUB_USE_ACTIONS_API=1 \
       -D PUBNUB_USE_ADVANCED_HISTORY=1 \
       -D PUBNUB_USE_AUTO_HEARTBEAT=1 \
       -D PUBNUB_USE_FETCH_HISTORY=1 \
       -D PUBNUB_USE_GRANT_TOKEN_API=0 \
       -D PUBNUB_USE_GZIP_COMPRESSION=1 \
       -D PUBNUB_USE_IPV6=1 \
       -D PUBNUB_USE_OBJECTS_API=1 \
       -D PUBNUB_USE_RETRY_CONFIGURATION=0 \
       -D PUBNUB_USE_REVOKE_TOKEN_API=0 \
       -D PUBNUB_USE_SSL=0 \
       -D PUBNUB_USE_SUBSCRIBE_EVENT_ENGINE=0 \
       -D PUBNUB_USE_SUBSCRIBE_V2=1 \
       -D PUBNUB_USE_LOG_CALLBACK=0 \
       ../core/samples/pubnub_subscribe_bug_reproduction.c pubnub_sync.a -lpthread
       
    cd ../..
    
    echo "✓ Program compiled successfully"
    echo
}

# Run the reproduction test
run_test() {
    echo "Running the reproduction test..."
    echo "This will attempt to reproduce the subscribe bug in v5.1.1"
    echo "The program should hang at 'Step 6: Calling pubnub_subscribe...'"
    echo "Press Ctrl+C if it hangs for more than 15 seconds"
    echo
    echo "Starting test in 3 seconds..."
    sleep 3
    
    if [ -f "pubnub-c-core/posix/pubnub_subscribe_bug_reproduction" ]; then
        cd pubnub-c-core/posix
        ./pubnub_subscribe_bug_reproduction
        cd ../..
    else
        echo "ERROR: Reproduction program not found. Compilation may have failed."
        exit 1
    fi
}

# Main execution
main() {
    check_dependencies
    download_pubnub
    compile_program
    
    echo "Setup completed successfully!"
    echo
    echo "To run the reproduction test:"
    echo "  cd pubnub-c-core/posix && ./pubnub_subscribe_bug_reproduction"
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
        if [ ! -f "pubnub-c-core/posix/pubnub_subscribe_bug_reproduction" ]; then
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