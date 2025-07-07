#ifndef ESP_LOG_H
#define ESP_LOG_H

#include <stdio.h>
#include <time.h>

// ESP32 logging simulation
#define ESP_LOGI(tag, format, ...) do { \
    time_t now = time(NULL); \
    struct tm *tm_info = localtime(&now); \
    char timestamp[26]; \
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info); \
    printf("[%s] I (%s): " format "\n", timestamp, tag, ##__VA_ARGS__); \
} while(0)

#define ESP_LOGE(tag, format, ...) do { \
    time_t now = time(NULL); \
    struct tm *tm_info = localtime(&now); \
    char timestamp[26]; \
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%d %H:%M:%S", tm_info); \
    printf("[%s] E (%s): " format "\n", timestamp, tag, ##__VA_ARGS__); \
} while(0)

#endif
