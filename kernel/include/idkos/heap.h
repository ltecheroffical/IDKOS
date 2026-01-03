#pragma once

#include <stddef.h>

void kminit();
[[nodiscard("Pointer should be freed after")]] void *kmalloc(size_t size);
void kfree(void *ptr);