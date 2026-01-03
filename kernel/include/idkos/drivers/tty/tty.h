#pragma once

#include <stdint.h>
#include <stdbool.h>

struct TTYCtx {
    union {
        void *ptr;
        uint32_t u32;
        uint16_t u16[2];
        uint8_t u8[4];
        int32_t i32;
        int16_t i16[2];
        int8_t i8[4];
    } data[4];
};

struct TTYFunctions {
    bool (*init)(struct TTYCtx *ctx);
    void (*deinit)(struct TTYCtx *ctx);

    void (*putc)(struct TTYCtx *ctx, char c);
};