#!/bin/bash

echo "=== Running ESP-IDF locally for PubNub FreeRTOS testing ==="
echo

# Check if ESP-IDF is installed
if [ ! -d "$HOME/esp/esp-idf" ]; then
    echo "ESP-IDF not found. Installing first..."
    ./setup_local_esp_idf.sh
else
    echo "Using existing ESP-IDF installation"
fi

# Set up environment
export IDF_PATH=$HOME/esp/esp-idf
source $IDF_PATH/export.sh

echo "✓ ESP-IDF environment loaded"
echo

# Navigate to project
cd esp_project_local

echo "Building ESP32 firmware with local ESP-IDF..."

# Set target (only needed once)
if [ ! -f "sdkconfig" ]; then
    echo "Setting ESP32 target..."
    idf.py set-target esp32
fi

# Build project
echo "Building project..."
idf.py build

echo
echo "✓ Build complete!"
echo
echo "Build artifacts:"
echo "- Firmware: build/pubnub_freertos_local.bin"
echo "- Bootloader: build/bootloader/bootloader.bin"
echo "- Partition table: build/partition_table/partition-table.bin"
echo
echo "To flash to ESP32:"
echo "  idf.py flash monitor"
echo
echo "Or specify port:"
echo "  idf.py -p /dev/cu.usbserial-* flash monitor    # macOS"
echo "  idf.py -p /dev/ttyUSB0 flash monitor           # Linux"
echo "  idf.py -p COM* flash monitor                   # Windows"
echo