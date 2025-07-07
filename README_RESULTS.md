# PubNub C-Core v5.1.0 Subscribe Bug Reproduction - Test Results

## Overview

Reproduction case for the reported PubNub C-Core v5.1.0 subscribe bug.

## Files

1. **`pubnub_subscribe_bug_reproduction.c`** - Main reproduction program
2. **`Makefile`** - Build configuration
3. **`COMPILE_INSTRUCTIONS.md`** - Detailed compilation instructions
4. **`setup_and_test.sh`** - Automated setup script

## Test Results

### Working Build (v5.1.0 without Subscribe Event Engine)

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

### Different Behavior with Subscribe Event Engine

When compiled with `USE_SUBSCRIBE_EVENT_ENGINE=1`:
```bash
cc -opubnub_subscribe_bug_reproduction_v2 -Wall -I.. -I. -I../lib/base64 -I../posix \
   -D PUBNUB_USE_SUBSCRIBE_EVENT_ENGINE=1 \
   ../core/samples/pubnub_subscribe_bug_reproduction.c pubnub_sync.a -lpthread
```

**Result**: Different behavior observed
- `pubnub_subscribe()` still returns `PNR_STARTED` (14)
- But the flow behaves differently with the event engine

## Code Functionality

The reproduction program:

1. ✅ Follows function call sequence:
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

## Possible Explanations Bug

1. **Subscribe Event Engine**: The new subscribe event engine in v5.1.0 might have different behavior patterns
2. **Specific Build Configuration**: Different compile-time flags might trigger the bug
3. **Network Conditions**: The issue might be network-dependent
4. **Threading Model**: The issue might be related to specific threading configurations

## How to Use the Reproduction Case

### Quick Test
```bash
./setup_and_test.sh --run
```

### Manual Compilation
```bash
# Download PubNub C-Core v5.1.0
git clone https://github.com/pubnub/c-core.git pubnub-c-core
cd pubnub-c-core && git checkout v5.1.0

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

### My Test Results
- `pubnub_subscribe()` returns `PNR_STARTED` immediately
- `pubnub_await()` completes successfully
- Full trace logging shows normal operation

## Recommendations for Further Investigation

1. **Test with Exact Build Configuration**: Try building with compiler flags and configuration
2. **Network Environment**: Test network environment
3. **Threading Configuration**: Verify `PUBNUB_THREADSAFE` and other threading settings
4. **Subscribe Event Engine**: Test with and without the new subscribe event engine
5. **Platform Differences**: Test specific platform (Linux/embedded vs macOS)

## Working Files

All files are ready to use:
- ✅ Reproduction program compiles and runs successfully
- ✅ Includes comprehensive debugging and logging
- ✅ Has timeout protection to prevent infinite hanging
- ✅ Can be easily modified to test different scenarios
