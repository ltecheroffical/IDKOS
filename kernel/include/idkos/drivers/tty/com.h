#pragma once

#include <stdint.h>

#include "idkos/drivers/tty/tty.h"

const extern struct TTYFunctions com_tty;

struct TTYCtx com_create_tty_ctx(uint16_t port);