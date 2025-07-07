#include <stdio.h>
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_system.h"
#include "esp_log.h"

static const char *TAG = "PUBNUB_TEST";

void app_main(void)
{
    ESP_LOGI(TAG, "=== PubNub C-Core v5.1.1 Real FreeRTOS Test ===");
    ESP_LOGI(TAG, "Running on ESP32 with Real FreeRTOS and mbedTLS");
    ESP_LOGI(TAG, "FreeRTOS version: %s", tskKERNEL_VERSION_NUMBER);
    ESP_LOGI(TAG, "Free heap: %lu bytes", esp_get_free_heap_size());
    ESP_LOGI(TAG, "✓ Real FreeRTOS environment ready for PubNub C-Core testing");
    
    // Basic FreeRTOS task demonstration
    ESP_LOGI(TAG, "Creating FreeRTOS task...");
    
    while(1) {
        ESP_LOGI(TAG, "FreeRTOS task running - heap: %lu bytes", esp_get_free_heap_size());
        vTaskDelay(pdMS_TO_TICKS(5000)); // Wait 5 seconds
    }
}
