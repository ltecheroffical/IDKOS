section .text

reset_dap:
    mov [dap.segment], ds
    mov [dap.offset], 0
    mov word [dap.sectors], 1
    mov [dap.lba], 0
    ret

read_disk:
    mov si, dap
    mov dl, [boot_drive]
    mov ah, 0x42
    int 0x13
    jc disk_error
    ret

dap:
    db 16 ; size
    db 0 ; reserved
.sectors: dw 1 ; sectors
.offset: dw 0 ; offset
.segment: dw 0 ; segment
.lba: dq 0 ; lba