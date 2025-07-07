// FreeRTOS simulation - using POSIX headers for compatibility
#ifdef FREERTOS_SIMULATION
#include <pthread.h>
#define FREERTOS_H
// Mock FreeRTOS types for build compatibility
typedef struct { int dummy; } TaskHandle_t;
typedef struct { int dummy; } SemaphoreHandle_t;
#else
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/semphr.h"
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

// Include the PubNub sync header - using POSIX for FreeRTOS simulation
#include "pubnub_sync.h"

// For HTTP keep-alive
#include "core/pubnub_helper.h"

// For timers
#include "core/pubnub_timers.h"

// For logging
#include "core/pubnub_log.h"

// For HTTP response access
#include "core/pubnub_coreapi.h"
#include "core/pubnub_memory_block.h"

// Global variables for signal handling
static volatile int should_exit = 0;
static pubnub_t *global_ctx = NULL;

// Signal handler for graceful exit
void signal_handler(int sig) {
    printf("\nReceived signal %d, attempting to cancel...\n", sig);
    should_exit = 1;
    if (global_ctx) {
        pubnub_cancel(global_ctx);
    }
}

// Function to print current time
void print_timestamp() {
    time_t now;
    struct tm *tm_info;
    char timestamp[26];
    
    time(&now);
    tm_info = localtime(&now);
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info);
    printf("[%s] ", timestamp);
}

int main() {
    enum pubnub_res pbresult;
    char const *message;
    int retry_count = 0;
    const int MAX_RETRIES = 3;
    
    // Set up signal handlers
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);
    
    print_timestamp();
    printf("=== PubNub C-Core v5.1.1 Subscribe Bug Reproduction ===\n");
    
    // Step 1: pubnub_alloc
    print_timestamp();
    printf("Step 1: Allocating PubNub context...\n");
    pubnub_t *ctx = pubnub_alloc();
    if (NULL == ctx) {
        printf("ERROR: Couldn't allocate a PubNub context\n");
        return -1;
    }
    global_ctx = ctx;
    print_timestamp();
    printf("✓ PubNub context allocated successfully\n");
    
    // Step 2: pubnub_init
    print_timestamp();
    printf("Step 2: Initializing PubNub context...\n");
    pubnub_init(ctx, "demo", "demo");
    print_timestamp();
    printf("✓ PubNub context initialized with demo keys\n");
    
    // Step 3: pubnub_use_http_keep_alive
    print_timestamp();
    printf("Step 3: Enabling HTTP keep-alive...\n");
    pubnub_use_http_keep_alive(ctx);
    print_timestamp();
    printf("✓ HTTP keep-alive enabled\n");
    
    // Step 4: pubnub_set_user_id
    print_timestamp();
    printf("Step 4: Setting user ID...\n");
    pubnub_set_user_id(ctx, "bug_reproduction_user");
    print_timestamp();
    printf("✓ User ID set to 'bug_reproduction_user'\n");
    
    // Step 5: pubnub_set_auth
    print_timestamp();
    printf("Step 5: Setting auth key...\n");
    pubnub_set_auth(ctx, "test_auth_key");
    print_timestamp();
    printf("✓ Auth key set to 'test_auth_key'\n");
    
    // Enable trace logging to see what's happening
    print_timestamp();
    printf("Setting log level to TRACE...\n");
    printf("Log level set to TRACE at compile time...\n");
    printf("Log level set to TRACE at compile time...\n");
    printf("Expected trace logs for pubnub_init should show only:\n");
    printf("  - pbpal_init()\n");
    printf("  - pbntf_setup()\n");
    printf("If you see more logs, the environment differs from the bug report.\n");
    
    // Step 6: pubnub_subscribe - THIS IS WHERE THE BUG OCCURS
    print_timestamp();
    printf("Step 6: Calling pubnub_subscribe with comma-separated channels...\n");
    printf("Channels: 'test_channel_1,test_channel_2'\n");
    printf("Channel Group: NULL\n");
    printf("This call should return immediately but may hang in v5.1.1...\n");
    
    // Set a timeout to prevent infinite hanging
    pubnub_set_transaction_timeout(ctx, 10000); // 10 seconds
    
    // The problematic call - this is supposed to return immediately but hangs in v5.1.0
    pbresult = pubnub_subscribe(ctx, "test_channel_1,test_channel_2", NULL);
    
    print_timestamp();
    printf("pubnub_subscribe returned with result: %d (%s)\n", pbresult, pubnub_res_2_string(pbresult));
    
    if (pbresult == PNR_STARTED) {
        print_timestamp();
        printf("Subscribe started successfully, now calling pubnub_await...\n");
        
        // Step 7: pubnub_await
        print_timestamp();
        printf("Step 7: Calling pubnub_await...\n");
        pbresult = pubnub_await(ctx);
        
        print_timestamp();
        printf("pubnub_await returned with result: %d (%s)\n", pbresult, pubnub_res_2_string(pbresult));
        
        if (pbresult == PNR_OK) {
            print_timestamp();
            printf("✓ Subscribe completed successfully\n");
            
            // Print full HTTP response body from subscribe
            print_timestamp();
            printf("=== SUBSCRIBE HTTP RESPONSE BODY ===\n");
            pubnub_chamebl_t response_body;
            int result = pubnub_last_http_response_body(ctx, &response_body);
            if (result == 0 && response_body.ptr != NULL) {
                printf("Response buffer size: %zu bytes\n", response_body.size);
                printf("Response body (raw with NULL handling): ");
                for (size_t i = 0; i < response_body.size; i++) {
                    char c = response_body.ptr[i];
                    if (c == '\0') {
                        printf("\\0");  // Show NULL as literal \0
                    } else if (c == '\n') {
                        printf("\\n");
                    } else if (c == '\r') {
                        printf("\\r");
                    } else if (c == '\t') {
                        printf("\\t");
                    } else if (c >= 32 && c <= 126) {
                        printf("%c", c);  // Printable ASCII
                    } else {
                        printf("\\x%02x", (unsigned char)c);  // Non-printable as hex
                    }
                }
                printf("\n");
                // Also try to reconstruct as proper JSON by replacing NULLs with spaces
                printf("Response body (JSON-like): ");
                for (size_t i = 0; i < response_body.size; i++) {
                    char c = response_body.ptr[i];
                    if (c == '\0') {
                        // Skip NULL characters entirely
                        continue;
                    } else {
                        printf("%c", c);
                    }
                }
                printf("\n");
            } else {
                printf("No response body available (result: %d)\n", result);
            }
            printf("=== END SUBSCRIBE HTTP RESPONSE BODY ===\n");
            
            // Step 8: pubnub_get
            print_timestamp();
            printf("Step 8: Retrieving messages with pubnub_get...\n");
            message = pubnub_get(ctx);
            int message_count = 0;
            while (message != NULL) {
                message_count++;
                print_timestamp();
                printf("Message %d: %s\n", message_count, message);
                message = pubnub_get(ctx);
            }
            
            if (message_count == 0) {
                print_timestamp();
                printf("No messages received (expected for first subscribe)\n");
            }
            
        } else {
            print_timestamp();
            printf("ERROR: pubnub_await failed with result: %d (%s)\n", pbresult, pubnub_res_2_string(pbresult));
            
            // Print error details
            switch(pbresult) {
                case PNR_TIMEOUT:
                    printf("  - Timeout occurred\n");
                    break;
                case PNR_CANCELLED:
                    printf("  - Operation was cancelled\n");
                    break;
                case PNR_STARTED:
                    printf("  - Operation is still in progress\n");
                    break;
                default:
                    printf("  - Unknown error code: %d\n", pbresult);
                    break;
            }
        }
        
    } else {
        print_timestamp();
        printf("ERROR: pubnub_subscribe failed immediately with result: %d (%s)\n", pbresult, pubnub_res_2_string(pbresult));
        
        // Print error details
        switch(pbresult) {
            case PNR_IN_PROGRESS:
                printf("  - Another transaction is in progress\n");
                break;
            case PNR_INVALID_CHANNEL:
                printf("  - Invalid channel name\n");
                break;
            default:
                printf("  - Unknown error code: %d\n", pbresult);
                break;
        }
    }
    
    // Test a simple publish to verify the connection works
    print_timestamp();
    printf("Testing publish to verify connection...\n");
    pbresult = pubnub_publish(ctx, "test_channel_1", "\"test message from bug reproduction\"");
    
    //if (pbresult == PNR_STARTED) {
        print_timestamp();
        printf("Publish started, awaiting result...\n");
        pbresult = pubnub_await(ctx);
        
        if (pbresult == PNR_OK) {
            print_timestamp();
            printf("✓ Publish completed successfully - connection is working\n");
            
            // Print full HTTP response body from publish
            print_timestamp();
            printf("=== PUBLISH HTTP RESPONSE BODY ===\n");
            pubnub_chamebl_t response_body;
            int result = pubnub_last_http_response_body(ctx, &response_body);
            if (result == 0 && response_body.ptr != NULL) {
                printf("Response buffer size: %zu bytes\n", response_body.size);
                printf("Response body (raw with NULL handling): ");
                for (size_t i = 0; i < response_body.size; i++) {
                    char c = response_body.ptr[i];
                    if (c == '\0') {
                        printf("\\0");  // Show NULL as literal \0
                    } else if (c == '\n') {
                        printf("\\n");
                    } else if (c == '\r') {
                        printf("\\r");
                    } else if (c == '\t') {
                        printf("\\t");
                    } else if (c >= 32 && c <= 126) {
                        printf("%c", c);  // Printable ASCII
                    } else {
                        printf("\\x%02x", (unsigned char)c);  // Non-printable as hex
                    }
                }
                printf("\n");
                // Also try to reconstruct as proper JSON by replacing NULLs with spaces
                printf("Response body (JSON-like): ");
                for (size_t i = 0; i < response_body.size; i++) {
                    char c = response_body.ptr[i];
                    if (c == '\0') {
                        // Skip NULL characters entirely
                        continue;
                    } else {
                        printf("%c", c);
                    }
                }
                printf("\n");
            } else {
                printf("No response body available (result: %d)\n", result);
            }
            printf("=== END PUBLISH HTTP RESPONSE BODY ===\n");
        } else {
            print_timestamp();
            printf("ERROR: Publish failed with result: %d (%s)\n", pbresult, pubnub_res_2_string(pbresult));
        }
    /*} else {
        print_timestamp();
        printf("ERROR: Publish failed immediately with result: %d (%s)\n", pbresult, pubnub_res_2_string(pbresult));
    }*/
    
    // Cleanup
    print_timestamp();
    printf("Cleaning up...\n");
    pubnub_free(ctx);
    global_ctx = NULL;
    
    print_timestamp();
    printf("=== Bug reproduction test completed ===\n");
    
    return 0;
}
