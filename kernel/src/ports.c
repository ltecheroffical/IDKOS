#include "idkos/ports.h"
#include <stdint.h>

void outportb(uint16_t port, uint8_t data) {
    asm volatile(
        ".intel_syntax noprefix\n"
        "out dx, al \n" 
        ".att_syntax prefix\n"
        :
        : "al" (data), "dx" (port)
    );
}

uint8_t inportb(uint16_t port) {
    uint8_t data;
    asm volatile(
        ".intel_syntax noprefix\n"
        "in al, dx\n"
        ".att_syntax prefix\n"
        : "=al" (data)
        : "dx" (port)
    );
    return data;
}