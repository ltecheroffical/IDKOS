#include "idkos/drivers/tty/com.h"
#include "idkos/drivers/tty/tty.h"
#include "idkos/heap.h"
#include <stdint.h>

#define VGA_WIDTH 80
#define VGA_HEIGHT 25
#define VGA_BUFFER ((volatile uint8_t*)0xB8000)

void kernel_main() {
    struct TTYCtx tty = com_create_tty_ctx(0x3F8); // COM1
    com_tty.init(&tty);

    kminit();

    void *ptr = kmalloc(512);

    char *message = "text test.\nText test.\rt\n";

    for (int y = 0; y < VGA_HEIGHT; y++) {
        for (int x = 0; x < VGA_WIDTH; x++) {
            int index = 2 * (y * VGA_WIDTH + x);
            VGA_BUFFER[index] = ' ';
            VGA_BUFFER[index + 1] = 0x07;
        }
    }

    int x = 0;
    int y = 0;
    for (char *cursor = message; *cursor != 0; cursor++) {
        com_tty.putc(&tty, *cursor);
        switch (*cursor) {
        case '\n':
            x = 0;
            y++;
            break;
        case '\r':
            x = 0;
            break;
        default:
            VGA_BUFFER[2 * (y * VGA_WIDTH + x)] = *cursor;
            VGA_BUFFER[2 * (y * VGA_WIDTH + x) + 1] = 0x07;
            x++;
            break;
        }
    }

    char *serial_message = "\n\n(If in serial, you're seeing it, it's working!!!)";
    for (char *cursor = serial_message; *cursor != 0; cursor++) {
        com_tty.putc(&tty, *cursor);
    }

    for (;;);
}