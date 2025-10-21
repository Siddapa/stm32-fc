MEMORY 
{
    FLASH (rx)  : ORIGIN = 0x08000000, LENGTH = 64K
    RAM   (rwx) : ORIGIN = 0x20000000, LENGTH = 20K
}

__reset_stack_pointer = ORIGIN(RAM) + LENGTH(RAM);

SECTIONS {
    .text : {
		. = ORIGIN(FLASH);
        LONG(__reset_stack_pointer);
        LONG(_start | 1);
        /* The whole interrupt table is 332 bytes long. Advance to that position. */
        . = ORIGIN(FLASH) + 332;
        /* And here comes the rest of the code, ie. all symbols starting with .text */
        *(.text)
    } > FLASH  /* Put this in the flash memory region */

	.ARM.exidx : {
        *(.ARM.exidx*)
        . = ALIGN(4);
    } > FLASH
}
