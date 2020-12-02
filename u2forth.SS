
/*
 *  DISCLAIMER:
 *
 *  Copyright © 2020, Alvaro Barcellos,
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
*/

;----------------------------------------------------------------------
;
;	02/12/2020
;
;	u2forth
;
;	inspired on eforth from books and papers from C. H. Ting
;
;	a experience for small microcontrolers
;
;	emulates a virtual uC really
;
;	still no interrupts
;	still no multitasks
;
;	forth for ATMEGA8, 8k flash, 1k SRAM, 
;		internal clock 8 MHz, USART 9600,8,N,1
;
;	using GCC avr-as -mmcu=atmega8 
;	
;	Alvaro Gomes Sobral Barcellos
;
;   "The first register is always the target register !"
;
		.NOLIST
		.LIST

;----------------------------------------------------------------------
;		.device "ATMEGA8"

;----------------------------------------------------------------------
;
; 	 assign a label as constant
;
		SRAM_START	=	0x100
		SRAM_SIZE	=	0x400
		SRAM_END    =	0x4FF
		STACK_SIZE	=	0x20
		FALSE		= 	0x00
		TRUE		= 	0xFF
		CELL		= 	0x02
		F_IMMED		=	0x80
		F_HIDEN		=	0x40
		F_RESER		=	0x20
		F_MASKS		=	0x1F

;----------------------------------------------------------------------
;
;	.set assign a value to a label
;
		SPP_TOP		=	SRAM_END
		RSP_TOP		=	SPP_TOP - STACK_SIZE
		PSP_TOP		=	RSP_TOP - STACK_SIZE

;----------------------------------------------------------------------
;
;	 assign a name to a register
;
		 __SREG__ = 0x3f
		__SP_H__ = 0x3e
		__SP_L__ = 0x3d

		_work_	= r0	; generic use
		_zero_	= r1	; always zero

		iph		= r31	; Z instruction pointer for access sram and flash memory
		ipl 	= r30	; Z instruction pointer for access sram and flash memory
		rsph	= r29	; Y return stack pointer for access sram
		rspl	= r28	; Y return stack pointer for access sram
		psph	= r27	; X parameter stack pointer for access sram
		pspl	= r26	; X parameter stack pointer for access sram

		th	= r25	; fist value parameter stack
		tl	= r24	; fist value parameter stack
		nh	= r23	; second value parameter stack
		nl	= r22	; second value parameter stack
		wh	= r21	; work registers
		wl	= r20	; work registers

;----------------------------------------------------------------------
; flags for words
		F_IMMED = 0x080
		F_COMPD = 0x040
		F_HIDDE = 0x020
		F_MASKS = 0x01F

;----------------------------------------------------------------------
; version information
		vers	= 1
		ions	= 0

;----------------------------------------------------------------------
; default values have extra last letter
		BASEE = 16

		BS = 8
		LF = 10
		CR = 13
		ESC = 27

		CELL = 2
		FALSE = 0x0000
		TRUE = 0xFFFF

		STKSZ = 32
		SPP	= RAMEND
		RSPP = SPP - STKSZ
		PSPP = RSPP - STKSZ

		TIBB = 0x0
		PAD0 = 0x0
		PAD1 = 0x0
		DPP = 0x0
		UPP = 0x0

;----------------------------------------------------------------------
; start value for reverse linked list
;
.set _LINK = 0x0

;----------------------------------------------------------------------
; header of word in dictionary
.macro CODE 
.dw  _LINK * 2
.set _LINK = pc
.db	@0,@1
.endm

;----------------------------------------------------------------------
.macro rspush 
		st -Y, @0
		st -Y, @1
.endm

;----------------------------------------------------------------------
.macro rspull 
		ld @1, Y+
		ld @0, Y+
.endm

;----------------------------------------------------------------------
.macro pspush
		st -X, @0
		st -X, @1
.endm

;----------------------------------------------------------------------
.macro pspull
		ld @1, X+
		ld @0, X+
.endm

;----------------------------------------------------------------------
.macro	peek 
		.if (@1 < $40) 
			in @0, @1
		.else
			lds @0, @1
		.endif
.endm

;----------------------------------------------------------------------
.macro	poke
		.if (@1 < $40) 
			out @0, @1
		.else
			sts @0, @1
		.endif
.endm

;----------------------------------------------------------------------
.macro ipread
		lpm @0, Z+
.endm


#define	BITMASK(x) (x & F_MASKS)

;----------------------------------------------------------------------
;
.DSEG	; start data segment (sram)
.ORG 	0x00060
label:	.byte	2;

.dw	BASEE	; BASE
.dw 0x0		; TMP
.dw 0x0 	; SPAN
.dw 0x0 	; >IN
.dw 0x0 	; #TIB
.dw 0x0 	; HLD 
.dw 0x0 	; CSP
.dw 0x0 	; CONTEXT
.dw 0x0 	; CURRENT
.dw 0x0 	; CURSOR
.dw 0x0 	; HANDLER
.dw 0x0 	; LAST

;----------------------------------------------------------------------
; pointer to buffers
.dw TIBB	; TIB0 
.dw PAD0	; PAD0 
.dw PAD1	; PAD1 
.dw 0x0 	; DP
.dw 0x0 	; UP
.dw 0x0 	; SP0
.dw 0x0 	; RP0

;----------------------------------------------------------------------
; pointers to words
.dw 0x0		; '?KEY
.dw 0x0		; 'EMIT
.dw 0x0		; 'EXPECT
.dw 0x0		; 'TAP
.dw 0x0		; 'ECHO
.dw 0x0		; 'PROMPT
.dw 0x0		; 'EVAL
.dw 0x0		; 'NUMBER
.dw 0x0		; 'NAME

;----------------------------------------------------------------------
;----------------------------------------------------------------------
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
        reti   	;      	rjmp   TIM0_OVF     ; Time_work_ Overflow Handler
        reti   	;      	rjmp   SPI_STC      ; SPI Transfer Complete Handler
        reti   	;      	rjmp   USART_RXC    ; USART RX Complete Handler
        reti  	;      	rjmp   USART_UDRE   ; UDR Empty Handler
        reti   	;      	rjmp   USART_TXC    ; USART TX Complete Handler
        reti   	;      	rjmp   ADC          ; ADC Conversion Complete Handler
        reti   	;      	rjmp   EE_RDY       ; EEPROM Ready Handler
        reti   	;      	rjmp   ANA_COMP     ; Analog Comparator Handler
        reti   	;      	rjmp   TWSI         ; Two-wire Serial Interface Handler
        reti   	;      	rjmp   SPM_RDY      ; Store Program Memory Ready Handler;



;----------------------------------------------------------------------
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

;----------------------------------------------------------------------
RESET: 	; Set Stack Pointer to top of RAM

;	clear interrupts
		cli 
;	init r1 as zero
		eor r1, r1					; exclusive or, xor
		out 0x3f, r1				; clear sreg
;	init real sp at end of sram
		ldi _work_, hi(SRAM_END)
		out sph, _work_
		ldi _work_, lo(SRAM_END)
		out spl, _work_
      	sei                   		; Enable interrupts
;----------------------------------------------------------------------
;	init instruction pointer and etc
CODE 3, "BYE"
BYE:
		eor iph, iph
		eor ipl, ipl
		eor th, th
		eor tl, tl
		eor nh, nh
		eor nl, nl
		eor wh, wh
		eor wl, wl

;----------------------------------------------------------------------
;	init return stack
CODE 5, "ABORT"
ABORT:
		ldi yh, hi(RSP_TOP)
		ldi yl, lo(RSP_TOP)

;----------------------------------------------------------------------
CODE 4, "QUIT"
QUIT:
;	init parameter stack
		ldi xh, hi(PSP_TOP)
		ldi xl, lo(PSP_TOP)



;----------------------------------------------------------------------
;
; start of dictionary
;
;----------------------------------------------------------------------
;	read a opcode in [ip] 
CODE 4, "WXYZ"
WXYZ:
; trampoline 
		lpm _work_, Z+
		;? w = pc
		add wl, _work_
		adc wh, _zero_
		push wl
		push wh
		ret
		; rjmp WHERETO

;----------------------------------------------------------------------
;	trampoline for 254 primitives
;
		rjmp WXYZ
		rjmp 
;----------------------------------------------------------------------
;

;----------------------------------------------------------------------
;	receive char and put true or if none put false
CODE 4,"?KEY"
WQRX:
WQKEY:

;----------------------------------------------------------------------
;	send char to tx usart
CODE 4,"EMIT"
WEMIT:
WTXTO:

;----------------------------------------------------------------------
;	init usart
CODE, 2,"!IO"
WSTOIO:

;----------------------------------------------------------------------
;	ok	push a value from flash
CODE, 4,"doLIT"
WDOLIT:
		pspush nl, nh
		movw nl, tl
		ipread tl
		ipread th
		rjmp WXYZ

;----------------------------------------------------------------------
;	test index loop in rsp, if 0< exit loop else next 
CODE, 4, "doNext"
WDONEXT:

;----------------------------------------------------------------------
;	ok	if 0 branch
CODE, 7,"?BRANCH"
WQBRAN:
		or th, tl
		movw tl, nl
		pspull nl, nh
		breq WBRAN
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	branch
CODE, 6,"BRANCH"
WBRAN:
		ipread  wl
		ipread  wh
		movw zl, wl
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	exit	pop new ip from return stack
CODE 4, "EXIT"
WEXIT:
		rspull zl, zh

;----------------------------------------------------------------------
;	ok  enter
CODE 5, "ENTER"
WENTER:
		ipread wl
		ipread wh
		rspush zl, zh
		movw zl, wl
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok 	2drop
CODE 5, "2DROP"
WTWODROP:
		pspull tl, th
		pspull nl, nh
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	2dup
CODE 4, "2DUP"
WTWODUP:
		pspush nl, nh
		pspush tl, th
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	to	
CODE 1, "!"
WTO:
		rspush xl, xh
		movw xl, tl
		pspush nl, nh
		rspull xl, xh
		rjmp W2DROP

;----------------------------------------------------------------------
;	ok	at
CODE 1, "@"
WAT:
		rspush xl, xh
		movw xl, tl
		pspull tl, th
		rspull xl, xh
		rjmp WXYZ

;----------------------------------------------------------------------
;	cstore
CODE 1, "C!"
WCTO:

;----------------------------------------------------------------------
;	cat
CODE 1, "C@"
WCAT:

;----------------------------------------------------------------------
;	ok	R@
CODE 2, "R@"
WRAT:
		pspush nl, nh
		movw nl, tl 
		rspull tl, th
		sbiw y, 2
		rjmp WYXZ

;----------------------------------------------------------------------
;	ok	R>
CODE 2, "R>"
WRTO:
		pspush nl, nh
		movw nl, tl 
		pspull tl, th
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	>R
CODE 2, ">R"
WTOR:
		rspush tl, th
		rjmp WDROP

;----------------------------------------------------------------------
:	ok   RP@
CODE 3, "RP@"
		pspush nl, nh
		movw nl, tl
		movm tl, rspl
		rjmp WXYZ
WRPAT:

;----------------------------------------------------------------------
:   RP!
CODE 3, "RP!"
WRPTO:
		movm rspl, tl
		rjmp WDROP

;----------------------------------------------------------------------
;	ok	DROP
CODE 4, "DROP"
WDROP:
		movw tp, nl 
		pspull nl, nh
		rjmp WXYZ

;----------------------------------------------------------------------
:   ok 	DUP
CODE 3, "DUP"
WDUP:
		pspush nl, nh
		movw tl, nl
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok 	SWAP
CODE 4, "SWAP"
WSWAP:
		movw wl, nl
		movw nl, tl
		move tl, wl
		rjmp WXYZ

;----------------------------------------------------------------------
:   ok 	OVER
CODE 4, "OVER"
WOVER:
		movw wl, nl
		ppush nl, nh
		movw nl, tl
		movw tl, wl
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	0<
CODE 2,"0<"
WZLESS:
		tst th
		mov tl, _zero_
		mov th, _zero_
		brge ISFALSE
ISTRUE:
		sbiw tl, 1
ISFALSE
		rjmp WXYZ

;----------------------------------------------------------------------
;	ok	0=
CODE 2,"0="
WZEQU:
		or th, tl
		mov tl, _zero_
		mov th, _zero_
		brge ISFALSE
		rjmp ISTRUE

;----------------------------------------------------------------------
:   ok	XOR
CODE 3, "XOR"
WXOR:
		eor nl, tl
		eor nh, th
		rjump WDROP
		
;----------------------------------------------------------------------
:   ok	AND
CODE 3, "AND"
WAND:
		and nl, tl
		and nh, th
		rjump WDROP

;----------------------------------------------------------------------
;	ok	OR
CODE 2, "OR"
WOR:
		or  nl, tl
		or  nh, th
		rjump WDROP

;----------------------------------------------------------------------
;	ok	INV
CODE 3, "INV"
WINV:
		com tl
		com th
		rjump WXYZ

;----------------------------------------------------------------------
;	ok	NEG
CODE 3, "NEG"
WNEG:
		neg tl
		neg th
		rjump WXYZ

;----------------------------------------------------------------------
;	ok	2*
CODE 3, "2*"
WSHL:
		lsl tl
		rol th
		rjump WXYZ

;----------------------------------------------------------------------
;	ok	2/
CODE 3, "2/"
WSHR:
		lsr th
		ror tl
		rjump WXYZ

;----------------------------------------------------------------------
; 	UM+
CODE 3, "UM+"
WUPLUS:
		add nl, tl
		adc nh, th
		eor tl
		eor th
		rol tl
		rjmp WXYZ

;----------------------------------------------------------------------
;
CODE 4, "CMOVE" ( tos from, n to, w many
WCMOVE:
		; WARNING No bound check
		; tos 	source
		; n		destination
		; w		1 or many, 0 does nothing

		; get the counter
		pspull wl, wh
		
		; preserve psp into rsp
		rspush xl, xh

UCMOME1:
		; decrease counter
		sbiw wl, 1
		brlt UCMOVE2

		; read a byte
		movw xl, tl
		ld r0, X+
		movw tl, xl

		; write a byte
		movw xl, nl
		st X+, r0
		movw nl, xl

		; again
		rjmp UCMOVE1

UCMOVE2:
		; restore psp from rsp
		rspull xl, xh

WTHREDROP:
		; drop arguments
		adiw xl, 1
		rjmp WTWODROP
		 



;----------------------------------------------------------------------
;----------------------------------------------------------------------
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

