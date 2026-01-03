#pragma once

#include <stdint.h>

void outportb(uint16_t port, uint8_t data);
uint8_t inportb(uint16_t port);