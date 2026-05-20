/* Linker script for ODX8 Operating System */

ENTRY(_start)

SECTIONS
{
    . = 1M;

    /* Multiboot header */
    .multiboot ALIGN(8) :
    {
        *(.multiboot)
    }

    /* Code section */
    .text ALIGN(4K) :
    {
        *(.text)
    }

    /* Read-only data */
    .rodata ALIGN(4K) :
    {
        *(.rodata)
    }

    /* Initialized data */
    .data ALIGN(4K) :
    {
        *(.data)
    }

    /* Uninitialized data */
    .bss ALIGN(4K) :
    {
        *(COMMON)
        *(.bss)
    }

    /* Discard unnecessary sections */
    /DISCARD/ :
    {
        *(.comment)
        *(.eh_frame)
        *(.note.gnu.build-id)
    }
}
