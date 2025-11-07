/*
    See a thorouhly commented linker file here:
    https://github.com/wntrblm/Castor_and_Pollux/blob/main/firmware/scripts/samd21g18a.ld
*/

ENTRY(__start)

/*
    {INT,EXT}RAM_{START,SIZE} need to be set previously
*/

_Min_Heap_Size = 0x200;     /* required amount of heap  */
_Min_Stack_Size = 0x400;    /* required amount of stack */

/* Memory layout for AgonLight 2 (ez80F92) with external 512K SRAM */
MEMORY {
    FLASH   (rx) : ORIGIN = 0x0,           LENGTH = FLASH_SIZE   /* internal Flash */
    INTRAM  (rw) : ORIGIN = INTRAM_START,  LENGTH = INTRAM_SIZE  /* internal RAM */ 
    USERRAM (rw) : ORIGIN = EXTRAM_START,  LENGTH = EXTRAM_SIZE  /* external RAM */
}

SECTIONS
{
    .init : { KEEP(*(.init .fini)) } > FLASH

    .IVECTS : {
        . = ALIGN(0x100);
        __ivec_start = .;
        KEEP(*(.IVECTS))
        __ivec_end = .;
    } > FLASH

    .text : { *(.text .text.*) } > FLASH

    .init_array : {
        __init_array_start = .;
        KEEP(*(SORT(.preinit_array.*)))
        KEEP(*(.preinit_array))
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        KEEP(*crtbegin.o(.ctors))
        KEEP(*(EXCLUDE_FILE (*crtend.o) .ctors))
        KEEP(*(SORT(.ctors.*)))
        KEEP(*crtend.o(.ctors))
        __init_array_end = .;
    } > FLASH

    .fini_array : { 
        KEEP(*(.fini_array))
        KEEP(*(.dtors))
    } > FLASH

    .rodata : { *(.rodata .rodata*) } > FLASH

    _sidata = LOADADDR(.data);
    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.ramfunc .ramfunc.*);
        *(.data .data.*);
        _edata = .;
        . = ALIGN(4);
    } > USERRAM AT > FLASH

    .bss (NOLOAD):
    {
        bss_start = .;
        *(.bss .bss*)
        bss_end = .;
    } > USERRAM

    /* User_heap_stack section, used to check that there is enough RAM left */
    .heap_stack (NOLOAD):
    {
        . = ALIGN(4);
        PROVIDE (_heap_start = .);
        PROVIDE ( end = . );
        PROVIDE ( _end = . );
        . = . + _Min_Heap_Size;
        . = . + _Min_Stack_Size;
        . = ALIGN(4);
    } >USERRAM
}

__stack              = EXTRAM_START + EXTRAM_SIZE;
___low_bss           = bss_start;
___len_bss           = SIZEOF(.bss);
___heapbot           = bss_end;
___heaptop           = EXTRAM_START + EXTRAM_SIZE - _Min_Stack_Size;
___run_clearbss      = ___len_bss > 0;

/* symbols for initializing the init_array and ctors sections */
___init_array_count     = SIZEOF(.init_array) / 3;
___fini_array_count     = SIZEOF(.fini_array) / 3;
___init_count           = ___init_array_count;
___fini_count           = ___fini_array_count;
___run_init             = ___init_count > 0;
___run_fini             = ___fini_count > 0;
___init_array_functions = ADDR(.init_array);
___fini_array_functions = ADDR(.fini_array);

___sidata = _sidata;
___sdata = _sdata;
___edata = _edata;
_initdata_len = _edata - _sdata;