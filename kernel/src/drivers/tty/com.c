#include "idkos/drivers/tty/com.h"
#include "idkos/drivers/tty/tty.h"
#include "idkos/ports.h"
#include <stdint.h>

#define TTY_COM_PORT(ctx) ((ctx)->data[0].u16[0])

struct TTYCtx com_create_tty_ctx(uint16_t port) {
    return (struct TTYCtx){
        .data[0] = {
            .u16 = port,
        },
    };
}

bool com_init(struct TTYCtx *ctx) {
    const uint8_t magic_test_byte = 0xAE;
    outportb(TTY_COM_PORT(ctx) + 1, 0x00); // Disable all interrupts
    outportb(TTY_COM_PORT(ctx) + 3, 0x80); // Enable DLAB (set baud rate divisor)
    outportb(TTY_COM_PORT(ctx) + 0, 0x03); // Set divisor to 3 (lo byte) 38400 baud
    outportb(TTY_COM_PORT(ctx) + 1, 0x00); //                  (hi byte)
    outportb(TTY_COM_PORT(ctx) + 3, 0x03); // 8 bits, no parity, one stop bit
    outportb(TTY_COM_PORT(ctx) + 2, 0xC7); // Enable FIFO, clear them, with 14-byte threshold
    outportb(TTY_COM_PORT(ctx) + 4, 0x0B); // IRQs enabled, RTS/DSR set

    // Test
    outportb(TTY_COM_PORT(ctx) + 4, 0x1E); // Set to loopback
    outportb(TTY_COM_PORT(ctx), magic_test_byte); // Send byte and check if same returned
    if (inportb(TTY_COM_PORT(ctx)) != magic_test_byte) {
        return false;
    }

    // Set it normal
    outportb(TTY_COM_PORT(ctx) + 4, 0x0F); // IRQs enabled, OUT#1 and OUT#2 enabled
    return true;
}

void com_deinit(struct TTYCtx *ctx) {
}

void com_putc(struct TTYCtx *ctx, char c) {
    while (!(inportb(TTY_COM_PORT(ctx) + 5) & 0x20));
    outportb(TTY_COM_PORT(ctx), c);
}

const struct TTYFunctions com_tty = {
    .init = com_init,
    .deinit = com_deinit,

    .putc = com_putc,
};