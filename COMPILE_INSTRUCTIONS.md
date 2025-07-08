# PubNub C-Core ESP32 Project - Compilation Instructions

## Prerequisites

### For QEMU ESP32 Simulation (Recommended)
1. **ESP-IDF**: v5.1.4 installed locally
2. **QEMU**: ESP32 emulation support (included in ESP-IDF)
3. **Disk Space**: ~2GB for ESP-IDF installation

### For ESP32 Hardware
1. **ESP-IDF**: v5.1.4 (installed via setup script)
2. **ESP32 Hardware**: ESP32 development board
3. **USB Cable**: To connect ESP32 to computer

### For POSIX Simulation
1. **C Compiler**: GCC or Clang
2. **POSIX System**: Linux, macOS, or Windows with WSL
3. **pthread Support**: For FreeRTOS simulation

## Quick Setup

### Option 1: QEMU ESP32 Simulation (Recommended)

**Run ESP32 project in virtual hardware:**

1. **One-time setup** (installs ESP-IDF locally):
   ```bash
   ./setup_local_esp_idf.sh
   ```

2. **Run QEMU simulation**:
   ```bash
   ./run_qemu_simulation.sh
   ```

**Features**:
- ✅ **Real ESP32 emulation** with QEMU virtual hardware
- ✅ **Real FreeRTOS** v10.4.3 kernel execution
- ✅ **Hardware peripherals** simulation (UART, timers, etc.)
- ✅ **No physical hardware** required
- ✅ **Accurate testing** without actual ESP32

### Option 2: ESP32 Hardware

**For testing on real ESP32 hardware:**

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

### Option 3: POSIX Simulation

**Quick testing on your laptop:**

```bash
./run_local_simulation.sh
```

**Features**:
- ✅ FreeRTOS simulation using POSIX threads
- ✅ Cross-platform compatibility
- ✅ Fast development iteration

## Expected Behavior

### QEMU ESP32 Simulation
The QEMU simulation provides authentic ESP32 boot sequence and FreeRTOS execution:
- ESP32 bootloader initialization
- FreeRTOS v10.4.3 kernel startup
- PubNub C-Core initialization and testing
- Real hardware peripheral emulation

### ESP32 Hardware
- Real FreeRTOS v10.4.3 kernel with real-time scheduling
- ESP32 native mbedTLS with hardware acceleration
- WiFi connectivity for PubNub communication
- Actual embedded constraints and timing

### POSIX Simulation
- FreeRTOS simulation using POSIX threads
- Cross-platform compatibility
- Fast development iteration

## Debugging Tips

### QEMU Debug
```bash
# Run with verbose output
./run_qemu_simulation.sh

# QEMU machine info
qemu-system-xtensa -machine esp32 -machine help
```

### ESP32 Hardware Debug
```bash
# Source ESP-IDF environment
source $HOME/esp/esp-idf/export.sh

# Flash with monitoring
cd esp_project_local
idf.py flash monitor

# Port detection
ls /dev/cu.usbserial-*     # macOS
ls /dev/ttyUSB*            # Linux
```

### POSIX Simulation Debug
```bash
# Run with GDB
cd local_simulation
gdb ./freertos_simulation
```

## Clean Up

```bash
# Clean build artifacts
cd esp_project_local
idf.py clean

# Remove ESP-IDF (optional)
rm -rf ~/esp/esp-idf
```