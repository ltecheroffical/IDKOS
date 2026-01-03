#include "idkos/heap.h"
#include <stdint.h>

size_t kernel_heap_ptr;
extern uint8_t kernel_heap[];

void kminit() {
    kernel_heap_ptr = 0;
}

void *kmalloc(size_t size) {
    void *ptr = &kernel_heap[kernel_heap_ptr];
    kernel_heap_ptr += size;
    return ptr;
}

void kfree(void *ptr) {
}