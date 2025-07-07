#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>

// Include the PubNub sync header - adjust path for root directory build
#include "pubnub-c-core/posix/pubnub_sync.h"

// For HTTP keep-alive
#include "pubnub-c-core/core/pubnub_helper.h"

// For timers
#include "pubnub-c-core/core/pubnub_timers.h"

// For logging
#include "pubnub-c-core/core/pubnub_log.h"

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
    printf("=== PubNub C-Core v5.1.0 Subscribe Bug Reproduction ===\n");
    
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
    
    // Enable trace logging to see what's happening
    print_timestamp();
    printf("Setting log level to TRACE...\n");
    pubnub_set_log_level(PUBNUB_LOG_LEVEL_TRACE);
    
    // Step 5: pubnub_subscribe - THIS IS WHERE THE BUG OCCURS
    print_timestamp();
    printf("Step 5: Calling pubnub_subscribe with comma-separated channels...\n");
    printf("Channels: 'test_channel_1,test_channel_2'\n");
    printf("Channel Group: NULL\n");
    printf("This call should return immediately but may hang in v5.1.0...\n");
    
    // Set a timeout to prevent infinite hanging
    pubnub_set_transaction_timeout(ctx, 10000); // 10 seconds
    
    // The problematic call - this is supposed to return immediately but hangs in v5.1.0
    pbresult = pubnub_subscribe(ctx, "test_channel_1,test_channel_2", NULL);
    
    print_timestamp();
    printf("pubnub_subscribe returned with result: %d\n", pbresult);
    
    if (pbresult == PNR_STARTED) {
        print_timestamp();
        printf("Subscribe started successfully, now calling pubnub_await...\n");
        
        // Step 6: pubnub_await
        print_timestamp();
        printf("Step 6: Calling pubnub_await...\n");
        pbresult = pubnub_await(ctx);
        
        print_timestamp();
        printf("pubnub_await returned with result: %d\n", pbresult);
        
        if (pbresult == PNR_OK) {
            print_timestamp();
            printf("✓ Subscribe completed successfully\n");
            
            // Step 7: pubnub_get
            print_timestamp();
            printf("Step 7: Retrieving messages with pubnub_get...\n");
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
            printf("ERROR: pubnub_await failed with result: %d\n", pbresult);
            
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
        printf("ERROR: pubnub_subscribe failed immediately with result: %d\n", pbresult);
        
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
    
    if (pbresult == PNR_STARTED) {
        print_timestamp();
        printf("Publish started, awaiting result...\n");
        pbresult = pubnub_await(ctx);
        
        if (pbresult == PNR_OK) {
            print_timestamp();
            printf("✓ Publish completed successfully - connection is working\n");
        } else {
            print_timestamp();
            printf("ERROR: Publish failed with result: %d\n", pbresult);
        }
    } else {
        print_timestamp();
        printf("ERROR: Publish failed immediately with result: %d\n", pbresult);
    }
    
    // Cleanup
    print_timestamp();
    printf("Cleaning up...\n");
    pubnub_free(ctx);
    global_ctx = NULL;
    
    print_timestamp();
    printf("=== Bug reproduction test completed ===\n");
    
    return 0;
}
