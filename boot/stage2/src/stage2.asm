org 0x8000

jmp start

%include "debug.asm"

%include "boot.asm"
%include "dap.asm"
%include "start.asm"
%include "errors.asm"

%include "globals.asm"

section .text
bits 32

pm_start:
    ; JUMP TO KERNEL!
    jmp 0x10000