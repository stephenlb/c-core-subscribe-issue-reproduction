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
    
    if ! command -v git &> /dev/null; then
        echo "WARNING: git not found. Will try to use wget instead."
    fi
    
    echo "✓ Dependencies check passed"
    echo
}

# Download PubNub C-Core
download_pubnub() {
    echo "Downloading PubNub C-Core v5.1.0..."
    
    if [ -d "pubnub-c-core" ]; then
        echo "pubnub-c-core directory already exists. Removing..."
        rm -rf pubnub-c-core
    fi
    
    if command -v git &> /dev/null; then
        echo "Using git to clone repository..."
        git clone https://github.com/pubnub/c-core.git pubnub-c-core
        cd pubnub-c-core
        git checkout v5.1.0
        cd ..
    else
        echo "Using wget to download tarball..."
        wget https://github.com/pubnub/c-core/archive/v5.1.0.tar.gz
        tar -xzf v5.1.0.tar.gz
        mv c-core-5.1.0 pubnub-c-core
        rm v5.1.0.tar.gz
    fi
    
    echo "✓ PubNub C-Core v5.1.0 downloaded"
    echo
}

# Compile the reproduction program
compile_program() {
    echo "Compiling the reproduction program..."
    
    if [ -f "Makefile" ]; then
        echo "Using provided Makefile..."
        make clean || true  # Don't fail if nothing to clean
        make
    else
        echo "Makefile not found, compiling manually..."
        gcc -std=c99 -Wall -Wextra -g -O0 \
            -I./pubnub-c-core/core \
            -I./pubnub-c-core/lib \
            -I./pubnub-c-core/posix \
            -DPUBNUB_THREADSAFE=1 \
            -o pubnub_subscribe_bug_reproduction \
            pubnub_subscribe_bug_reproduction.c \
            ./pubnub-c-core/core/*.c \
            ./pubnub-c-core/posix/*.c \
            -lpthread
    fi
    
    echo "✓ Program compiled successfully"
    echo
}

# Run the reproduction test
run_test() {
    echo "Running the reproduction test..."
    echo "This will attempt to reproduce the subscribe bug in v5.1.0"
    echo "The program should hang at 'Step 6: Calling pubnub_subscribe...'"
    echo "Press Ctrl+C if it hangs for more than 15 seconds"
    echo
    echo "Starting test in 3 seconds..."
    sleep 3
    
    ./pubnub_subscribe_bug_reproduction
}

# Main execution
main() {
    check_dependencies
    download_pubnub
    compile_program
    
    echo "Setup completed successfully!"
    echo
    echo "To run the reproduction test:"
    echo "  ./pubnub_subscribe_bug_reproduction"
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
        if [ ! -f "pubnub_subscribe_bug_reproduction" ]; then
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