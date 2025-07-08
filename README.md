# PubNub C-Core ESP32 Project - FreeRTOS & QEMU Simulation

## Summary

ESP32 project with PubNub C-Core integration featuring multiple testing environments:
- **Real ESP32 Hardware**: FreeRTOS v10.4.3 with mbedTLS hardware acceleration
- **QEMU Simulation**: Virtual ESP32 emulation with real FreeRTOS execution
- **POSIX Simulation**: Local development environment

## Test Environments

### 1. QEMU ESP32 Simulation (Recommended)
- **Platform**: QEMU virtual ESP32 with real FreeRTOS execution
- **Features**: Real ESP32 emulation, actual FreeRTOS kernel, hardware peripherals
- **Purpose**: Accurate testing without physical hardware
- **Command**: `./run_qemu_simulation.sh`

### 2. ESP32 Hardware
- **Platform**: ESP32 microcontroller with Xtensa dual-core
- **FreeRTOS**: Real FreeRTOS v10.4.3 kernel with real-time scheduling
- **SSL/TLS**: ESP32 native mbedTLS with hardware acceleration
- **Build System**: ESP-IDF v5.1 with official Espressif toolchain

### 3. POSIX Simulation
- **Platform**: POSIX threads simulating FreeRTOS behavior
- **Purpose**: Quick development and testing without hardware
- **Command**: `./run_local_simulation.sh`

## Usage

### QEMU ESP32 Simulation

Run the ESP32 project in QEMU emulation:

```bash
./run_qemu_simulation.sh
```

**Expected Output:**
```
=== Running ESP32 QEMU Simulation ===
✓ ESP-IDF environment loaded
✓ Using existing build

Starting QEMU ESP32 simulation...
Press Ctrl+C to exit

Creating proper flash image for QEMU...
Adding SPI flash device
ets Jul 29 2019 12:21:46

rst:0x1 (POWERON_RESET),boot:0x12 (SPI_FAST_FLASH_BOOT)
configsip: 0, SPIWP:0xee
clk_drv:0x00,q_drv:0x00,d_drv:0x00,cs0_drv:0x00,hd_drv:0x00,wp_drv:0x00
mode:DIO, clock div:2
load:0x3fff0030,len:7116
load:0x40078000,len:15560
ho 0 tail 12 room 4
load:0x40080400,len:4
0x40080400: _init at ??:?

load:0x40080404,len:3876
entry 0x4008059c
I (29) boot: ESP-IDF v5.1.4 2nd stage bootloader
I (29) boot: compile time Jun 20 2024 16:32:17
I (29) boot: Multicore bootloader
I (33) boot: chip revision: v3.0
I (37) qemu_io: QEMU virtual ESP32 detected
I (42) boot.esp32: SPI Speed      : 40MHz
I (46) boot.esp32: SPI Mode       : DIO
I (51) boot.esp32: SPI Flash Size : 4MB
I (55) boot: Enabling RNG early entropy source...
I (61) boot: Partition Table:
I (64) boot: ## Label            Usage          Type ST Offset   Length
I (71) boot:  0 nvs              WiFi data        01 02 00009000 00006000
I (79) boot:  1 phy_init         RF data          01 01 0000f000 00001000
I (86) boot:  2 factory          factory app      00 00 00010000 00100000
I (94) boot: End of partition table
I (98) esp_image: segment 0: paddr=00010020 vaddr=3f400020 size=09050h ( 36944) map
I (119) esp_image: segment 1: paddr=00019078 vaddr=3ffb0000 size=022c0h (  8896) load
I (122) esp_image: segment 2: paddr=0001b340 vaddr=40080000 size=046c0h ( 18112) load
I (132) esp_image: segment 3: paddr=0001fa08 vaddr=400c6c00 size=00014h (    20) load
I (133) esp_image: segment 4: paddr=0001fa24 vaddr=50000000 size=00000h (     0) load
I (141) boot: Loaded app from partition at offset 0x10000
I (141) boot: Disabling RNG early entropy source...
I (152) cpu_start: Multicore app
I (161) cpu_start: Pro cpu start user code
I (161) cpu_start: cpu freq: 160000000 Hz
I (161) cpu_start: Application information:
I (164) cpu_start: Project name:     pubnub_freertos_local
I (170) cpu_start: App version:      1
I (174) cpu_start: Compile time:     Jul  7 2025 16:50:56
I (180) cpu_start: ELF file SHA256:  0000000000000000...
I (186) cpu_start: ESP-IDF:          v5.1.4
I (191) cpu_start: Min chip rev:     v0.0
I (195) cpu_start: Max chip rev:     v3.99 
I (200) cpu_start: Chip rev:         v3.0
I (205) heap_init: Initializing. RAM available for dynamic allocation:
I (212) heap_init: At 3FFAE6E0 len 00001920 (6 KiB): DRAM
I (218) heap_init: At 3FFB2EC8 len 0002D138 (180 KiB): DRAM
I (224) heap_init: At 3FFE0440 len 00003AE0 (14 KiB): D/IRAM
I (231) heap_init: At 3FFE4350 len 0001BCB0 (111 KiB): D/IRAM
I (237) heap_init: At 40094C14 len 0000B3EC (44 KiB): IRAM
I (244) spi_flash: detected chip: generic
I (248) spi_flash: flash io: dio
I (252) app_start: Starting scheduler on CPU0
I (257) app_start: Starting scheduler on CPU1
I (257) main_task: Started on CPU0
I (267) main_task: Calling app_main()
I (267) PUBNUB_TEST: === PubNub C-Core ESP32 FreeRTOS Test ===
I (267) PUBNUB_TEST: FreeRTOS version: FreeRTOS v10.4.3
I (277) PUBNUB_TEST: ESP-IDF version: v5.1.4
I (287) PUBNUB_TEST: Free heap: 290816 bytes
I (287) PUBNUB_TEST: Initializing PubNub...
```

### ESP32 Hardware

Build and flash to real ESP32:

```bash
./run_local_esp_idf.sh
cd esp_project_local
idf.py flash monitor
```

### POSIX Simulation

Run on your laptop:

```bash
./run_local_simulation.sh
```

## Features

- **PubNub C-Core**: Latest C-Core SDK integration
- **FreeRTOS**: Real-time operating system support
- **mbedTLS**: Hardware-accelerated SSL/TLS encryption
- **ESP-IDF**: Professional ESP32 development framework
- **QEMU**: Virtual hardware simulation for testing

## Project Structure

```
esp_project_local/          # ESP-IDF project directory
├── main/
│   ├── main.c             # PubNub test application
│   └── CMakeLists.txt     # Build configuration
├── components/
│   └── pubnub/            # PubNub C-Core library
├── sdkconfig              # ESP32 configuration
└── build/                 # Build artifacts

run_qemu_simulation.sh     # QEMU simulation script
run_local_simulation.sh    # POSIX simulation script
run_local_esp_idf.sh       # ESP32 build script
```
