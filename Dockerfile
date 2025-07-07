# Dockerfile for PubNub C-Core Real FreeRTOS/mbedTLS Build Environment
FROM espressif/idf:release-v5.1

# Set working directory
WORKDIR /app

# Install additional dependencies for PubNub C-Core
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    tar \
    && rm -rf /var/lib/apt/lists/*

# Copy the project files
COPY . .

# Create ESP-IDF project structure and build script
RUN echo '#!/bin/bash\n\
set -e\n\
echo "=== Building PubNub C-Core with Real FreeRTOS/mbedTLS (ESP-IDF) ==="\n\
cd /app\n\
\n\
# Check if pubnub-c-core exists, if not download it\n\
if [ ! -d "pubnub-c-core" ]; then\n\
    echo "Downloading PubNub C-Core v5.1.1..."\n\
    wget -q https://github.com/pubnub/c-core/archive/refs/tags/v5.1.1.tar.gz\n\
    tar -xzf v5.1.1.tar.gz\n\
    mv c-core-5.1.1 pubnub-c-core\n\
    rm v5.1.1.tar.gz\n\
fi\n\
\n\
# Create ESP-IDF project structure\n\
if [ ! -d "esp_project" ]; then\n\
    echo "Creating ESP-IDF project structure..."\n\
    mkdir -p esp_project/main\n\
    mkdir -p esp_project/components/pubnub\n\
    \n\
    # Create main CMakeLists.txt\n\
    cat > esp_project/CMakeLists.txt << EOF\n\
cmake_minimum_required(VERSION 3.16)\n\
include($$ENV{IDF_PATH}/tools/cmake/project.cmake)\n\
project(pubnub_freertos_test)\n\
EOF\n\
    \n\
    # Create main component CMakeLists.txt\n\
    cat > esp_project/main/CMakeLists.txt << EOF\n\
idf_component_register(SRCS "main.c"\n\
                       INCLUDE_DIRS ".")\n\
EOF\n\
    \n\
    # Create PubNub component CMakeLists.txt\n\
    cat > esp_project/components/pubnub/CMakeLists.txt << EOF\n\
file(GLOB_RECURSE PUBNUB_SOURCES\n\
    "../../pubnub-c-core/core/*.c"\n\
    "../../pubnub-c-core/lib/*.c"\n\
    "../../pubnub-c-core/freertos/*.c"\n\
)\n\
\n\
idf_component_register(SRCS $${PUBNUB_SOURCES}\n\
                       INCLUDE_DIRS\n\
                       "../../pubnub-c-core/core"\n\
                       "../../pubnub-c-core/lib"\n\
                       "../../pubnub-c-core/freertos"\n\
                       "../../pubnub-c-core/lib/base64"\n\
                       REQUIRES mbedtls esp_wifi esp_netif nvs_flash)\n\
EOF\n\
    \n\
    # Create sdkconfig.defaults for FreeRTOS configuration\n\
    cat > esp_project/sdkconfig.defaults << EOF\n\
CONFIG_FREERTOS_HZ=1000\n\
CONFIG_ESP_TASK_WDT_TIMEOUT_S=10\n\
CONFIG_ESP_MAIN_TASK_STACK_SIZE=8192\n\
CONFIG_MBEDTLS_CERTIFICATE_BUNDLE=y\n\
CONFIG_MBEDTLS_SSL_PROTO_TLS1_2=y\n\
CONFIG_LWIP_MAX_SOCKETS=16\n\
CONFIG_LWIP_SO_REUSE=y\n\
CONFIG_LWIP_SO_RCVBUF=y\n\
CONFIG_ESP_WIFI_STATION_EXAMPLE_SSID="wifi_ssid"\n\
CONFIG_ESP_WIFI_STATION_EXAMPLE_PASSWORD="wifi_password"\n\
EOF\n\
fi\n\
\n\
# Create main.c with FreeRTOS reproduction program\n\
if [ -f "pubnub_subscribe_bug_reproduction_freertos.c" ]; then\n\
    echo "Adapting reproduction program for ESP-IDF/FreeRTOS..."\n\
    \n\
    # Create ESP-IDF compatible main.c\n\
    cat > esp_project/main/main.c << EOF\n\
#include <stdio.h>\n\
#include <string.h>\n\
#include <stdlib.h>\n\
#include <time.h>\n\
#include <sys/time.h>\n\
#include "freertos/FreeRTOS.h"\n\
#include "freertos/task.h"\n\
#include "freertos/semphr.h"\n\
#include "esp_system.h"\n\
#include "esp_wifi.h"\n\
#include "esp_event.h"\n\
#include "esp_log.h"\n\
#include "nvs_flash.h"\n\
#include "esp_netif.h"\n\
#include "esp_sntp.h"\n\
\n\
// Include PubNub headers\n\
#include "pubnub_alloc.h"\n\
#include "pubnub_ccore.h"\n\
#include "pubnub_netcore.h"\n\
#include "pubnub_assert.h"\n\
#include "pubnub_helper.h"\n\
#include "pubnub_timers.h"\n\
#include "pubnub_log.h"\n\
\n\
static const char *TAG = "PUBNUB_TEST";\n\
\n\
// WiFi credentials (configure in sdkconfig)\n\
#define WIFI_SSID CONFIG_ESP_WIFI_STATION_EXAMPLE_SSID\n\
#define WIFI_PASS CONFIG_ESP_WIFI_STATION_EXAMPLE_PASSWORD\n\
\n\
static EventGroupHandle_t s_wifi_event_group;\n\
#define WIFI_CONNECTED_BIT BIT0\n\
#define WIFI_FAIL_BIT      BIT1\n\
\n\
static void wifi_event_handler(void* arg, esp_event_base_t event_base,\n\
                              int32_t event_id, void* event_data)\n\
{\n\
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {\n\
        esp_wifi_connect();\n\
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {\n\
        esp_wifi_connect();\n\
        ESP_LOGI(TAG, "retry to connect to the AP");\n\
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {\n\
        ip_event_got_ip_t* event = (ip_event_got_ip_t*) event_data;\n\
        ESP_LOGI(TAG, "got ip:" IPSTR, IP2STR(&event->ip_info.ip));\n\
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);\n\
    }\n\
}\n\
\n\
static void wifi_init_sta(void)\n\
{\n\
    s_wifi_event_group = xEventGroupCreate();\n\
\n\
    ESP_ERROR_CHECK(esp_netif_init());\n\
    ESP_ERROR_CHECK(esp_event_loop_create_default());\n\
    esp_netif_create_default_wifi_sta();\n\
\n\
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();\n\
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));\n\
\n\
    esp_event_handler_instance_t instance_any_id;\n\
    esp_event_handler_instance_t instance_got_ip;\n\
    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,\n\
                                                        ESP_EVENT_ANY_ID,\n\
                                                        &wifi_event_handler,\n\
                                                        NULL,\n\
                                                        &instance_any_id));\n\
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,\n\
                                                        IP_EVENT_STA_GOT_IP,\n\
                                                        &wifi_event_handler,\n\
                                                        NULL,\n\
                                                        &instance_got_ip));\n\
\n\
    wifi_config_t wifi_config = {\n\
        .sta = {\n\
            .ssid = WIFI_SSID,\n\
            .password = WIFI_PASS,\n\
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,\n\
        },\n\
    };\n\
\n\
    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));\n\
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));\n\
    ESP_ERROR_CHECK(esp_wifi_start());\n\
\n\
    ESP_LOGI(TAG, "wifi_init_sta finished.");\n\
\n\
    EventBits_t bits = xEventGroupWaitBits(s_wifi_event_group,\n\
            WIFI_CONNECTED_BIT | WIFI_FAIL_BIT,\n\
            pdFALSE,\n\
            pdFALSE,\n\
            portMAX_DELAY);\n\
\n\
    if (bits & WIFI_CONNECTED_BIT) {\n\
        ESP_LOGI(TAG, "connected to ap SSID:%s", WIFI_SSID);\n\
    } else if (bits & WIFI_FAIL_BIT) {\n\
        ESP_LOGI(TAG, "Failed to connect to SSID:%s", WIFI_SSID);\n\
    }\n\
}\n\
\n\
static void pubnub_test_task(void *pvParameters)\n\
{\n\
    ESP_LOGI(TAG, "=== PubNub C-Core v5.1.1 Subscribe Bug Reproduction (Real FreeRTOS) ===");\n\
    \n\
    // Wait for WiFi connection\n\
    vTaskDelay(pdMS_TO_TICKS(2000));\n\
    \n\
    ESP_LOGI(TAG, "Step 1: Allocating PubNub context...");\n\
    pubnub_t *ctx = pubnub_alloc();\n\
    if (NULL == ctx) {\n\
        ESP_LOGE(TAG, "ERROR: Could not allocate a PubNub context");\n\
        vTaskDelete(NULL);\n\
        return;\n\
    }\n\
    ESP_LOGI(TAG, "✓ PubNub context allocated successfully");\n\
    \n\
    ESP_LOGI(TAG, "Step 2: Initializing PubNub context...");\n\
    pubnub_init(ctx, "demo", "demo");\n\
    ESP_LOGI(TAG, "✓ PubNub context initialized with demo keys");\n\
    \n\
    ESP_LOGI(TAG, "Step 3: Enabling HTTP keep-alive...");\n\
    pubnub_use_http_keep_alive(ctx);\n\
    ESP_LOGI(TAG, "✓ HTTP keep-alive enabled");\n\
    \n\
    ESP_LOGI(TAG, "Step 4: Setting user ID...");\n\
    pubnub_set_user_id(ctx, "bug_reproduction_user");\n\
    ESP_LOGI(TAG, "✓ User ID set to bug_reproduction_user");\n\
    \n\
    ESP_LOGI(TAG, "Step 5: Setting auth key...");\n\
    pubnub_set_auth(ctx, "test_auth_key");\n\
    ESP_LOGI(TAG, "✓ Auth key set to test_auth_key");\n\
    \n\
    ESP_LOGI(TAG, "Step 6: Calling pubnub_subscribe with comma-separated channels...");\n\
    ESP_LOGI(TAG, "Channels: test_channel_1,test_channel_2");\n\
    ESP_LOGI(TAG, "Channel Group: NULL");\n\
    ESP_LOGI(TAG, "This call should return immediately but may hang in v5.1.1...");\n\
    \n\
    // Set timeout to prevent infinite hanging\n\
    pubnub_set_transaction_timeout(ctx, 10000); // 10 seconds\n\
    \n\
    // The problematic call\n\
    enum pubnub_res pbresult = pubnub_subscribe(ctx, "test_channel_1,test_channel_2", NULL);\n\
    \n\
    ESP_LOGI(TAG, "pubnub_subscribe returned with result: %d", pbresult);\n\
    \n\
    if (pbresult == PNR_STARTED) {\n\
        ESP_LOGI(TAG, "Subscribe started successfully, now calling pubnub_await...");\n\
        \n\
        pbresult = pubnub_await(ctx);\n\
        ESP_LOGI(TAG, "pubnub_await returned with result: %d", pbresult);\n\
        \n\
        if (pbresult == PNR_OK) {\n\
            ESP_LOGI(TAG, "✓ Subscribe completed successfully");\n\
        } else {\n\
            ESP_LOGE(TAG, "ERROR: pubnub_await failed with result: %d", pbresult);\n\
        }\n\
    } else {\n\
        ESP_LOGE(TAG, "ERROR: pubnub_subscribe failed immediately with result: %d", pbresult);\n\
    }\n\
    \n\
    // Cleanup\n\
    pubnub_free(ctx);\n\
    ESP_LOGI(TAG, "=== Bug reproduction test completed ===");\n\
    \n\
    vTaskDelete(NULL);\n\
}\n\
\n\
void app_main(void)\n\
{\n\
    // Initialize NVS\n\
    esp_err_t ret = nvs_flash_init();\n\
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {\n\
        ESP_ERROR_CHECK(nvs_flash_erase());\n\
        ret = nvs_flash_init();\n\
    }\n\
    ESP_ERROR_CHECK(ret);\n\
\n\
    ESP_LOGI(TAG, "ESP_WIFI_MODE_STA");\n\
    wifi_init_sta();\n\
\n\
    // Create PubNub test task\n\
    xTaskCreate(pubnub_test_task, "pubnub_test", 8192, NULL, 5, NULL);\n\
}\n\
EOF\n\
fi\n\
\n\
# Build the ESP-IDF project\n\
cd esp_project\n\
echo "Building ESP-IDF project with real FreeRTOS and mbedTLS..."\n\
\n\
# Set ESP32 as target\n\
idf.py set-target esp32\n\
\n\
# Build the project\n\
idf.py build\n\
\n\
echo "✓ Real FreeRTOS build completed successfully"\n\
echo "✓ Binary ready: build/pubnub_freertos_test.bin"\n\
echo "✓ Flash with: idf.py flash -p /dev/ttyUSB0 monitor"\n\
' > /app/build_real_freertos.sh

# Make the build script executable
RUN chmod +x /app/build_real_freertos.sh

# Default command
CMD ["/app/build_real_freertos.sh"]