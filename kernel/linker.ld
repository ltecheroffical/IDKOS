ENTRY(_start)
OUTPUT_FORMAT(elf32-i386)

/* LD needs to shut up when we are building our elf */
PHDRS {
  text PT_LOAD FLAGS(5); /* R + X */
  data PT_LOAD FLAGS(6); /* R + W */
}

SECTIONS {
    . = 0x10000;

    .text : ALIGN(16) {
        _start = .;
        *(.text)
    } : text

	.rodata : ALIGN(16) {
		*(.rodata)
	} : text

	.data : ALIGN(16) {
		*(.data)
	} : data

	.bss : ALIGN(16) {
		*(COMMON)
		*(.bss)

		kernel_stack_bottom = .;
		. = . + 16K;
		kernel_stack_top = .;

		kernel_heap = .;
		. = . + 64K;
	} : data
}