INCLUDE	"ez80f92.inc"

;
; Start or initialisation code and C-runtime start
; ------------------------------------------------
	.section .init
	.global 	__start
_reset:	
_rst0:
__start:
    DI      ; disable interrupts
	;STMIX  ; set mixed memory mode flag (will push 0x02 or 0x03 onto the stack depending on Z80 or ADL mode)
    ; The CPU starts in Z80 mode, we need to get into eZ80 mode to get the right addressing modes and instructions
    .assume adl = 0
    ; perform a jump that will set the ADL mode bit. See eZ80-User-Manual-Zilog_um0077.pdf table 15
    JP.LIL __start_real
	.assume	adl = 1	
__start_real:

    ; do very low level init of peripherals and SRAM and flash
    ld a, 0xFF
    out0 (PB_DDR), a         ; GPIO
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
    out0 (SPI_CTL), a        ; SPI
    in0 a, (RTC_CTRL)        ; RTC, Writing to the RTC_CTRL register also
    and a, 0xBE              ;      resets the RTC count prescaler allowing
    out0 (RTC_CTRL), a       ;      the RTC to be synchronized to another time source

    ld a, 0x04
    out0 (CS0_LBR), a
    ld a, 0x0b
    out0 (CS0_UBR), a
    ld a, 0b00000001
    out0 (CS0_BMC), a
    ld a, 0b00001000
    out0 (CS0_CTL), a

    ld a, 0x00
    out0 (CS1_CTL), a

    ld a, 0x00
    out0 (CS2_CTL), a

    ld a, 0x00
    out0 (CS3_CTL), a
    ;   
    ; Enable internal memory
    ;
    ld a, 0x00
    out0 (FLASH_ADDR_U), a
    ld a, 0b00101000   ;  1 wait-state, ez80 mode
    out0 (FLASH_CTRL), a

    ld a, 0xb7
    out0 (RAM_ADDR_U), a
    ld a, 0b10000000
    out0 (RAM_CTL), a

    ; set up program specific stack
	;ld	sp, __stack		; defined in makefile.mk
    ld sp, 0x0BFFFF

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
    jr z, .endzerobss
	CALL	_clear_bss 		; Clear the RAM in the BSS segment

.endzerobss:
; Call initialisers and constructors
; ----------------------------------

    ld a, ___run_init               ; boolean from the linker if ___init_count > 0
    or a, 0
    jr z, .init_end

	ld ix,init_functions			; prepare to iterate through init_functions
    ld a, ___init_count_a & 0xFF    ; counter byte-order will be [MSB: A, C, LSB: B]
    ld b, ___init_count_b & 0xFF    ; AND with 0xFF to skip the r_imm8 load error of a symbol constant
    ld c, ___init_count_c & 0xFF

.init_loop:
	push	bc 					; save iteration counter
	push	af  
	ld	    hl,(ix) 			; get address of the current initialisation function
	lea	    ix,ix+3 			; move point to next function ready for next iteration
	call	__indcallhl 		; call the initialisation function
	pop	    af 					; restore iteration counter
	pop	    bc
	djnz	.init_loop 			; iterate on the count in [b] - the lowest byte
	dec	    c 					; iterate on the count in [c] - the middle byte
	jp	    nz,.init_loop
	dec	    a 					; iterate on the count in [a] - the high byte
	jp	    nz,.init_loop

.init_end:

; Call main function
; ------------------
; Start of the C program called either as int main(void) or int main(int argc, char *argv[])
; - value returned will be in HL
    ; per ABI, we expect BC = 0
    xor a          ; clear carry
    ld bc, 0
    ld de, 0
    ld iy, 0

	call	_main 				; int main(int argc, char *argv[])

   ; return value / exit code will be in HL


.section	.fini
	.global	_exit
_exit:
    JR .
.fini_end:

	.global	__Exit
__Exit: 
    JR .

.global _delay_once
_delay_once:
    ld iy, 0
    add iy, sp
    push hl

    ; --------------------------
    LD DE, 10          ; outer loop
outer_high2:
    LD BC, 60000        ; inner loop
inner_high2:
    DEC BC
    LD A,B
    OR C
    JR NZ, inner_high2
    DEC DE
    LD A,D
    OR E
    JR NZ, outer_high2
    
    pop iy
    ret


.global _blinky_asm
_blinky_asm:
    ; --------------------------
    ; Configure PB5 as GPIO output, ALT0
    ; --------------------------
    LD B, 0x00
    LD C, PC_DDR
    LD A, 0x00 ; all as output (0 = output)
    OUT (C), A

blink_loop:
    ; All GPIO C ports high
    LD A, 0xFF
    LD B, 0x00
    LD C, PC_DR
    OUT (C), A

    ; --------------------------
    ; Delay loop ~0.5 second
    ; Adjust counts as needed for 18.432 MHz
    ; --------------------------
    LD DE, 10          ; outer loop
outer_high:
    LD BC, 60000        ; inner loop
inner_high:
    DEC BC
    LD A,B
    OR C
    JR NZ, inner_high
    DEC DE
    LD A,D
    OR E
    JR NZ, outer_high

    ; All GPIO C ports low
    LD A, 0x00
    LD B, 0x00
    LD C, PC_DR
    OUT (C), A

    ; --------------------------
    ; Delay loop ~0.5 second
    ; --------------------------
    LD DE, 10
outer_low:
    LD BC, 60000
inner_low:
    DEC BC
    LD A,B
    OR C
    JR NZ, inner_low
    DEC DE
    LD A,D
    OR E
    JR NZ, outer_low

    JR blink_loop



.global	_abort
_abort:
    JR .

; Clear the memory (the heap used for dynamic variables)
; ------------------------------------------------------
;
; Location of BSS is defined by the labels (coming from linker_script)
;   ___low_bss
;   ___len_bss
;
.section .init.bss
	local _clear_bss
_clear_bss:
    ld bc, ___len_bss
 	ld 	hl, ___low_bss
 	ld 	de, ___low_bss+1
 	ld 	(hl), 0
 	ldir 					; copy 0 from previous location to next
 	ret

.section	.text
	.global	_atexit
_atexit:
	.global	_on_exit
    ; nothing 
    RET


.section	.text
	.global	__indcallhl
__indcallhl:
	jp	(hl)


.section	.text
	.global	__setflag
__setflag:

	push	bc

	push	af
	pop	bc		; c <- flags

	bit	2,c		; .if (v == 1)
	jr	z,_done		; .else go to .done
	ld	a,c		; c <- c xor %80
	xor	a,0x80
	ld	c,a

_done:
	push 	bc
	pop	af		; flags <- c
	pop	bc
	ret	

.section	.text
	.global	__frameset
__frameset:
	pop	de
	push	ix
	ld	ix,0
	add	ix,sp
	add	hl,sp
	ld	sp,hl
	ex	de,hl
	jp	(hl)


; Storage for Initialisers, Constructors, Destructors & Finalisers 
; ----------------------------------------------------------------
; C++ has constructors (ctors) and destructors (dtors)
; with initialisation (init_functions) and finalisation(fini_functions)
; I assume some "magic" is done by the linker to fill thses tables
;
	.section	.rodata
	local	init_functions
	local	fini_functions
init_functions: 				; adddress at the beginning because call from 1st to last
	d24	___init_array_functions
	d24	___init_ctors_functions
    d24 ___fini_dtors_functions
    d24 ___fini_array_functions
fini_functions:       			; address at the end because call from last to 1st


; Sections for initialisers and constructors

	.section	.init_array
init_array:
	.section	.ctors
ctors:

; Sections for destructors and finalisers

	.section	.dtors
dtors:
	.section	.fini_array
fini_array:

	extern 	_main
	extern 	__indcallhl

	extern 	___len_bss			; coming from linker_script, defined in makefile.mk
	extern 	___low_bss			; coming from linker_script, defined in makefile.mk
	extern  ___heapbot 			; coming from linker_script, defined in makefile.mk
	extern 	__stack				; defined in makefile.mk


	extern	___fini_array_count
	extern	___init_array_count
	extern	___init_array_functions
	extern	___init_ctors_functions
    extern ___fini_dtors_functions
    extern ___fini_array_functions

    extern _sidata
    extern _sdata
    extern _edata
    extern _initdata_len
