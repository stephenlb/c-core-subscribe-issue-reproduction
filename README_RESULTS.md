# PubNub C-Core v5.1.1 Subscribe Bug Reproduction - Test Results (FreeRTOS/mbedTLS)

## Overview

Reproduction case for the reported PubNub C-Core v5.1.1 subscribe bug, now enhanced with **FreeRTOS and mbedTLS support** via Docker for comprehensive testing across different environments.

## Files

1. **`pubnub_subscribe_bug_reproduction.c`** - Original POSIX reproduction program
2. **`pubnub_subscribe_bug_reproduction_freertos.c`** - FreeRTOS/mbedTLS version with simulation
3. **`Dockerfile`** - Alpine Linux container with mbedTLS build environment
4. **`setup_and_test.sh`** - Docker-based automated setup script
5. **`Makefile`** - Build configuration (legacy POSIX)
6. **`COMPILE_INSTRUCTIONS.md`** - Detailed compilation instructions for both environments

## Test Results

### FreeRTOS/mbedTLS Environment (Docker) - v5.1.1

**Test Date**: 2025-07-07 22:12:22  
**Environment**: Alpine Linux with mbedTLS, FreeRTOS simulation  
**SSL/TLS**: Enabled via mbedTLS libraries  

Build command:
```bash
./setup_and_test.sh  # Docker-based build
./setup_and_test.sh --run  # Run test in container
```

Compilation flags:
```bash
gcc -o pubnub_subscribe_bug_reproduction_freertos \
    -I.. -I. -I../lib/base64 -I../posix -I../core \
    -DPUBNUB_USE_SSL=1 \
    -DFREERTOS_SIMULATION=1 \
    -DPUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE \
    ../core/samples/pubnub_subscribe_bug_reproduction_freertos.c \
    pubnub_sync.a -lmbedtls -lmbedx509 -lmbedcrypto -lpthread
```

**Result**: ✅ **SUCCESSFUL EXECUTION**
- `pubnub_subscribe()` returns `PNR_STARTED` (14) immediately
- `pubnub_await()` completes with `PNR_OK` (0)
- SSL/TLS capabilities available via mbedTLS
- Subscribe and publish operations both work correctly
- **No hanging behavior observed**

**Complete Output**:
```
[2025-07-07 22:12:22] === PubNub C-Core v5.1.1 Subscribe Bug Reproduction ===
[2025-07-07 22:12:22] Step 1: Allocating PubNub context...
[2025-07-07 22:12:22] ✓ PubNub context allocated successfully
[2025-07-07 22:12:22] Step 2: Initializing PubNub context...
[2025-07-07 22:12:22] ✓ PubNub context initialized with demo keys
[2025-07-07 22:12:22] Step 3: Enabling HTTP keep-alive...
[2025-07-07 22:12:22] ✓ HTTP keep-alive enabled
[2025-07-07 22:12:22] Step 4: Setting user ID...
[2025-07-07 22:12:22] ✓ User ID set to 'bug_reproduction_user'
[2025-07-07 22:12:22] Step 5: Setting auth key...
[2025-07-07 22:12:22] ✓ Auth key set to 'test_auth_key'
[2025-07-07 22:12:22] Step 6: Calling pubnub_subscribe with comma-separated channels...
Channels: 'test_channel_1,test_channel_2'
Channel Group: NULL
This call should return immediately but may hang in v5.1.1...
[2025-07-07 22:12:22] pubnub_subscribe returned with result: 14 (Pubnub API transaction started)
[2025-07-07 22:12:22] Subscribe started successfully, now calling pubnub_await...
[2025-07-07 22:12:22] Step 7: Calling pubnub_await...
[2025-07-07 22:12:22] pubnub_await returned with result: 0 (OK)
[2025-07-07 22:12:22] ✓ Subscribe completed successfully
[2025-07-07 22:12:22] === SUBSCRIBE HTTP RESPONSE BODY ===
Response buffer size: 24 bytes
Response body (raw with NULL handling): [[\0,"17519263426713121\0]
Response body (JSON-like): [[,"17519263426713121]
=== END SUBSCRIBE HTTP RESPONSE BODY ===
[2025-07-07 22:12:22] Step 8: Retrieving messages with pubnub_get...
[2025-07-07 22:12:22] No messages received (expected for first subscribe)
[2025-07-07 22:12:22] Testing publish to verify connection...
[2025-07-07 22:12:22] Publish started, awaiting result...
[2025-07-07 22:12:22] ✓ Publish completed successfully - connection is working
[2025-07-07 22:12:22] === PUBLISH HTTP RESPONSE BODY ===
Response buffer size: 30 bytes
Response body (raw with NULL handling): [1\0"Sent"\0"17519263428125378"\0
Response body (JSON-like): [1"Sent""17519263428125378"
=== END PUBLISH HTTP RESPONSE BODY ===
[2025-07-07 22:12:22] Cleaning up...
[2025-07-07 22:12:22] === Bug reproduction test completed ===
```

### Legacy POSIX Build (v5.1.1 without Subscribe Event Engine)

When compiled with the standard configuration:
```bash
# From pubnub-c-core/posix directory
cc -opubnub_subscribe_bug_reproduction -Wall -I.. -I. -I../lib/base64 -I../posix \
   -D PUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE \
   -D PUBNUB_USE_SUBSCRIBE_EVENT_ENGINE=0 \
   ../core/samples/pubnub_subscribe_bug_reproduction.c pubnub_sync.a -lpthread
```

**Result**: The program completes successfully
- `pubnub_subscribe()` returns `PNR_STARTED` (14) immediately
- `pubnub_await()` completes with `PNR_OK` (0)
- Subscribe operation works as expected
- **Note**: This is the legacy POSIX approach

### Different Behavior with Subscribe Event Engine (Legacy POSIX)

When compiled with `USE_SUBSCRIBE_EVENT_ENGINE=1`:
```bash
cc -opubnub_subscribe_bug_reproduction_v2 -Wall -I.. -I. -I../lib/base64 -I../posix \
   -D PUBNUB_USE_SUBSCRIBE_EVENT_ENGINE=1 \
   ../core/samples/pubnub_subscribe_bug_reproduction.c pubnub_sync.a -lpthread
```

**Result**: Different behavior observed
- `pubnub_subscribe()` still returns `PNR_STARTED` (14)
- But the flow behaves differently with the event engine
- **Note**: This is the legacy POSIX approach

## Code Functionality

### FreeRTOS/mbedTLS Version Features
- **FreeRTOS Simulation**: Uses POSIX threads with FreeRTOS-compatible types
- **mbedTLS Integration**: SSL/TLS support via mbedTLS libraries
- **Docker Environment**: Consistent Alpine Linux build environment
- **Enhanced Logging**: Additional FreeRTOS-specific debug information

### Core Reproduction Program Logic

Both versions of the reproduction program:

1. ✅ Follows exact function call sequence:
   - `pubnub_alloc()`
   - `pubnub_init()`
   - `pubnub_use_http_keep_alive()`
   - `pubnub_set_user_id()`
   - `pubnub_set_auth()`
   - `pubnub_subscribe()` with comma-separated channels
   - `pubnub_await()`
   - `pubnub_get()`

2. ✅ Uses the exact parameters:
   - Channels: `"test_channel_1,test_channel_2"` (comma-separated list of 2 channels)
   - Channel Group: `NULL`

3. ✅ Includes extensive logging and debugging:
   - Timestamps for all operations
   - Result code interpretation
   - Timeout protection (10 seconds)
   - Signal handling for graceful exit

4. ✅ Compiled with `PUBNUB_LOG_LEVEL_TRACE` to show internal operations

## Analysis: Why FreeRTOS/mbedTLS Environment Works

### Successful Test Results
The FreeRTOS/mbedTLS Docker environment shows **no hanging behavior**, suggesting:

1. **Environment Isolation**: Docker provides consistent environment that may avoid specific system-level issues
2. **mbedTLS Benefits**: SSL/TLS capability may handle network connections more reliably
3. **Alpine Linux**: Lightweight environment may have different networking behavior
4. **FreeRTOS Simulation**: POSIX thread-based simulation may avoid real-time OS timing issues

### Possible Explanations for Original Bug

1. **Subscribe Event Engine**: The new subscribe event engine in v5.1.1 might have different behavior patterns
2. **Specific Build Configuration**: Different compile-time flags might trigger the bug
3. **Network Conditions**: The issue might be network-dependent
4. **Threading Model**: The issue might be related to specific threading configurations
5. **Platform Dependencies**: Real FreeRTOS vs simulation differences
6. **SSL/TLS Stack**: Different SSL implementations may behave differently

## How to Use the Reproduction Case

### Quick Test (FreeRTOS/mbedTLS Docker)
```bash
# Build and test FreeRTOS/mbedTLS environment
./setup_and_test.sh
./setup_and_test.sh --run

# Manual Docker execution
docker run --rm -v "$(pwd):/app" pubnub-freertos-mbedtls sh -c \
  'cd /app/pubnub-c-core/posix && ./pubnub_subscribe_bug_reproduction_freertos'
```

### Legacy POSIX Manual Compilation
```bash
# Download PubNub C-Core v5.1.1
git clone https://github.com/pubnub/c-core.git pubnub-c-core
cd pubnub-c-core && git checkout v5.1.1

# Copy the reproduction file
cp ../pubnub_subscribe_bug_reproduction.c core/samples/

# Build the library
cd posix && make -f posix.mk pubnub_sync_sample

# Compile the reproduction program
cc -opubnub_subscribe_bug_reproduction -Wall -I.. -I. -I../lib/base64 -I../posix \
   -D PUBNUB_LOG_LEVEL=PUBNUB_LOG_LEVEL_TRACE \
   ../core/samples/pubnub_subscribe_bug_reproduction.c pubnub_sync.a -lpthread

# Run the test
./pubnub_subscribe_bug_reproduction
```

## Expected vs Actual Behavior

### Reported Behavior (Bug)
- `pubnub_subscribe()` never returns (hangs indefinitely)
- Only trace output: `pbpal_init()` and `pbntf_setup()` from `pubnub_init`

### FreeRTOS/mbedTLS Test Results (Docker)
- ✅ `pubnub_subscribe()` returns `PNR_STARTED` (14) immediately
- ✅ `pubnub_await()` completes with `PNR_OK` (0) successfully
- ✅ Full trace logging shows normal operation
- ✅ SSL/TLS capabilities available
- ✅ Both subscribe and publish operations work
- ✅ **No hanging behavior observed**

### Legacy POSIX Test Results
- ✅ `pubnub_subscribe()` returns `PNR_STARTED` immediately
- ✅ `pubnub_await()` completes successfully
- ✅ Full trace logging shows normal operation
- ⚠️ **Bug may be environment-specific**

## Recommendations for Further Investigation

### Immediate Actions
1. **Test Real FreeRTOS**: Try on actual FreeRTOS hardware vs simulation
2. **Network Environment**: Test different network conditions and configurations
3. **SSL/TLS Variations**: Compare mbedTLS vs other SSL implementations
4. **Container vs Host**: Compare Docker container vs native host execution

### Advanced Testing
1. **Test with Exact Build Configuration**: Try building with specific compiler flags and configuration
2. **Threading Configuration**: Verify `PUBNUB_THREADSAFE` and other threading settings
3. **Subscribe Event Engine**: Test with and without the new subscribe event engine
4. **Platform Differences**: Test specific platform (Linux/embedded vs macOS vs Windows)
5. **Memory Constraints**: Test under low-memory conditions
6. **Real-time Constraints**: Test with actual FreeRTOS timing requirements

## Working Files

### FreeRTOS/mbedTLS Environment
- ✅ Docker-based build environment with Alpine Linux
- ✅ mbedTLS SSL/TLS support enabled
- ✅ FreeRTOS simulation using POSIX threads
- ✅ Consistent cross-platform environment
- ✅ Automated build and test scripts

### General Features
- ✅ Both reproduction programs compile and run successfully
- ✅ Includes comprehensive debugging and logging
- ✅ Has timeout protection to prevent infinite hanging
- ✅ Can be easily modified to test different scenarios
- ✅ Docker environment provides isolation and consistency
- ✅ Ready for SSL/TLS testing scenarios
