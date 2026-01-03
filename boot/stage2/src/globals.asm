section .bss

boot_drive resb 1

SECTOR_BUFFER_SECTORS equ 32
sector_buffer times SECTOR_BUFFER_SECTORS resb 512
