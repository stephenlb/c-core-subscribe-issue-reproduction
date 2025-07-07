# PubNub C-Core Subscribe Bug Reproduction - Compilation Instructions

## Prerequisites

1. **C Compiler**: GCC or Clang
2. **Make**: GNU Make or compatible
3. **PubNub C-Core SDK**: Version 5.1.0 or 5.1.1 to reproduce the bug

## Quick Setup

### Option 1: Using the Provided Makefile (Recommended)

1. **Download PubNub C-Core**:
   ```bash
   # Clone the repository
   git clone https://github.com/pubnub/c-core.git pubnub-c-core
   
   # Or download a specific version
   wget https://github.com/pubnub/c-core/archive/v5.1.0.tar.gz
   tar -xzf v5.1.0.tar.gz
   mv c-core-5.1.0 pubnub-c-core
   ```

2. **Compile the reproduction program**:
   ```bash
   make
   ```

3. **Run the reproduction test**:
   ```bash
   ./pubnub_subscribe_bug_reproduction
   ```

### Option 2: Manual Compilation

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

### Option 3: Using PubNub's Build System

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

- `-std=c99`: Use C99 standard
- `-Wall -Wextra`: Enable comprehensive warnings
- `-g`: Include debug information
- `-O0`: Disable optimizations for debugging
- `-lpthread`: Link with pthread library (required for PubNub C-Core)

## Testing Different Versions

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

### Working Version (v5.0.3)
- `pubnub_subscribe()` should return `PNR_STARTED` immediately
- `pubnub_await()` should complete normally
- The program should finish within a few seconds

### Broken Version (v5.1.0, v5.1.1)
- `pubnub_subscribe()` may never return (hangs indefinitely)
- The program will appear to freeze after "Step 6: Calling pubnub_subscribe..."
- You may need to use Ctrl+C to terminate the program

## Debugging Tips

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

- **macOS**: May need to install Xcode command line tools
- **Linux**: Ensure build-essential is installed
- **Windows**: Use MinGW or similar POSIX-compatible environment

## Clean Up

To clean up build artifacts:
```bash
make clean
```

To remove all downloaded files:
```bash
rm -rf pubnub-c-core*
```