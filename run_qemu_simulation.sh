#!/bin/bash

echo "=== Running ESP32 QEMU Simulation ==="
echo

# Check if ESP-IDF is installed
if [ ! -d "$HOME/esp/esp-idf" ]; then
    echo "❌ ESP-IDF not found at $HOME/esp/esp-idf"
    echo "Please run ./setup_local_esp_idf.sh first"
    exit 1
fi

# Set up environment
export IDF_PATH=$HOME/esp/esp-idf
source $IDF_PATH/export.sh

echo "✓ ESP-IDF environment loaded"
echo

# Navigate to project
cd esp_project_local

# Check if project is built
if [ ! -f "build/pubnub_freertos_local.bin" ]; then
    echo "Building ESP32 firmware for QEMU..."
    idf.py build
    if [ $? -ne 0 ]; then
        echo "❌ Build failed!"
        exit 1
    fi
    echo "✓ Build complete"
else
    echo "✓ Using existing build"
fi

echo
echo "Starting QEMU ESP32 simulation..."
echo "Press Ctrl+C to exit"
echo

# Create proper flash image for QEMU with bootloader and partition table
echo "Creating proper flash image for QEMU..."
dd if=/dev/zero of=build/flash_image.bin bs=4M count=1 2>/dev/null

# Flash bootloader at 0x1000
dd if=build/bootloader/bootloader.bin of=build/flash_image.bin bs=1 seek=4096 conv=notrunc 2>/dev/null

# Flash partition table at 0x8000
dd if=build/partition_table/partition-table.bin of=build/flash_image.bin bs=1 seek=32768 conv=notrunc 2>/dev/null

# Flash application at 0x10000
dd if=build/pubnub_freertos_local.bin of=build/flash_image.bin bs=1 seek=65536 conv=notrunc 2>/dev/null

# Run QEMU with ESP32 emulation
qemu-system-xtensa \
    -machine esp32 \
    -drive file=build/flash_image.bin,if=mtd,format=raw \
    -serial stdio \
    -display none \
    -no-reboot

echo
echo "✓ QEMU simulation ended"