.intel_syntax noprefix

.text
.global _start
_start:
    mov esp, kernel_stack_top
    mov ebp, esp

    call kernel_main
