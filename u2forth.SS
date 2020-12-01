
;
;	ATMEGA8, internal clock 8 MHz, USART 9600,8,N,1
;
;	u2forth
;	
;	Alvaro Gomes Sobral Barcellos
;
;	first one
;  
;   The first register is always the target register 
;	where the result is written to!
;
		.NOLIST
		.LIST

;		.device "ATMEGA8"

;
; 	.equ assign a label as constant
;
		.equ	SRAM_START	=	0x100
		.equ	SRAM_SIZE	=	0x400
		.equ	SRAM_END    =	0x4FF
		.equ	STACK_SIZE	=	0x20
		.equ	FALSE		= 	0x00
		.equ	TRUE		= 	0xFF
		.equ	CELL		= 	0x02
		.equ	F_IMMED		=	0x80
		.equ	F_HIDEN		=	0x40
		.equ	F_RESER		=	0x20
		.equ	F_MASKS		=	0x1F

;
;	.set assign a value to a label
;
		.set	SPP_TOP		=	SRAM_END
		.set	RSP_TOP		=	SPP_TOP - STACK_SIZE
		.set	PSP_TOP		=	RSP_TOP - STACK_SIZE

;
;	.def assign a name to a register
;
		.def 	__SREG__ = 0x3f
		.def	__SP_H__ = 0x3e
		.def	__SP_L__ = 0x3d

		.def 	_work_	= r0	; generic use
		.def 	_zero_	= r1	; always zero
		.def	ftoh	= r31	; Z for access sram and flash memory
		.def	ftol	= r30	; Z for access sram and flash memory
		.def	rsph	= r29	; Y return stack pointer
		.def	rspl	= r28	; Y return stack pointer
		.def	psph	= r27	; X parameter stack pointer
		.def	pspl	= r26	; X parameter stack pointer
		.def	iph	= r25	; instruction pointer
		.def	ipl	= r24	; instruction pointer
		.def	wh	= r23	; work registers
		.def	wl	= r22	; work registers
		.def	nh	= r21	; second value parameter stack
		.def	nl	= r20	; second value parameter stack
		.def	th	= r19	; fist value parameter stack
		.def	tl	= r18	; fist value parameter stack

.MACRO BYE

.ENDMACRO

#define	BITMASK(x) (x & F_MASKS)

;
.dseg	; start data segment (sram)
.org 	0x00060
label:	.byte	2;
;
;
.cseg	; start code segment (flash)
.org	0x00000


      	rjmp   RESET        ; Reset Handler
      	reti	;   	rjmp   EXT_INT0     ; IRQ0 Handler
        reti   	;      	rjmp   EXT_INT1     ; IRQ1 Handler
        reti   	;      	rjmp   TIM2_COMP    ; Timer2 Compare Handler
        reti   	;      	rjmp   TIM2_OVF     ; Timer2 Overflow Handler
        reti   	;      	rjmp   TIM1_CAPT    ; Timer1 Capture Handler
        reti   	;      	rjmp   TIM1_COMPA   ; Timer1 CompareA Handler
        reti   	;      	rjmp   TIM1_COMPB   ; Timer1 CompareB Handler
        reti   	;      	rjmp   TIM1_OVF     ; Timer1 Overflow Handler
        reti   	;      	rjmp   TIM0_OVF     ; Timer0 Overflow Handler
        reti   	;      	rjmp   SPI_STC      ; SPI Transfer Complete Handler
        reti   	;      	rjmp   USART_RXC    ; USART RX Complete Handler
        reti  	;      	rjmp   USART_UDRE   ; UDR Empty Handler
        reti   	;      	rjmp   USART_TXC    ; USART TX Complete Handler
        reti   	;      	rjmp   ADC          ; ADC Conversion Complete Handler
        reti   	;      	rjmp   EE_RDY       ; EEPROM Ready Handler
        reti   	;      	rjmp   ANA_COMP     ; Analog Comparator Handler
        reti   	;      	rjmp   TWSI         ; Two-wire Serial Interface Handler
        reti   	;      	rjmp   SPM_RDY      ; Store Program Memory Ready Handler;



.global main
        .type   main, @function
main:
;        in __tmp_reg__,__SREG__
;        in r28,__SP_L__
;        in r29,__SP_H__
;        sbiw r28,15
; 		cli
;        out __SP_H__,r29
;        out __SP_L__,r28
;        out __SREG__,__tmp_reg__

RESET: 	; Set Stack Pointer to top of RAM

;	clear interrupts
		cli 
;	init r1 as zero
		eor r1, r1					; exclusive or, xor
		out 0x3f, r1				; clear sreg
;	init real sp at end of sram
		ldi r0, hi(SRAM_END)
		out sph, r0
		ldi r0, lo(SRAM_END)
		out spl, r0
      	sei                   		; Enable interrupts
BYE:
;	init instruction pointer and etc
		eor iph, iph
		eor ipl, ipl
		eor th, th
		eor tl, tl
		eor nh, nh
		eor nl, nl
		eor wh, wh
		eor wl, wl

ABORT:
;	init return stack
		ldi yh, hi(RSP_TOP)
		ldi yl, lo(RSP_TOP)

QUIT:
;	init parameter stack
		ldi xh, hi(PSP_TOP)
		ldi xl, lo(PSP_TOP)

.MACRO $PPUSH
		sti th, -X
		sti tl, -X
.ENDMACRO

.MACRO $PPULL
		ldi tl. X+
		ldi th, X+
.ENDMACRO

.global roulette
        .type   roulette, @object
        .size   roulette, 37
roulette:
        .byte   0
        .byte   32
        .byte   15
        .byte   19
        .byte   4
        .byte   21
        .byte   2
        .byte   25
        .byte   17
        .byte   34
        .byte   6
        .byte   27
        .byte   13
        .byte   36
        .byte   11
        .byte   30
        .byte   8
        .byte   23
        .byte   10
        .byte   5
        .byte   24
        .byte   16
        .byte   33
        .byte   1
        .byte   20
        .byte   14
        .byte   31
        .byte   9
        .byte   22
        .byte   18
        .byte   29
        .byte   7
        .byte   28
        .byte   12
        .byte   35
        .byte   3
        .byte   26

