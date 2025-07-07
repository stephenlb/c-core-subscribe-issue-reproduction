#ifndef FREERTOS_H
#define FREERTOS_H

#include <pthread.h>
#include <unistd.h>
#include <stdint.h>

// FreeRTOS simulation using POSIX threads
#define pdTRUE 1
#define pdFALSE 0
#define portMAX_DELAY 0xFFFFFFFF
#define pdMS_TO_TICKS(ms) (ms)

typedef void* TaskHandle_t;
typedef uint32_t TickType_t;

// Task creation simulation
#define xTaskCreate(func, name, stack, param, priority, handle) \
    pthread_create((pthread_t*)handle, NULL, (void*(*)(void*))func, param)

// Task delay simulation  
#define vTaskDelay(ticks) usleep((ticks) * 1000)

// Task deletion simulation
#define vTaskDelete(handle) pthread_exit(NULL)

// FreeRTOS version simulation
#define tskKERNEL_VERSION_NUMBER "FreeRTOS v10.4.3 (Simulated)"

#endif
