/*
    See a thorouhly commented linker file here:
    https://github.com/wntrblm/Castor_and_Pollux/blob/main/firmware/scripts/samd21g18a.ld
*/

ENTRY(__start)

/*
    RAM_START and RAM_SIZE need to be set previously
*/

MEMORY {
    FLASH (rx) : ORIGIN = 0x0, LENGTH = 128K  /* Define Flash region */
    USERRAM (rw) : ORIGIN = RAM_START, LENGTH = RAM_SIZE  /* Define RAM region */
}

SECTIONS
{
    . = RAM_START;

    .init : { *(.init .init.args .init.bss .fini) } > FLASH

    .text : { *(.text) } > FLASH

    .init_array : { *(.init_array) } > FLASH

    .ctors : { *(.ctors) } > FLASH

    .dtors : { *(.dtors) } > FLASH

    .fini_array : { *(.fini_array) } > FLASH

    .rodata : { *(.rodata) } > FLASH

    _sidata = LOADADDR(.data);
    .data : {
        . = ALIGN(4);
        _sdata = .;
        *(.data) 
        _edata = .;
        . = ALIGN(4);
    } > USERRAM AT > FLASH

    .bss (NOLOAD):
    {
        bss_start = .;
        *(.bss .bss*)
        bss_end = .;
    } > USERRAM
}

__stack              = RAM_START + RAM_SIZE;
___low_bss           = bss_start;
___len_bss           = SIZEOF(.bss);
___heapbot           = bss_end;
___heaptop           = RAM_START + RAM_SIZE;
___run_clearbss      = ___len_bss > 0;

/* symbols for initializing the init_array and ctors sections */
___init_array_count     = SIZEOF(.init_array) / 3;
___ctors_count          = SIZEOF(.ctors) / 3;
___dtors_count          = SIZEOF(.dtors) / 3;
___fini_array_count     = SIZEOF(.fini_array) / 3;
___init_count           = ___init_array_count + ___ctors_count;
___fini_count           = ___dtors_count + ___fini_array_count;
___run_init             = ___init_count > 0;
___run_fini             = ___fini_count > 0;
___init_count_a         = (((___init_count -1) >> 16) & 0xFF) + 1;
___init_count_b         = (((___init_count -1)      ) & 0xFF) + 1;
___init_count_c         = (((___init_count -1) >>  8) & 0xFF) + 1;
___fini_count_a         = (((___fini_count -1) >> 16) & 0xFF) + 1;
___fini_count_b         = (((___fini_count -1)      ) & 0xFF) + 1;
___fini_count_c         = (((___fini_count -1) >>  8) & 0xFF) + 1;
___init_array_functions = SIZEOF(.init_array) + ADDR(.init_array);
___init_ctors_functions = SIZEOF(.ctors) + ADDR(.ctors);
___fini_dtors_functions = SIZEOF(.dtors) + ADDR(.dtors);
___fini_array_functions = SIZEOF(.fini_array) + ADDR(.fini_array);

___sidata = _sidata;
___sdata = _sdata;
___edata = _edata;
_initdata_len = _edata - _sdata;