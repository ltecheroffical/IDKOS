section .text

start:
    pop dx
    mov [boot_drive], dl

    mov ax, stack_segment
    mov ss, ax
    mov sp, stack_top

    call check_32bit
    call enable_a20

    call load_kernel
    jmp boot

check_32bit:
    ; On 286 and eariler, 12-15 of flags are hardwired, we check if they aren't
    ; We do because use use 32-bit registers to parse FAT32

    ; Preserve OG flags
    pushf

    ; Save flags
    pushf
    pop ax
    mov cx, ax

    ; Set bits 12-15
    xor ax, 0xF000
    push ax
    popf

    ; Check if they changed
    pushf
    pop ax
    xor ax, cx
    and ax, 0xF000

    jz not_32bit
    popf
    ret

enable_a20:
    call .check_a20
    cmp ax, 0
    je .exit

    ; BIOS
    ; A20 support
    mov ax, 0x2403
    int 0x15
    jc .next_bios
    cmp ah, 0
    jnz .next_bios
    ; A20 Status
    mov ax, 0x2402
    int 0x15
    jc .next_bios
    cmp ah, 0
    jne .next_bios

    cmp al, 1
    je .exit

    ; Activate A20
    mov ax, 0x2401
    int 0x15
    jc .next_bios
    cmp ah, 0
    jne .next_bios
    jmp .exit

.next_bios:
    mov si, .no_a20_msg
    jmp display_error

.exit:
    ret

.no_a20_msg db "Cannot enable A20", 0

.check_a20:
    ; Code from https://wiki.osdev.org/A20_Line
    pushf
    push ds
    push es
    push di
    push si

    cli

    xor ax, ax ; ax = 0
    mov es, ax

    not ax ; ax = 0xFFFF
    mov ds, ax

    mov di, 0x0500
    mov si, 0x0510

    mov al, byte [es:di]
    push ax

    mov al, byte [ds:si]
    push ax

    mov byte [es:di], 0x00
    mov byte [ds:si], 0xFF

    cmp byte [es:di], 0xFF

    pop ax
    mov byte [ds:si], al

    pop ax
    mov byte [es:di], al

    mov ax, 0
    je .check_a20_exit
    
    mov ax, 1

.check_a20_exit:
    pop si
    pop di
    pop es
    pop ds
    popf


    ret

stack_segment equ 0x9000
stack_top     equ 0xFFFF