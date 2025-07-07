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
    echo "Building Docker image for Real FreeRTOS/mbedTLS environment (ESP-IDF)..."
    
    # Build Docker image
    docker build -t pubnub-freertos-mbedtls .
    
    echo "✓ Docker image built successfully"
    echo
    
    echo "Creating ESP-IDF project with Real FreeRTOS/mbedTLS..."
    
    # Build ESP-IDF project in Docker container
    echo "Building ESP-IDF project with Real FreeRTOS and mbedTLS..."
    docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls /app/build_real_freertos.sh
    
    echo "✓ Real FreeRTOS project built successfully"
    echo
}

# Run the reproduction test
run_test() {
    echo "Real FreeRTOS/mbedTLS ESP-IDF project has been built successfully!"
    echo
    echo "The ESP-IDF project creates firmware that runs on ESP32 hardware with:"
    echo "- ✓ Real FreeRTOS kernel (not simulation)"
    echo "- ✓ mbedTLS for SSL/TLS support"
    echo "- ✓ WiFi connectivity for PubNub communication"
    echo "- ✓ PubNub C-Core v5.1.1 bug reproduction test"
    echo
    echo "To run this on actual ESP32 hardware:"
    echo "1. Connect ESP32 device via USB"
    echo "2. Configure WiFi credentials in esp_project/sdkconfig.defaults"
    echo "3. Flash and monitor:"
    echo "   docker run --rm -it --device=/dev/ttyUSB0 -v \"\$(pwd):/app\" pubnub-freertos-mbedtls sh -c 'cd /app/esp_project && idf.py flash monitor'"
    echo
    echo "Build artifacts:"
    echo "- Firmware binary: esp_project/build/pubnub_freertos_test.bin"
    echo "- Bootloader: esp_project/build/bootloader/bootloader.bin"
    echo "- Partition table: esp_project/build/partition_table/partition-table.bin"
    echo
    echo "The real FreeRTOS environment will test the same bug reproduction scenario"
    echo "but running on actual FreeRTOS with real-time constraints and ESP32 hardware."
}

# Main execution
main() {
    check_dependencies
    download_pubnub
    compile_program
    
    echo "Setup completed successfully!"
    echo
    echo "Real FreeRTOS/mbedTLS ESP-IDF project ready!"
    echo
    echo "To flash to ESP32 hardware:"
    echo "  docker run --rm -it --device=/dev/ttyUSB0 -v \"$(pwd):/app\" pubnub-freertos-mbedtls sh -c 'cd /app/esp_project && idf.py flash monitor'"
    echo
    echo "To view project details:"
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
        if [ ! -d "esp_project" ]; then
            echo "ESP-IDF project not found. Running full setup first..."
            main --run
        else
            run_test
        fi
        ;;
    --help)
        echo "PubNub C-Core Subscribe Bug Reproduction Setup Script (Real FreeRTOS/mbedTLS)"
        echo
        echo "Usage:"
        echo "  $0              # Download and compile ESP-IDF project"
        echo "  $0 --run        # Download, compile, and show flash instructions"
        echo "  $0 --help       # Show this help message"
        echo
        echo "This script creates a real FreeRTOS/mbedTLS environment using ESP-IDF"
        echo "for ESP32 hardware. The output is firmware that can be flashed to"
        echo "an actual ESP32 device for testing the PubNub subscribe bug."
        echo
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
