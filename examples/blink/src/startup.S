INCLUDE "ez80f92.inc"

;
; Start or initialisation code and C-runtime start
; ------------------------------------------------
    .section .init
    .global  __start
_reset: 
_rst0:
__start:
    ; The CPU starts in Z80 mode, we need to get into eZ80 mode to get the right addressing modes and instructions
    .assume adl = 0
    di      ; disable interrupts
    ;stmix  ; set mixed memory mode flag (will push 0x02 or 0x03 onto the stack depending on Z80 or ADL mode)
    ; perform a jump that will set the ADL mode bit. See eZ80-User-Manual-Zilog_um0077.pdf table 15
    jp.lil _Reset_Handler
; everything hereafter is in ADL mode
.assume adl = 1 

; support RST {00, 08, 10, 18, 20, 28, 30, 38} instructions
; these are like a CALL. We can return normally from them.
. = 0x08
_rst8:
    CALL.LIL _rst_08_handler
    RET
. = 0x10
_rst10:
    CALL.LIL _rst_10_handler
    RET
. = 0x18
_rst18:
    CALL.LIL _rst_18_handler
    RET
. = 0x20
_rst20:
    CALL.LIL _rst_20_handler
    RET
. = 0x28
 _rst28:
    CALL.LIL _rst_28_handler
    RET
. = 0x30
_rst30:
    CALL.LIL _rst_30_handler
    RET
. = 0x38
_rst38:
    CALL.LIL _rst_38_handler
    RET
. = 0x66
_nmi:
    CALL.LIL _NMI_Handler
    RETN

; default implementation for maskable interrupts
; must reinable interrupts and do a RETI at end.
__default_mi_handler:
    JP .
    EI
 RETI

.equ NVECTORS, 48          ; number of interrupt vectors

;--------------------------------------
; Save interrupt mask/state
;--------------------------------------
.macro SAVEIMASK
    ld   a, i              ; sets parity bit to value of IEF2
    push af
    di                     ; disable interrupts while loading table
.endm

;--------------------------------------
; Restore interrupt mask/state
;--------------------------------------
.macro RESTOREIMASK
    pop  af
    jp   po, .+5           ; parity bit is IEF2
    ei
.endm

; Number of vectors supported
;
.section .rodata
.global __nvectors
__nvectors:  .word NVECTORS            ; extern unsigned short _nvectors;

.section .bss
    .global __2nd_jump_table
__2nd_jump_table:
    .space NVECTORS * 4     ; reserve 4 bytes per vector entry (jump table in RAM)

; Interrupt Vector Table
;  - this segment must be aligned on a 256 byte boundary anywhere below
;    the 64K byte boundry
;  - each 2-byte entry is a 2-byte vector address
;
    ; DEFINE .IVECTS, SPACE = ROM, ALIGN = 100h
    ; SEGMENT .IVECTS
.section .IVECTS, "a", @progbits
    .global __vector_table
__vector_table:
    .word __1st_jump_table + 0x00
    .word __1st_jump_table + 0x04
    .word __1st_jump_table + 0x08
    .word __1st_jump_table + 0x0c
    .word __1st_jump_table + 0x10
    .word __1st_jump_table + 0x14
    .word __1st_jump_table + 0x18
    .word __1st_jump_table + 0x1c
    .word __1st_jump_table + 0x20
    .word __1st_jump_table + 0x24
    .word __1st_jump_table + 0x28
    .word __1st_jump_table + 0x2c
    .word __1st_jump_table + 0x30
    .word __1st_jump_table + 0x34
    .word __1st_jump_table + 0x38
    .word __1st_jump_table + 0x3c
    .word __1st_jump_table + 0x40
    .word __1st_jump_table + 0x44
    .word __1st_jump_table + 0x48
    .word __1st_jump_table + 0x4c
    .word __1st_jump_table + 0x50
    .word __1st_jump_table + 0x54
    .word __1st_jump_table + 0x58
    .word __1st_jump_table + 0x5c
    .word __1st_jump_table + 0x60
    .word __1st_jump_table + 0x64
    .word __1st_jump_table + 0x68
    .word __1st_jump_table + 0x6c
    .word __1st_jump_table + 0x70
    .word __1st_jump_table + 0x74
    .word __1st_jump_table + 0x78
    .word __1st_jump_table + 0x7c
    .word __1st_jump_table + 0x80
    .word __1st_jump_table + 0x84
    .word __1st_jump_table + 0x88
    .word __1st_jump_table + 0x8c
    .word __1st_jump_table + 0x90
    .word __1st_jump_table + 0x94
    .word __1st_jump_table + 0x98
    .word __1st_jump_table + 0x9c
    .word __1st_jump_table + 0xa0
    .word __1st_jump_table + 0xa4
    .word __1st_jump_table + 0xa8
    .word __1st_jump_table + 0xac
    .word __1st_jump_table + 0xb0
    .word __1st_jump_table + 0xb4
    .word __1st_jump_table + 0xb8
    .word __1st_jump_table + 0xbc

; 1st Interrupt Vector Jump Table
;  - this table must reside in the first 64K bytes of memory
;  - each 4-byte entry is a jump to the 2nd jump table plus offset
;
.section .init
.global __1st_jump_table
__1st_jump_table:
    JP __2nd_jump_table + 0x00
    JP __2nd_jump_table + 0x04
    JP __2nd_jump_table + 0x08
    JP __2nd_jump_table + 0x0c
    JP __2nd_jump_table + 0x10
    JP __2nd_jump_table + 0x14
    JP __2nd_jump_table + 0x18
    JP __2nd_jump_table + 0x1c
    JP __2nd_jump_table + 0x20
    JP __2nd_jump_table + 0x24
    JP __2nd_jump_table + 0x28
    JP __2nd_jump_table + 0x2c
    JP __2nd_jump_table + 0x30
    JP __2nd_jump_table + 0x34
    JP __2nd_jump_table + 0x38
    JP __2nd_jump_table + 0x3c
    JP __2nd_jump_table + 0x40
    JP __2nd_jump_table + 0x44
    JP __2nd_jump_table + 0x48
    JP __2nd_jump_table + 0x4c
    JP __2nd_jump_table + 0x50
    JP __2nd_jump_table + 0x54
    JP __2nd_jump_table + 0x58
    JP __2nd_jump_table + 0x5c
    JP __2nd_jump_table + 0x60
    JP __2nd_jump_table + 0x64
    JP __2nd_jump_table + 0x68
    JP __2nd_jump_table + 0x6c
    JP __2nd_jump_table + 0x70
    JP __2nd_jump_table + 0x74
    JP __2nd_jump_table + 0x78
    JP __2nd_jump_table + 0x7c
    JP __2nd_jump_table + 0x80
    JP __2nd_jump_table + 0x84
    JP __2nd_jump_table + 0x88
    JP __2nd_jump_table + 0x8c
    JP __2nd_jump_table + 0x90
    JP __2nd_jump_table + 0x94
    JP __2nd_jump_table + 0x98
    JP __2nd_jump_table + 0x9c
    JP __2nd_jump_table + 0xa0
    JP __2nd_jump_table + 0xa4
    JP __2nd_jump_table + 0xa8
    JP __2nd_jump_table + 0xac
    JP __2nd_jump_table + 0xb0
    JP __2nd_jump_table + 0xb4
    JP __2nd_jump_table + 0xb8
    JP __2nd_jump_table + 0xbc
; Initialize all potential interrupt vector locations with a known
; default handler.
;
; void _init_default_vectors(void);
;
.section .init
__init_default_vectors:
_init_default_vectors:
    PUSH AF
    SAVEIMASK
    LD HL, __default_mi_handler
    LD A, 0xC3
    LD  (__2nd_jump_table), A  ; Place jp opcode
    LD  (__2nd_jump_table + 1), HL ; __default_hndlr
    LD  HL, __2nd_jump_table
    LD DE, __2nd_jump_table + 4
    LD BC, NVECTORS * 4 - 4
    LDIR
    IM 2
    LD  A, __vector_table >> 8
    LD  I, A    ; Load interrupt vector base
    RESTOREIMASK
    POP AF
    RET

; Installs a user interrupt handler in the 2nd interrupt vector jump table
;
; void * _set_vector(unsigned int vector, void(*handler)(void));
;
.global _set_vector
.global __set_vector
__set_vector:
_set_vector:
    PUSH IY
    LD IY, 0
    ADD IY, SP    ; Standard prologue
    PUSH AF
    SAVEIMASK
    LD BC, 0    ; Clear BC
    LD B, 2    ; Calculate 2nd jump table offset
    LD C, (IY + 6)   ; Vector offset
    MLT BC    ; BC is 2nd jp table offset
    LD HL, __2nd_jump_table
    ADD HL, BC    ; HL is location of jp in 2nd jp table
    LD  (HL), 0xC3   ; Place jp opcode just in case
    INC HL    ; HL is jp destination address
    LD BC, (IY + 9)   ; BC is isr address
    LD  DE, (HL)   ; Save previous handler
    LD  (HL), BC   ; Store new isr address
    PUSH DE
    POP HL    ; Return previous handler
    RESTOREIMASK
    POP AF
    LD  SP, IY    ; Standard epilogue
    POP IY
    RET

.section .text
_Reset_Handler:
    ; do very low level init of peripherals and SRAM and flash
    ld a, 0xFF
    out0 (PB_DDR), a         ; GPIO all set to input
    out0 (PC_DDR), a         ;
    out0 (PD_DDR), a         ;
    ld a, 0x00
    out0 (PB_ALT1), a        ;
    out0 (PC_ALT1), a        ;
    out0 (PD_ALT1), a        ;
    out0 (PB_ALT2), a        ;
    out0 (PC_ALT2), a        ;
    out0 (PD_ALT2), a        ;
    out0 (TMR0_CTL), a       ; timers
    out0 (TMR1_CTL), a       ;
    out0 (TMR2_CTL), a       ;
    out0 (TMR3_CTL), a       ;
    out0 (TMR4_CTL), a       ;
    out0 (TMR5_CTL), a       ;
    out0 (UART0_IER), a      ; UARTs
    out0 (UART1_IER), a      ;
    out0 (I2C_CTL), a        ; I2C
    out0 (FLASH_IRQ), a      ; Flash
    ld a, 0x04
    out0 (SPI_CTL), a        ; SPI (CPHA=1, CPOL=0, SPI_EN=0, default bits)
    in0 a, (RTC_CTRL)        ; RTC, Writing to the RTC_CTRL register also
    and a, 0xBE              ;      resets the RTC count prescaler allowing
    out0 (RTC_CTRL), a       ;      the RTC to be synchronized to another time source

    ; lower boundary for external SRAM (starting 0x040000)
    ld a, 0x04
    out0 (CS0_LBR), a
    ; upper boundary for external SRAM (ending 0x0bffff ==> 512 KB SRAM chip)
    ld a, 0x0b
    out0 (CS0_UBR), a
    ; 1 wait-state, ez80 mode
    ld a, 0b00000001
    out0 (CS0_BMC), a
    ; memory chip select, cs0 enabled
    ld a, 0b00001000
    out0 (CS0_CTL), a

    ; disable other chip-selects
    ld a, 0x00
    out0 (CS1_CTL), a
    ld a, 0x00
    out0 (CS2_CTL), a
    ld a, 0x00
    out0 (CS3_CTL), a

    ; internal flash configured at memmory address 0x000000
    ld a, 0x00
    out0 (FLASH_ADDR_U), a
    ld a, 0b00101000   ;  1 wait-state, ez80 mode
    out0 (FLASH_CTRL), a

    ; configure internal RAM upper address byte (meaning its range is 0xb7FFFF to 0xb7E000 for 8 KB in eZ80F92)
    ld a, 0xb7
    out0 (RAM_ADDR_U), a
    ld a, 0b10000000         ; enable
    out0 (RAM_CTL), a

    ; set up program specific stack
    ld sp, __stack  ; defined through linkerscript

; load init values from FLASH to RAM
_init_data:
    ; HL = source (FLASH) = _sidata
    ld  hl, _sidata
    ; DE = destination (SRAM) = _sdata
    ld  de, _sdata
    ; BC = number of bytes = _edata - _sdata
    ld  bc, _initdata_len

    ; If no data, skip
    ld  a, b
    or  c
    JR z, .startzerobss

    ; Copy loop: LDIR = load from (HL) to (DE), increment, decrement BC
    ldir                 ; copies BC bytes from (HL) to (DE)

; Zero the bss section
; --------------------
; The HEADER __alloc_base for malloc() is in BSS, so it should be reset as part of this
.startzerobss:
    ld a, ___run_clearbss
    or a, 0
    jr z, .call_init_functions
local _clear_bss
_clear_bss:
   ; Clear the RAM in the BSS segment
    ld  bc, ___len_bss
    ld  hl, ___low_bss
    ld  de, ___low_bss+1
    ld  (hl), 0
    ldir ; copy 0 from previous location to next

.call_init_functions:

; initialize default vector table
    call _init_default_vectors

; Call initialisers and constructors
; ----------------------------------

    ld  a, ___run_init
    or  a, a
    jr  z, .call_into_main

    ld  ix, ___init_array_functions
    ld  bc, ___init_count      ; BC is 24-bit in ADL mode

.init_loop:
    ld   hl, (ix)              ; get address of current function
    lea  ix, ix+3              ; move to next function
    push bc                    ; the called function may modify our registers 
    push ix                    ; so we better save them on the stack (calling convention)

    call __indcallhl
    pop ix            ; and restore the saved registers again
    pop bc           

    dec  bc          ; decrement 24-bit counter (number of functions left) but doesn't set flags
    ld a, b
    or a, c         ; sets Z if BC==0 (lower 16 bits of it.. assume noone uses beyond 64k functions anyways)
    jp   nz, .init_loop

.call_into_main:
; Call main function
; ------------------
; Start of the C program called either as int main(void) or int main(int argc, char *argv[])
; - value returned will be in HL

    call _main     ; int main()
    ; return value / exit code will be in HL
    ; hang up. don't continue further.
    JR .

.section .text
    .global _atexit
_atexit:
    .global _on_exit
    ; nothing 
    RET

.section .text
    .global __indcallhl
__indcallhl:
    jp  (hl)

.section .text
    .global __setflag
__setflag:

    push bc
    push af
    pop  bc  ; c <- flags

    bit  2,c  ; .if (v == 1)
    jr   z,_done  ; .else go to .done
    ld   a,c  ; c <- c xor %80
    xor  a,0x80
    ld   c,a

_done:
    push  bc
    pop   af  ; flags <- c
    pop   bc
    ret 

.section .text
    .global __frameset
__frameset:
    pop  de
    push ix
    ld   ix, 0
    add  ix, sp
    add  hl, sp
    ld   sp, hl
    ex   de, hl
    jp   (hl)

 .assume adl=1

.section .text
.global __frameset0
__frameset0:
    pop     hl
    push    ix
    ld      ix, 0
    add     ix, sp
    jp      (hl)


; Dummy interrupt handlers
 .weak _rst_08_handler
_rst_08_handler:
    RET
 .weak _rst_10_handler
_rst_10_handler:
    RET
 .weak _rst_18_handler
_rst_18_handler:
    RET
 .weak _rst_20_handler
_rst_20_handler:
    RET
 .weak _rst_28_handler
_rst_28_handler:
    RET
 .weak _rst_30_handler
_rst_30_handler:
    RET
 .weak _rst_38_handler
_rst_38_handler:
    RET
 .weak _NMI_Handler
_NMI_Handler:
    RET

    ; Sections for destructors and finalisers
    extern  _main
    extern  __indcallhl

    extern  ___len_bss   ; coming from linker_script, defined in makefile.mk
    extern  ___low_bss   ; coming from linker_script, defined in makefile.mk
    extern  ___heapbot   ; coming from linker_script, defined in makefile.mk

    extern  __stack    ; defined in makefile.mk

    extern ___init_array_count
    extern ___init_array_functions

    extern _sidata
    extern _sdata
    extern _edata
    extern _initdata_len
