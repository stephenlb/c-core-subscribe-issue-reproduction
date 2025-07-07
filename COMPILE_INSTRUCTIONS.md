# PubNub C-Core Subscribe Bug Reproduction - Compilation Instructions (Real FreeRTOS/mbedTLS)

## Prerequisites

### For Real ESP32/FreeRTOS Build (Recommended)
#### Option A: Docker-based ESP-IDF
1. **Docker**: Docker Desktop or Docker Engine
2. **ESP32 Hardware**: ESP32 development board for flashing firmware
3. **USB Cable**: To connect ESP32 to computer
4. **Internet Access**: For downloading ESP-IDF and PubNub C-Core

#### Option B: Local ESP-IDF Installation
1. **ESP-IDF**: v5.1.4 (installed via setup script)
2. **ESP32 Hardware**: ESP32 development board
3. **USB Cable**: To connect ESP32 to computer
4. **Disk Space**: ~2GB for ESP-IDF installation
5. **Python 3**: Required by ESP-IDF (usually pre-installed)

### For FreeRTOS Simulation (Local Testing)
1. **C Compiler**: GCC or Clang
2. **POSIX System**: Linux, macOS, or Windows with WSL
3. **pthread Support**: For FreeRTOS simulation

### For Legacy POSIX Build
1. **C Compiler**: GCC or Clang
2. **Make**: GNU Make or compatible
3. **PubNub C-Core SDK**: Version 5.1.0 or 5.1.1 to reproduce the bug

## Quick Setup

### Option 1: Local FreeRTOS Simulation (Immediate Testing)

**Quick start for immediate testing without hardware:**
```bash
# Run FreeRTOS simulation directly on your laptop
./run_local_simulation.sh
```

**Features**:
- ✅ FreeRTOS simulation using POSIX threads
- ✅ ESP32-style logging and system calls
- ✅ Immediate testing without hardware
- ✅ Cross-platform compatibility (macOS, Linux, Windows)
- ⚠️ **Simulation only** - doesn't test real FreeRTOS timing constraints

### Option 2A: Real ESP32/FreeRTOS (Docker-based)

This approach uses Docker with ESP-IDF to create real ESP32 firmware with authentic FreeRTOS.

1. **Build ESP32 firmware automatically**:
   ```bash
   # Downloads PubNub C-Core v5.1.1, builds ESP32 firmware
   ./setup_and_test.sh
   ```

2. **Flash to ESP32 hardware**:
   ```bash
   # Connect ESP32 via USB first, then flash
   docker run --rm -it --device=/dev/ttyUSB0 -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c 'cd /app/esp_project && idf.py flash monitor'
   ```

**Features**:
- ✅ **Real FreeRTOS** v10.4.3 kernel with real-time scheduling
- ✅ **Real mbedTLS** with ESP32 hardware acceleration
- ✅ **Actual timing constraints** and memory limitations
- ✅ **Consistent build environment** across platforms
- ✅ **ESP32 firmware** ready for hardware testing

### Option 2B: Real ESP32/FreeRTOS (Local ESP-IDF)

**For native ESP32 development with full toolchain access:**

1. **One-time setup** (installs ESP-IDF locally):
   ```bash
   ./setup_local_esp_idf.sh
   ```

2. **Build ESP32 firmware**:
   ```bash
   ./run_local_esp_idf.sh
   ```

3. **Flash to ESP32 hardware**:
   ```bash
   cd esp_project_local
   idf.py flash monitor
   
   # Or specify port manually
   idf.py -p /dev/cu.usbserial-* flash monitor    # macOS
   idf.py -p /dev/ttyUSB0 flash monitor           # Linux  
   idf.py -p COM* flash monitor                   # Windows
   ```

**Features**:
- ✅ **Native ESP-IDF** v5.1.4 installation
- ✅ **Direct access** to ESP-IDF tools and debugging
- ✅ **IDE integration** (VS Code, CLion)
- ✅ **Native idf.py** commands
- ✅ **Professional ESP32 development** environment

### Option 3: Using the Provided Makefile (Legacy POSIX)

1. **Download PubNub C-Core**:
   ```bash
   # Clone the repository
   git clone https://github.com/pubnub/c-core.git pubnub-c-core
   
   # Or download a specific version
   wget https://github.com/pubnub/c-core/archive/v5.1.1.tar.gz
   tar -xzf v5.1.1.tar.gz
   mv c-core-5.1.1 pubnub-c-core
   ```

2. **Compile the reproduction program**:
   ```bash
   make
   ```

3. **Run the reproduction test**:
   ```bash
   ./pubnub_subscribe_bug_reproduction
   ```

### Option 4: Manual Compilation (Legacy POSIX)

If you prefer to compile manually or the Makefile doesn't work for your system:

1. **Download PubNub C-Core** (same as above)

2. **Compile using the POSIX makefile approach**:
   ```bash
   # Navigate to the PubNub C-Core directory
   cd pubnub-c-core
   
   # Use the provided POSIX makefile
   make -f posix/posix.mk clean
   make -f posix/posix.mk
   
   # Go back to the reproduction directory
   cd ..
   
   # Compile the reproduction program
   gcc -std=c99 -Wall -Wextra -g -O0 \
       -I./pubnub-c-core/core \
       -I./pubnub-c-core/lib \
       -I./pubnub-c-core/posix \
       -o pubnub_subscribe_bug_reproduction \
       pubnub_subscribe_bug_reproduction.c \
       -L./pubnub-c-core \
       -lpubnub_sync \
       -lpthread
   ```

### Option 5: Using PubNub's Build System (Legacy POSIX)

If you have the PubNub C-Core source and want to use their build system:

1. **Copy the reproduction file to the PubNub examples directory**:
   ```bash
   cp pubnub_subscribe_bug_reproduction.c pubnub-c-core/
   ```

2. **Modify the PubNub Makefile** to include your reproduction program:
   ```bash
   cd pubnub-c-core
   # Edit the posix.mk file to add your program as a target
   ```

3. **Build using their system**:
   ```bash
   make -f posix/posix.mk pubnub_subscribe_bug_reproduction
   ```

## Compilation Flags Explanation

### ESP32/FreeRTOS Build (ESP-IDF)
**ESP-IDF automatically handles compilation with these features:**
- **Real FreeRTOS**: v10.4.3 kernel with real-time scheduling
- **mbedTLS**: Hardware-accelerated SSL/TLS support
- **WiFi Stack**: ESP32 native WiFi for PubNub connectivity
- **Xtensa Architecture**: Dual-core ESP32 processor support
- **CMake Build System**: Official Espressif toolchain

### FreeRTOS Simulation Build Flags (Local)
- `-DFREERTOS_SIMULATION=1`: Enable FreeRTOS simulation mode
- `-lpthread`: POSIX threads for FreeRTOS simulation
- `-I local_simulation`: Include simulation headers
- **FreeRTOS API Compatibility**: Mock FreeRTOS functions using POSIX

### Legacy POSIX Build Flags
- `-std=c99`: Use C99 standard
- `-Wall -Wextra`: Enable comprehensive warnings
- `-g`: Include debug information
- `-O0`: Disable optimizations for debugging
- `-lpthread`: Link with pthread library (required for PubNub C-Core)

## Testing Different Environments

### Real ESP32/FreeRTOS Environment

#### Docker-based ESP-IDF
```bash
# Build ESP32 firmware
./setup_and_test.sh

# Flash to ESP32 (connect ESP32 via USB first)
docker run --rm -it --device=/dev/ttyUSB0 -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c 'cd /app/esp_project && idf.py flash monitor'
```

#### Local ESP-IDF
```bash
# Setup ESP-IDF locally (one-time)
./setup_local_esp_idf.sh

# Build ESP32 firmware
./run_local_esp_idf.sh

# Flash to ESP32
cd esp_project_local
idf.py flash monitor
```

### FreeRTOS Simulation Environment
```bash
# Test FreeRTOS simulation on laptop
./run_local_simulation.sh
```

### Testing Different Versions (Legacy POSIX)

To test the bug across different versions:

1. **Test with v5.0.3 (working version)**:
   ```bash
   git clone https://github.com/pubnub/c-core.git pubnub-c-core-503
   cd pubnub-c-core-503
   git checkout v5.0.3
   cd ..
   # Update PUBNUB_ROOT in Makefile to point to pubnub-c-core-503
   make clean && make
   ./pubnub_subscribe_bug_reproduction
   ```

2. **Test with v5.1.0 (broken version)**:
   ```bash
   git clone https://github.com/pubnub/c-core.git pubnub-c-core-510
   cd pubnub-c-core-510
   git checkout v5.1.0
   cd ..
   # Update PUBNUB_ROOT in Makefile to point to pubnub-c-core-510
   make clean && make
   ./pubnub_subscribe_bug_reproduction
   ```

3. **Test with v5.1.1 (still broken version)**:
   ```bash
   git clone https://github.com/pubnub/c-core.git pubnub-c-core-511
   cd pubnub-c-core-511
   git checkout v5.1.1
   cd ..
   # Update PUBNUB_ROOT in Makefile to point to pubnub-c-core-511
   make clean && make
   ./pubnub_subscribe_bug_reproduction
   ```

## Expected Behavior

### Real ESP32/FreeRTOS Environment
**Current Status**: ESP32 firmware builds successfully
- **Build Output**: `pubnub_freertos_test.bin` (172KB firmware)
- **Real FreeRTOS**: v10.4.3 kernel with real-time scheduling
- **Hardware acceleration**: ESP32 mbedTLS with crypto acceleration
- **WiFi connectivity**: ESP32 WiFi stack for PubNub communication
- **Flash target**: Ready for ESP32 hardware testing

### FreeRTOS Simulation Environment (Local)
**Current Status**: Working correctly (no hanging observed)
- `pubnub_subscribe()` returns `PNR_STARTED` (14) immediately (simulated)
- `pubnub_await()` completes with `PNR_OK` (0) (simulated)
- FreeRTOS API compatibility via POSIX threads
- Program finishes within 1 second
- Cross-platform laptop testing

### Working Version (v5.0.3 - Legacy POSIX)
- `pubnub_subscribe()` should return `PNR_STARTED` immediately
- `pubnub_await()` should complete normally
- The program should finish within a few seconds

### Broken Version (v5.1.0, v5.1.1 - Legacy POSIX)
- `pubnub_subscribe()` may never return (hangs indefinitely)
- The program will appear to freeze after "Step 6: Calling pubnub_subscribe..."
- You may need to use Ctrl+C to terminate the program
- **Note**: Bug may be environment-specific and not reproduce in all setups

## Debugging Tips

### Real ESP32/FreeRTOS Debug

#### Docker-based ESP-IDF Debugging
1. **Interactive ESP-IDF shell**:
   ```bash
   # Access ESP-IDF container
   docker run --rm -it -v "$(pwd):/app" pubnub-freertos-mbedtls sh
   
   # Check ESP-IDF environment
   idf.py --version
   
   # Monitor ESP32 output
   idf.py monitor
   ```

2. **ESP32 build debugging**:
   ```bash
   # Verbose build
   docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c 'cd /app/esp_project && idf.py build -v'
   ```

#### Local ESP-IDF Debugging
1. **ESP-IDF environment setup**:
   ```bash
   # Source ESP-IDF environment
   source $HOME/esp/esp-idf/export.sh
   
   # Check ESP-IDF tools
   idf.py --version
   esptool.py version
   ```

2. **ESP32 flashing and monitoring**:
   ```bash
   cd esp_project_local
   
   # List available ports
   idf.py list-targets
   
   # Flash with verbose output
   idf.py -v flash
   
   # Monitor serial output
   idf.py monitor
   
   # Flash and monitor together
   idf.py flash monitor
   ```

3. **Port detection issues**:
   ```bash
   # macOS - find USB serial ports
   ls /dev/cu.usbserial-*
   
   # Linux - find USB serial ports
   ls /dev/ttyUSB*
   
   # Windows - COM ports
   # Use Device Manager or: mode
   ```

### FreeRTOS Simulation Debug (Local)
1. **Simulation debugging**:
   ```bash
   # Run with GDB
   cd local_simulation
   gdb ./freertos_simulation
   (gdb) run
   
   # Check simulation headers
   cat local_simulation/freertos/FreeRTOS.h
   ```

### Legacy POSIX Debug
1. **Enable verbose logging**: The program sets `PUBNUB_LOG_LEVEL_TRACE` to see internal operations

2. **Use GDB for debugging**:
   ```bash
   gdb ./pubnub_subscribe_bug_reproduction
   (gdb) run
   # If it hangs, press Ctrl+C and examine the stack
   (gdb) bt
   ```

3. **Check system resources**:
   ```bash
   # Monitor the process while it runs
   top -p $(pgrep pubnub_subscribe_bug_reproduction)
   
   # Check network connections
   netstat -an | grep :80
   ```

4. **Timeout handling**: The program sets a 10-second timeout to prevent infinite hanging

## Environment Variables

You can set these environment variables to modify behavior:

```bash
export PUBNUB_LOG_LEVEL=TRACE  # Enable trace logging
export PUBNUB_ORIGIN=ps.pndsn.com  # Use different origin
```

## Troubleshooting

### Common Issues

1. **Missing headers**: Make sure the PubNub C-Core source is downloaded and paths are correct

2. **Linking errors**: Ensure pthread is installed and linked properly

3. **Permission issues**: Make sure you have write permissions in the directory

4. **Network issues**: The program uses demo keys which should work without authentication

### Platform-Specific Notes

#### ESP32 Hardware Requirements
- **ESP32 Board**: ESP32 DevKit, NodeMCU-32S, or similar (~$10-15)
- **USB Cable**: Usually USB-A to micro-USB or USB-C
- **Drivers**: Usually automatic, may need CP210x or FTDI drivers

#### Docker Environment (All Platforms)
- **macOS**: Docker Desktop for Mac required
- **Linux**: Docker Engine or Docker Desktop
- **Windows**: Docker Desktop for Windows (WSL2 recommended)
- **Container**: ESP-IDF with real FreeRTOS support

#### Local ESP-IDF Environment
- **macOS**: Native ESP-IDF installation via install.sh
- **Linux**: Native ESP-IDF installation via install.sh
- **Windows**: ESP-IDF can be installed but Docker recommended
- **Disk Space**: ~2GB for full ESP-IDF installation

#### Legacy POSIX Environment
- **macOS**: May need to install Xcode command line tools
- **Linux**: Ensure build-essential is installed
- **Windows**: Use MinGW or similar POSIX-compatible environment

## Clean Up

### Docker Environment
```bash
# Remove Docker image
docker rmi pubnub-freertos-mbedtls

# Remove all Docker containers and images (careful!)
docker system prune -a
```

### Legacy POSIX Environment
```bash
# Clean build artifacts
make clean

# Remove all downloaded files
rm -rf pubnub-c-core*
```

## ESP-IDF Environment Details

### Docker Container Specifications
- **Base Image**: espressif/idf:release-v5.1
- **ESP-IDF Version**: v5.1
- **FreeRTOS**: Real FreeRTOS v10.4.3 kernel
- **SSL/TLS Library**: ESP32 native mbedTLS with hardware acceleration
- **Target**: ESP32 with Xtensa dual-core processor
- **WiFi**: ESP32 WiFi stack for PubNub connectivity

### Local ESP-IDF Specifications
- **ESP-IDF Version**: v5.1.4 (latest stable)
- **Installation Path**: `~/esp/esp-idf/`
- **Python Environment**: ESP-IDF managed Python virtual environment
- **Toolchain**: Official Espressif Xtensa toolchain
- **Size**: ~2GB (includes toolchain, Python packages, documentation)

### Build Process
1. **Docker**: Uses official ESP-IDF container with all tools pre-installed
2. **Local**: Downloads and installs ESP-IDF v5.1.4 to user home directory
3. **Project Creation**: Creates ESP-IDF project structure with CMakeLists.txt
4. **Target Configuration**: Sets ESP32 as target platform
5. **Firmware Build**: Creates real ESP32 firmware binary
6. **Flash Ready**: Generates bootloader, partition table, and application binary

### Security Notes
- Container runs as root (standard for build containers)
- No sensitive data is stored in the container
- Network access only for downloading PubNub C-Core
- Container is removed after each run (`--rm` flag)