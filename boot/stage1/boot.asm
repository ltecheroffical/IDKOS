bits 16
org 0x7C00

section .text
boot:
    cli

    mov si, 0x7DBE + 0x08 ; LBA of partition #1
    mov ax, [si]
    mov [dap.lba], ax
    mov ax, [si + 2]
    mov [dap.lba + 2], ax

    mov ax, [0x7DBE + 0x0C] ; Sectors of partition #
    mov [dap.sectors], ax

    mov si, dap
    mov ah, 0x42 ; Extended read
    int 0x13
    jc disk_error

    mov dh, 0 ; Ensure one byte since you can't push/pop one byte
    push dx ; Pass boot drive through stack
    jmp 0x8000 ; Jump to stage2

disk_error:
    mov ah, 0x0E
    mov si, disk_error_msg

.loop:
    lodsb
    cmp al, 0
    je .end
    int 0x10
    jmp .loop

.end:
    hlt

dap:
    db 16 ; size
    db 0 ; reserved
.sectors: dw 1 ; sectors
    dw 0x8000 ; offset
    dw 0 ; segment
.lba: dq 0 ; lba


disk_error_msg db "Disk error", 0

times 510-($-$$) db 0
dw 0xAA55