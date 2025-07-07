#ifndef ESP_SYSTEM_H
#define ESP_SYSTEM_H

#include <stdint.h>
#include <stdlib.h>

// ESP32 system simulation
static inline uint32_t esp_get_free_heap_size(void) {
    return 200000; // Simulate 200KB free heap
}

#endif
