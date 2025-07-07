# PubNub C-Core Subscribe Bug Reproduction - Compilation Instructions (FreeRTOS/mbedTLS)

## Prerequisites

### For Docker-based FreeRTOS/mbedTLS Build (Recommended)
1. **Docker**: Docker Desktop or Docker Engine
2. **Internet Access**: For downloading PubNub C-Core and Docker images
3. **PubNub C-Core SDK**: Version 5.1.1 (automatically downloaded)

### For Legacy POSIX Build
1. **C Compiler**: GCC or Clang
2. **Make**: GNU Make or compatible
3. **PubNub C-Core SDK**: Version 5.1.0 or 5.1.1 to reproduce the bug

## Quick Setup

### Option 1: Docker-based FreeRTOS/mbedTLS Build (Recommended)

This approach uses Docker to create a consistent Alpine Linux environment with mbedTLS and FreeRTOS simulation.

1. **Build and test automatically**:
   ```bash
   # Downloads PubNub C-Core v5.1.1, builds Docker container, and compiles
   ./setup_and_test.sh
   
   # Run the FreeRTOS/mbedTLS reproduction test
   ./setup_and_test.sh --run
   ```

2. **Manual Docker execution**:
   ```bash
   # Build Docker image
   docker build -t pubnub-freertos-mbedtls .
   
   # Run the test
   docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c \
     'cd /app/pubnub-c-core/posix && ./pubnub_subscribe_bug_reproduction_freertos'
   ```

**Features**:
- **SSL/TLS Support**: Enabled via mbedTLS libraries
- **FreeRTOS Simulation**: POSIX thread-based compatibility
- **Alpine Linux**: Lightweight container environment
- **Consistent Build**: Same environment across all platforms

### Option 2: Using the Provided Makefile (Legacy POSIX)

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

### Option 3: Manual Compilation (Legacy POSIX)

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

### Option 4: Using PubNub's Build System (Legacy POSIX)

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

### FreeRTOS/mbedTLS Build Flags (Docker)
- `-DPUBNUB_USE_SSL=1`: Enable SSL/TLS support
- `-DFREERTOS_SIMULATION=1`: Enable FreeRTOS simulation mode
- `-lmbedtls -lmbedx509 -lmbedcrypto`: Link with mbedTLS libraries
- `-DPUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE`: Enable trace logging
- `-lpthread`: POSIX threads for FreeRTOS simulation

### Legacy POSIX Build Flags
- `-std=c99`: Use C99 standard
- `-Wall -Wextra`: Enable comprehensive warnings
- `-g`: Include debug information
- `-O0`: Disable optimizations for debugging
- `-lpthread`: Link with pthread library (required for PubNub C-Core)

## Testing Different Environments

### FreeRTOS/mbedTLS Environment (Docker)
The Docker-based approach automatically uses PubNub C-Core v5.1.1 with FreeRTOS simulation and mbedTLS:

```bash
# Test FreeRTOS/mbedTLS environment
./setup_and_test.sh --run

# Or manually with Docker
docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c \
  'cd /app/pubnub-c-core/posix && ./pubnub_subscribe_bug_reproduction_freertos'
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

### FreeRTOS/mbedTLS Environment (Docker)
**Current Status**: Working correctly (no hanging observed)
- `pubnub_subscribe()` returns `PNR_STARTED` (14) immediately
- `pubnub_await()` completes with `PNR_OK` (0)
- SSL/TLS capabilities available via mbedTLS
- Program finishes within 1 second
- Both subscribe and publish operations work

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

### FreeRTOS/mbedTLS Debug (Docker)
1. **Enable verbose logging**: The program sets `PUBNUB_LOG_LEVEL_TRACE` by default

2. **Access Docker container for debugging**:
   ```bash
   # Interactive shell in container
   docker run --rm -it -v "$(pwd):/app" pubnub-freertos-mbedtls sh
   
   # Check mbedTLS libraries
   ldd /app/pubnub-c-core/posix/pubnub_subscribe_bug_reproduction_freertos
   
   # Check SSL/TLS configuration
   grep -r "mbedtls" /app/pubnub-c-core/
   ```

3. **Docker build debugging**:
   ```bash
   # Rebuild Docker image with verbose output
   docker build --no-cache -t pubnub-freertos-mbedtls .
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

#### Docker Environment (All Platforms)
- **macOS**: Docker Desktop for Mac required
- **Linux**: Docker Engine or Docker Desktop
- **Windows**: Docker Desktop for Windows (WSL2 recommended)
- **Container**: Alpine Linux with mbedTLS (platform-independent)

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

## Docker Environment Details

### Container Specifications
- **Base Image**: Alpine Linux (latest)
- **SSL/TLS Library**: mbedTLS 3.6.x
- **FreeRTOS**: Simulation using POSIX threads
- **Compiler**: GCC with Alpine Linux
- **Size**: ~321 MiB (includes development tools)

### Build Process
1. Downloads Alpine Linux base image
2. Installs build tools and mbedTLS development libraries
3. Copies project files into container
4. Creates build script for FreeRTOS/mbedTLS compilation
5. Downloads PubNub C-Core v5.1.1 during build
6. Compiles with SSL/TLS and FreeRTOS simulation enabled

### Security Notes
- Container runs as root (standard for build containers)
- No sensitive data is stored in the container
- Network access only for downloading PubNub C-Core
- Container is removed after each run (`--rm` flag)