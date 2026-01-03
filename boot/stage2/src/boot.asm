section .text

load_kernel:
    call parse_fat16_meta

    call reset_dap
    
    mov word [dap.offset], sector_buffer

    ; Calculate root directory start
    mov al, [fat16_fat_count]
    movzx ax, al
    mov bx, [fat16_sectors_per_fat]
    mul ax, bx
    movzx eax, ax

    mov ebx, [fat16_fat_start_lba]
    add eax, ebx
    mov [dap.lba], eax

    mov ax, [fat16_root_entries]
    shr ax, 4 ; /16
    mov [dap.sectors], ax

    cmp ax, SECTOR_BUFFER_SECTORS
    jg invalid_fat
    
    call read_disk

    mov si, sector_buffer
.search_loop:
    mov al, [si]
    cmp al, 0x00 ; EOF
    je .not_found
    cmp al, 0xE5
    je .search_loop_next

    xor dx, dx
.compare_filename_loop:
    mov bx, si
    add bx, dx
    mov al, [bx]
    mov bx, .kernel_filename
    add bx, dx
    mov ah, [bx]

    cmp al, ah
    jne .search_loop_next

    inc dx
    cmp dx, 11
    jne .compare_filename_loop
    jmp .load

.search_loop_next:
    add si, 32
    jmp .search_loop

.load:
    mov ax, [si + 26]
    mov [.kernel_current_cluster], ax

    ; Load the FAT once I find the kernel bc we don't need the table anymore
    call reset_dap
    
    mov word [dap.offset], sector_buffer + 512
    
    mov eax, [fat16_fat_start_lba]
    mov [dap.lba], eax

    mov ax, [fat16_sectors_per_fat]
    mov [dap.sectors], ax

    call read_disk

    call reset_dap
    mov word [dap.offset], sector_buffer
.read_kernel_loop:
    mov ax, [.kernel_current_cluster]
    movzx eax, ax

    sub eax, 2 ; Clusters start at 2
    mov bl, [fat16_sectors_per_cluster]
    movzx ebx, bl
    mul eax, ebx

    add eax, [fat16_data_start_lba]
    push eax

    mov ecx, 0
.read_cluster_loop:
    mov si, sp
    
    push ds
    mov ax, ss
    mov ds, ax
    mov eax, [si]
    pop ds

    add eax, ecx
    mov dword [dap.lba], eax

    push ecx
    call read_disk

    xor si, si
.copy_sector_loop:
    mov al, [sector_buffer + si]
    push ds
    mov cx, [.kernel_current_cluster]
    sub cx, 2 ; Clusters start at 2
    shl cx, 5 ; *32

    add cx, 0x1000
    mov ds, cx
    mov [si], al
    pop ds

    inc si
    cmp si, 512
    jne .copy_sector_loop
    pop ecx
    
    inc ecx
    mov al, [fat16_sectors_per_cluster]
    movzx eax, al
    cmp ecx, eax
    jne .read_cluster_loop

    pop dword eax

    ; Check for more clusters
    mov si, sector_buffer + 512
    mov ax, [.kernel_current_cluster]
    shl ax, 1 ; *2
    add si, ax
    mov ax, [si]
    cmp ax, 0xFFEF
    mov [.kernel_current_cluster], ax
    jbe .read_kernel_loop
    ret

.not_found:
    mov si, .kernel_not_found_msg
    call display_error

.kernel_current_cluster dw 0
.kernel_not_found_msg db "/KERNEL.BIN not found.", 0
.kernel_filename db "KERNEL  BIN"

parse_fat16_meta:
    call reset_dap
    mov si, 0x7DBE + 0x10 + 0x08 ; LBA of partition #2
    mov eax, [si]
    mov [.partition2_lba], eax
    mov [dap.lba], eax

    mov word [dap.offset], sector_buffer
    mov [dap.sectors], 2

    call read_disk

    ; Signature
    mov al, [sector_buffer + 38]
    cmp al, 0x28
    je .next_1
    cmp al, 0x29
    je .next_1
    jmp invalid_fat

.next_1:
    ; First byte must be 0xEB
    mov al, [sector_buffer + 0]
    cmp al, 0xEB
    jne invalid_fat

    ; Bytes per sector
    ; Alignment check
    mov ax, [sector_buffer + 11]
    test ax, 0x01FF
    jnz invalid_fat

    shr ax, 9 ; /512
    cmp ax, SECTOR_BUFFER_SECTORS - 1
    jg invalid_fat
    mov [fat16_sectors_per_fat_sector], ax
    
    ; Get required meta

    ; FAT count
    mov al, [sector_buffer + 16]
    mov [fat16_fat_count], al

    ; Sectors per FAT
    mov ax, [sector_buffer + 22]
    mul ax, [fat16_sectors_per_fat_sector]
    mov [fat16_sectors_per_fat], ax

    ; Sectors per cluster
    mov al, [sector_buffer + 13]
    movzx ax, al
    mul ax, [fat16_sectors_per_fat_sector]
    mov [fat16_sectors_per_cluster], al

    ; Root entries
    mov ax, [sector_buffer + 17]
    mov [fat16_root_entries], ax
    
    ; FAT start LBA [partition_lba + (reserved_sectors * sectors_per_fat_sector)]
    ; Get reserved sectors
    mov ax, [sector_buffer + 14]
    movzx eax, ax
    ; Convert to LBA
    mov bx, [fat16_sectors_per_fat_sector]
    movzx ebx, bx
    mul eax, ebx
    ; Calculate FAT start LBA
    mov esi, [.partition2_lba]
    add esi, eax
    mov [fat16_fat_start_lba], esi

    ; Data start LBA [fat_start_lba + fat_count * sectors_per_fat * sectors_per_fat_sector + root_entries / 16]
    ; root_entries / 16
    mov dx, [fat16_root_entries]
    shr dx, 4 ; /16
    ; fat_count * sectors_per_fat * sectors_per_fat_sector    
    mov bl, [fat16_fat_count]
    movzx bx, bl
    mov cx, [fat16_sectors_per_fat]
    mul bx, cx
    mov cx, [fat16_sectors_per_fat_sector]
    mul bx, cx
    ; combine all + fat_start_lba
    add dx, bx
    movzx edx, dx
    mov ebx, [fat16_fat_start_lba]
    add edx, ebx
    mov [fat16_data_start_lba], edx
    ret

.partition2_lba dq 0

boot:
    lgdt [.gdt_descriptor]

    ; Switch to protected mode
    mov eax, cr0 
    or al, 1 ; Set PE
    mov cr0, eax

    jmp 0x08:pm_start

.gdt_start:

.gdt_null:
    dq 0x0000000000000000    ; mandatory null descriptor

.gdt_code:
    dw 0xFFFF                ; limit low
    dw 0x0000                ; base low
    db 0x00                  ; base middle
    db 10011010b             ; access byte
    db 11001111b             ; flags + limit high
    db 0x00                  ; base high

.gdt_data:
    dw 0xFFFF
    dw 0x0000
    db 0x00
    db 10010010b
    db 11001111b
    db 0x00

.gdt_end:

.gdt_descriptor:
    dw .gdt_end - .gdt_start - 1
    dd .gdt_start

section .bss
fat16_sectors_per_fat_sector resw 1
fat16_fat_start_lba resq 1
fat16_data_start_lba resq 1
fat16_fat_count resb 1
fat16_sectors_per_fat resw 1
fat16_sectors_per_cluster resb 1
fat16_root_entries resw 1