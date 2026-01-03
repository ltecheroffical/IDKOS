section .text

disk_error:
    mov si, .disk_error_msg
    jmp display_error

.disk_error_msg db "Disk error", 0

invalid_fat:
    mov si, .invalid_fat_msg
    jmp display_error

.invalid_fat_msg db "Invalid FAT partition", 0

not_32bit:
    mov si, .32bit_msg
    jmp display_error

.32bit_msg db "Cannot boot without 386 or higher CPU", 0

; Prints error in si as a C string and halts
display_error:
    mov ah, 0x0E
.loop:
    lodsb
    cmp al, 0
    je .end

    int 0x10
    jmp .loop
.end:
    cli
    hlt
    jmp .end ; In case it doesn't halt or we get an interrupt