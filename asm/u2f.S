
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

/* get some magic constants */

#include <avr/io.h>

/*
just dont compile by sdt
#include <avr/eeprom.h>
#include <avr/wdt.h>
*/

;----------------------------------------------------------------------
;
; 02/12/2020
;
; Alvaro Gomes Sobral Barcellos
;
; u2forth
;

/*

  inspired on eforth from books and papers from C. H. Ting
 
  just experience for small microcontrolers
 
  emulates a virtual uCi, really, really, just using SEG and PC, ((0x3D) + 0x20) is reserved for interrups (future)
 
  still no interrupts
 
  still no multitasks
 
;----------------------------------------------------------------------
; dictionary structure
;
 .word  link     link to previous
 .byte  size     sizeof name OR mask 0x1F
 .ascii "name"   name, plus a byte 0 if size is odd
 .byte  opcode   opcode
 .word  param,   many

;----------------------------------------------------------------------

22/01/2021
	maybe include DEFER and IS

12/01/2021
	moved some documentation to howto.inc
	rewrote internal interpreter for core, enter, exit,
	new core for 0, 1, 2, 3, opcodes and new _core for other opcodes as trampoline
	need move leafs to big table with fixed opcodes 
	need move all assembler to this file

08/01/2021	
	rewrote for all primitive ends with EXIT not CORE
	this permit that all words at table, twigs or leaves, runs with same end code
	


*/

     .NOLIST

     .LIST

;----------------------------------------------------------------------
;
;    MUST use gnu cpp 
;    use with .S (upper S) or
;    use with -x assembler-with-cpp
;
;----------------------------------------------------------------------
; generic use
#define         _work_    r0    
; .set _work_ , r0    

; always zero
#define         _zero_    r1    
; .set _zero_ , r1

; Z instruction pointer for access sram and flas_high memory
#define         ip_low     r30    
;.set	ipl,	r30

; Z instruction pointer for access sram and flas_high memory
#define         ip_high     r31    
;.set	iph,	r31

; Y return stack pointer for access sram
#define         rsp_low    r28    
;.set	rspl,	r28

; Y return stack pointer for access sram
#define         rsp_high    r29    
;.set	rsph,	r29

; X parameter stack pointer for access sram
#define         psp_low    r26    
;.set	pspl,	r26

; X parameter stack pointer for access sram
#define         psp_high    r27    
;.set	psph,	r27

; work registers
#define         wrk_low    r24    
;.set	wl,	r24

; work registers
#define         wrk_high    r25    
;.set	wh,	r25

; second value parameter stack
#define         nds_low    r22    
;.set	nl,	r22

; second value parameter stack
#define         nds_high    r23    
;.set	nh, r23

; fist value parameter stack
#define         tos_low    r20    
;.set	tl,	r20

; fist value parameter stack
#define         tos_high    r21    
;.set	th,	r21

;----------------------------------------------------------------------;
; assign stacks address
; for atmega8
;
        SRAM_START = 0x060
        USER_START = 0x0C0
        SRAM_END = 0x45F

;----------------------------------------------------------------------
;
; default sizes forth83
		SPU_SIZE = 32
        PSP_SIZE = 64
		RSP_SIZE = 48
		TIB_SIZE = 80
		PAD_SIZE = 84

;----------------------------------------------------------------------
; grows downwards SP = SP - 1
        SPP_TOP = SRAM_END
        RSP_TOP = SPP_TOP - SPU_SIZE
        PSP_TOP = RSP_TOP - RSP_SIZE

;----------------------------------------------------------------------
; grows upwards PT = PT + 1
        TIB_TOP = PSP_TOP - PSP_SIZE - TIB_SIZE

;----------------------------------------------------------------------
; grows upwards PT = PT + 1
        PAD_TOP = TIB_TOP - PAD_SIZE
;
;----------------------------------------------------------------------
;
; flags for words
;
        F_IMMEDIATE = 0x080
        F_COMPILE = 0x040
        F_HIDDEN = 0x020

        F_MASKZ = 0x01F
        F_MASKO = 0x0E0

;---------------------------------------------------------------------
;
; default base
;
        BASEE = 16

;---------------------------------------------------------------------
;
; default cell size
;
		CELL_SZ = 2

;---------------------------------------------------------------------
;
; default init cell, ????
;
		_INIT = 200

;----------------------------------------------------------------------
;
; version information
;----------------------------------------------------------------------
;
; version information
;
.equ version, 0x0100

;----------------------------------------------------------------------
;
; start reverse linked list
;
.set _LINK , 0x0
.set _THIS , 0x0

;----------------------------------------------------------------------
;
; idents for first opcode in macros
;
.equ isNOOP, 0
.equ isLEAF, 1
.equ isTWIG, 2

;----------------------------------------------------------------------
;
; header of word in dictionary
; opcode for CORE ( execute a opcode )
; must end with CORE :)
;
.macro LEAF size , name
.set _THIS, .
.word _LINK
.set _LINK, _THIS 
.byte \size
.ascii "\name"
;was odd, so we need to pad it
.if ! ( \size & 1 ) 
.byte 0
.endif
.byte isLEAF
.balign 2
.endm

;----------------------------------------------------------------------
;
; header of word in dictionary
; opcode for TWIG ( as colon )
; must end with EXIT :)
;
.macro TWIG size , name
.set _THIS, .
.word _LINK
.set _LINK, _THIS 
.byte \size
.ascii "\name"
;was odd, so we need to pad it
.if ! ( \size & 1 ) 
.byte 0
.endif
.byte isTWIG
.balign 2
.endm

;----------------------------------------------------------------------
.macro rspush low , high
        st -Y , \low
        st -Y , \high
.endm

;----------------------------------------------------------------------
.macro rspull low , high
        ld \high , Y+
        ld \low , Y+
.endm

;----------------------------------------------------------------------
.macro pspush low , high
        st -X , \low
        st -X , \high
.endm

;----------------------------------------------------------------------
.macro pspull low , high
        ld \high , X+
        ld \low , X+
.endm

;----------------------------------------------------------------------
; also io@
.macro peek byte , address
        .if (\address < $40)
         in \byte , \address
        .else
         lds \byte , \address
        .endif
.endm

;----------------------------------------------------------------------
; also io!
.macro poke byte , address
        .if (\address < $40)
         out \byte , \address
        .else
         sts \byte , \address
        .endif
.endm

;----------------------------------------------------------------------
.macro ipread register
       lpm \register , Z+
.endm

;----------------------------------------------------------------------
;
; code segment, flash
;
.section .text
; .org 0x00000
.global main
main:

;----------------------------------------------------------------------
;
; interrup vector table
;
;----------------------------------------------------------------------

        rjmp RESET ; Reset Handler
        reti ; rjmp EXT_INT0 ; IRQ0 Handler
        reti ; rjmp EXT_INT1 ; IRQ1 Handler
        reti ; rjmp TIM2_COMP ; Timer2 Compare Handler
        reti ; rjmp TIM2_OVF ; Timer2 Overflow Handler
        reti ; rjmp TIM1_CAPT ; Timer1 Capture Handler
        reti ; rjmp TIM1_COMPA ; Timer1 CompareA Handler
        reti ; rjmp TIM1_COMPB ; Timer1 CompareB Handler
        reti ; rjmp TIM1_OVF ; Timer1 Overflow Handler
        rjmp TIM0_OVF ; Timer0 Overflow Handler
        reti ; rjmp SPI_STC ; SPI Transfer Complete Handler
        reti ; rjmp USART_RXC ; USART RX Complete Handler
        reti ; rjmp USART_UDRE ; ((0x0C) + 0x20) Empty Handler
        reti ; rjmp USART_TXC ; USART TX Complete Handler
        reti ; rjmp ADC ; ADC Conversion Complete Handler
        reti ; rjmp EE_RDY ; EEPROM Ready Handler
        reti ; rjmp ANA_COMP ; Analog Comparator Handler
        reti ; rjmp TWSI ; Two-wire Serial Interface Handler
        reti ; rjmp SPM_RDY ; Store Program Memory Ready Handler;

;----------------------------------------------------------------------
;
;	timer0 prescale using 64, 
;
;	count as 61, about 1008,07 Hz
;	count as 62, about  992,07 Hz, 
;
;	counter cotinues while inside ? 
;   without these instructions ?
;
TIM0_OVF:
;	save flags and stop interrups
		in R5, __SREG__
		cli
;	reset watch dog
		wdr
;	get counter
		lds R3, TIMER
		lds R2, TIMER+1
; 	increase counter
		eor	R4, R4
		inc R4
		add R2, R4
		dec R4
		adc R2, R4
;	put counter
		sts TIMER, R3
		sts TIMER+1, R2
;	adjusts counter
;		out TCNT0H, R2
;		out TCNT0L, R3

;	load flags and return
		out __SREG__, R5
		sei
		reti

;----------------------------------------------------------------------
; watch dogh
;	WDTCSR = bit (WDIE) | bit (WDP2) | bit (WDP1);    // set WDIE, and 1 second delay
#define	WDIE	6
#define WDP2	2
#define WDP1	1
#define WDE		3
#define WDCE	4

; reset WDT
		wdr
;
;  define watch dog counter
;		??? code
;
; write logical one to WDCE and WDE
;		in wrk_low, WDTCR
;		ori wrk_low, (1<<WDCE)|(1<<WDE)
;		out WDTCR, wrk_low		
; turn off wd
;		ldi wrk_low, (0<<WDE)
;		out WDTRC, wrk_low
; set WDIE, and 1 second delay
;		ori wrk_low, (1<<WDIE)|(1<<WDP2)|(1<<WDP1)
;		out WDTCR, wrk_low

; Enable interrupts
		sei

;----------------------------------------------------------------------
;
; start of dictionary
;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;
; init instruction pointer and etc
;
        __SREG__ = 0x3f
        __SP_H__ = 0x3e
        __SP_L__ = 0x3d

;----------------------------------------------------------------------
; 
LEAF 5, "RESET"
RESET:
; clear interrupts
        cli
; init _zero_as zero
        eor _zero_, _zero_; exclusive or, xor
        out __SREG__, _zero_; clear sreg
; init real sp at end of sram
        ldi wrk_high, hi8(SPP_TOP)
        out __SP_H__, wrk_high
        ldi wrk_low, lo8(SPP_TOP)
        out __SP_L__, wrk_low

;----------------------------------------------------------------------
; init instruction pointer and etc
LEAF 3, "BYE"
BYE:
        ; clear tos, sec, wrk

        eor tos_high, tos_high
        eor tos_low, tos_low
        eor nds_high, nds_high
        eor nds_low, nds_low
        eor wrk_high, wrk_high
        eor wrk_low, wrk_low

;----------------------------------------------------------------------
;
; init return stack
;
LEAF 5, "ABORT"
ABORT:
; init return stack
        ldi rsp_high, hi8(RSP_TOP)
        ldi rsp_low, lo8(RSP_TOP)

;----------------------------------------------------------------------
;
; init parameter stack
;
LEAF 4, "QUIT"
QUIT:
; init parameter stack
        ldi psp_high, hi8(PSP_TOP)
        ldi psp_low, lo8(PSP_TOP)

;----------------------------------------------------------------------
;
; init variables ????
;
; must point to real start

        ldi zh, hi8(_INIT)
        ldi zl, lo8(_INIT)
        rjmp CORE

;----------------------------------------------------------------------
; start forth,
;----------------------------------------------------------------------

;---------------------------------------------------------------------
;
;
LEAF 4, "NOOP"
NOOP:
        rjmp CORE

;----------------------------------------------------------------------
;
; ok non block, test if can receive a char ( -- 0x00 | ch 0xFF )
;
LEAF 4, "KEY?"
KEYQM:
RXAT:
        sbis 0xb, 7
        rjmp FFALSE
        in wrk_low, 0xc
        pspush nds_low, nds_high
        movw nds_low, tos_low
        rjmp FTRUE

;----------------------------------------------------------------------
;
; ok non block, test if can send a char ( ch -- ch 0x00 | 0xFF )
;
LEAF 5, "EMIT?"
EMITQM:
TXTO:
        sbis 0xb, 5
        rjmp FFALSE
        out 0xc, tos_low
        movw wrk_low, nds_low
        pspull nds_low, nds_high
        rjmp FTRUE

;----------------------------------------------------------------------
;
; init usart, from avr-gcc public code, io ports as constants
;
LEAF 3, "IO!"
IOYO:
        eor wrk_low, wrk_low
        out 0x20, wrk_low
        ldi wrk_low,lo8(52)
        out 0x9,wrk_low
        in wrk_low,0xa
        ori wrk_low,lo8(24)
        out 0xa,wrk_low
        ldi wrk_low,lo8(-114)
        out 0x20,wrk_low
        in wrk_low,0x20
        ori wrk_low,lo8(64)
        out 0x20,wrk_low
        rjmp CORE

;----------------------------------------------------------------------
; ok push a value from flash into parameter stack
LEAF 7, "LITL"
LITL:
        pspush nds_low, nds_high
        movw nds_low, tos_low
        ipread tos_low
        ipread tos_high
        rjmp CORE

;----------------------------------------------------------------------
; get address of a variable ????
LEAF 4, "doVAR"
DOVAR:
		rjmp CORE

;----------------------------------------------------------------------
;
; ok pop tos and test if less than zero, leave seg register
;
TSTOP:
        movw wrk_low, tos_low
        movw tos_low, nds_low
        pspull nds_low, nds_high
        sbiw wrk_low, 1
        ret

;----------------------------------------------------------------------
;
; ok if 0 branch ( a -- F | T )
;
LEAF 7, "?BRANCH"
QMBRANCH:
        rcall TSTOP
        breq BRANCH
        rjmp CORE

;----------------------------------------------------------------------
; ok branch
LEAF 6, "BRANCH"
BRANCH:
        ipread wrk_low
        ipread wrk_high
        rjmp GOES

;----------------------------------------------------------------------
; ok exec pop new ip from return stack
LEAF 4, "EXEC"
EXEC:
        movw wrk_low, tos_low
        movw tos_low, nds_low
        pspull nds_low, nds_high
        rjmp GOES

;----------------------------------------------------------------------
; ok exit pop new ip from return stack
LEAF 4, "EXIT"
EXIT:
        rspull zl, zh
        rjmp ENTER ; not need maybe

;----------------------------------------------------------------------
; ok enter
LEAF 5, "ENTER"
ENTER:
        ipread wrk_low
        ipread wrk_high
        rspush zl, zh
GOES:
        sbiw wrk_low, 1 ; point to opcode.
        movw zl, wrk_low
        rjmp CORE

;---------------------------------------------------------------------
;
; read a opcode in [ip]
;
LEAF 4, "CORE"
CORE:

; next instruction

        ipread r0

; try  0, 1, 2, 3

		dec r0		
		dec r0
		brlt CORE	; equal to 0 or 1
		breq ENTER	; equal to 2
		dec r0
		breq EXIT	; equal to 3
		rjmp _CORE

;----------------------------------------------------------------------
TRIDROP:
; ok drop
        ; drop arguments
        adiw xl, 1
;----------------------------------------------------------------------
; ok 2drop
LEAF 5, "2DROP"
TWODROP:
        pspull tos_low, tos_high
        pspull nds_low, nds_high
        rjmp CORE

;----------------------------------------------------------------------
; ok 2dup
LEAF 4, "2DUP"
TWODUP:
        pspush nds_low, nds_high
        pspush tos_low, tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ok 2swap ( a b c d -- c d a b )
LEAF 4, "2SWAP"
TWOSWAP:
; get b
		pspull wrk_low, wrk_high
		rspush wrk_low, wrk_high
; get a
		pspull wrk_low, wrk_high
		rspush wrk_low, wrk_high
; put c
        pspush nds_low, nds_high
; put d 
        pspush tos_low, tos_high
; get a 
		rspull nds_low, nds_high
; get b
		rspull tos_low, tos_high

        rjmp CORE

;----------------------------------------------------------------------
; ok +! to
LEAF 1, "+!"
PLUSTO:
        rspush xl, xh
        movw xl, tos_low
        ld wrk_high, X+
        ld wrk_low, X+
        add wrk_low, nds_low
        adc wrk_high, nds_high
        st -X, wrk_low
        st -X, wrk_high
        rspull xl, xh
        rjmp TWODROP

;----------------------------------------------------------------------
; ok ! to (works only in sram)
LEAF 1, "!"
TO:
        rspush xl, xh
        movw xl, tos_low
        st X+, nds_high
        st X+, nds_low
_TO1:
        rspull xl, xh
        pspush nds_low, nds_high
        rjmp TWODROP

;----------------------------------------------------------------------
; ok C!
LEAF 1, "C!"
CTO:
        rspush xl, xh
        movw xl, tos_low
        st X+, nds_low
        rjmp _TO1

;----------------------------------------------------------------------
; ok @ at (works only in sram)
LEAF 1, "@"
AT:
        rspush xl, xh
        movw xl, tos_low
        ld tos_high, x+
        ld tos_low, x+
_AT1:
        rspull xl, xh
        rjmp CORE

;----------------------------------------------------------------------
; ok C@ cat
LEAF 1, "C@"
CAT:
        rspush xl, xh
        movw xl, tos_low
        ld tos_low, x+
        eor tos_high, tos_high
        rjmp _AT1

;----------------------------------------------------------------------
; ok R@
LEAF 2, "R@"
RAT:
        pspush nds_low, nds_high
        movw nds_low, tos_low
        rspull tos_low, tos_high
        sbiw rsp_low, 1
        rjmp CORE

;----------------------------------------------------------------------
; ok R>
LEAF 2, "R>"
RGT:
        pspush nds_low, nds_high
        movw nds_low, tos_low
        rspull tos_low, tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ok >R
LEAF 2, ">R"
GTR:
        rspush tos_low, tos_high
        rjmp DROP

;----------------------------------------------------------------------
; ok RS@
LEAF 3, "RS@"
RSAT:
        movw wrk_low, rsp_low
        rjmp PUSHS

;----------------------------------------------------------------------
; ok RS!
LEAF 3, "RS!"
RSTO:
        movw rsp_low, tos_low
        rjmp DROP

;----------------------------------------------------------------------
; PS@
LEAF 4, "PS@"
PSAT:
        movw wrk_low, psp_low
        rjmp PUSHS

;----------------------------------------------------------------------
; PS!
LEAF 4, "PS!"
PSTO:
        movw psp_low, tos_low
        rjmp CORE

;----------------------------------------------------------------------
; ok ?DUP (a -- 0 | a a)
LEAF 3, "?DUP"
QMDUP:
        mov _work_, tos_low
        or _work_, tos_high
		breq _QMDUP1
        rjmp DUP
_QMDUP1:
		rjmp CORE

;----------------------------------------------------------------------
; ok DUP (a -- a a)
LEAF 3, "DUP"
DUP:
        pspush nds_low, nds_high
        movw nds_low, tos_low
        rjmp CORE

;----------------------------------------------------------------------
; ok SWAP (a b -- b a)
LEAF 4, "SWAP"
SWAP:
        movw wrk_low, nds_low
        movw nds_low, tos_low
        movw tos_low, wrk_low
        rjmp CORE
 
;----------------------------------------------------------------------
;
; ok DROP (a b -- a)
;
LEAF 4, "DROP"
DROP:
        movw tos_low, nds_low
        pspull nds_low, nds_high
        rjmp CORE

;----------------------------------------------------------------------
;
; ok (a b c -- a b c w)
; push a value or a flag, to tos
;
LEAF 5, "PUSHS"
PUSHS:
        pspush nds_low, nds_high
        movw nds_low, tos_low
        movw tos_low, wrk_low
        rjmp CORE

;----------------------------------------------------------------------
; ok ROT (a b c -- b c a)
;
LEAF 3, "ROT"
ROT:
        pspull wrk_low, wrk_high
        rjmp PUSHS

;----------------------------------------------------------------------
; ok OVER (a b -- a b a)
;
LEAF 4, "OVER"
OVER:
        movw wrk_low, nds_low
        rjmp PUSHS

;----------------------------------------------------------------------
;
; ok push a false 0x0000
;
LEAF 5, "FALSE"
ZERO:
FFALSE:
        clr wrk_low
        clr wrk_high
        rjmp PUSHS

;----------------------------------------------------------------------
;
; ok push a true 0xFFFF
;
LEAF 4, "TRUE"
ONENEG:
FTRUE:
        ser wrk_low
        ser wrk_high
        rjmp PUSHS
;----------------------------------------------------------------------
;
;	ok 
LEAF 5, "1+"
ONEPLUS:
        movw wrk_low, tos_low
        adiw wrk_low, 1
        movw tos_low, wrk_low
        rjmp CORE

;----------------------------------------------------------------------
;
;	ok
LEAF 2, "1-"
ONEMINUS:
        movw wrk_low, tos_low
        sbiw wrk_low, 1
        movw tos_low, wrk_low
        rjmp CORE

;----------------------------------------------------------------------
; ????
LEAF 8, "BITSCLEAR"
BITSCLEAR:
        com nds_low
        com nds_high
        rjmp AND

;----------------------------------------------------------------------
; ????
LEAF 7, "BITSSET"
BITSSET:
        com nds_low
        com nds_high
        rjmp AND

;----------------------------------------------------------------------
; ????
LEAF 10, "BITSTOGGLE"
BITSTOGGLE:
        com nds_low
        com nds_high
        rjmp AND

;----------------------------------------------------------------------
; ?? 0>
LEAF 2, "0>"
ZEROGT:
        rcall TSTOP
        brlt _ZEROGT1
        rjmp FFALSE
_ZEROGT1:
		rjmp FTRUE
;----------------------------------------------------------------------
; ?? 0<
LEAF 2, "0<"
ZEROLT:
        rcall TSTOP
        brlt _ZEROLT1
        rjmp FFALSE
_ZEROLT1:
		rjmp FTRUE

;----------------------------------------------------------------------
; ?? 30=
LEAF 2, "0="
ZEROEQ:
        rcall TSTOP
        breq _ZEROEQ1
        rjmp FFALSE
_ZEROEQ1:
		rjmp FTRUE

;----------------------------------------------------------------------
; ok XOR
LEAF 3, "XOR"
XOR:
        eor nds_low, tos_low
        eor nds_high, tos_high
        rjmp DROP

;----------------------------------------------------------------------
; ok AND
LEAF 3, "AND"
AND:
        and nds_low, tos_low
        and nds_high, tos_high
        rjmp DROP

;----------------------------------------------------------------------
; ok OR
LEAF 2, "OR"
OR:
        or nds_low, tos_low
        or nds_high, tos_high
        rjmp DROP

;----------------------------------------------------------------------
; ok +
LEAF 1, "+"
PLUS:
        add nds_low, tos_low
        adc nds_high, tos_high
        rjmp DROP

;----------------------------------------------------------------------
; ok -
LEAF 1, "-"
MINUS:
        sub nds_low, tos_low
        sbc nds_high, tos_high
        rjmp DROP

;----------------------------------------------------------------------
; <
LEAF 1, "<"
LTHAN:
        sub nds_low, tos_low
        sbc nds_high, tos_high
        brlt _LTHAN1
        rjmp FFALSE
_LTHAN1:
		rjmp FTRUE

;----------------------------------------------------------------------
; >
LEAF 1, ">"
GTHAN:
        sub nds_low, tos_low
        sbc nds_high, tos_high
        brge _GTHAN1
        rjmp FFALSE
_GTHAN1:
		rjmp FTRUE

;----------------------------------------------------------------------
; >
LEAF 1, "="
EQUAL:
        sub nds_low, tos_low
        sbc nds_high, tos_high
        brge _EQUAL1
        rjmp FFALSE
_EQUAL1:
		rjmp FTRUE

;----------------------------------------------------------------------
; ok INV
LEAF 3, "INV"
INV:
        com tos_low
        com tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ok NEG
LEAF 3, "NEG"
NEG:
        neg tos_low
        neg tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ok 2*
LEAF 2, "2*"
SHL:
        lsl tos_low
        rol tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ok 2/
LEAF 2, "2/"
SHR:
        asr tos_high
        ror tos_low
        rjmp CORE

;----------------------------------------------------------------------
; UM+
LEAF 3, "UM+"
UPLUS:
        ; do signed plus
        add nds_low, tos_low
        adc nds_high, tos_high
        ; preserve carry at tos
        eor tos_low, tos_low
        eor tos_high, tos_high
        rol tos_low
        rjmp CORE

;----------------------------------------------------------------------
;
; CMOVE copy from source++ to destination++, decrease w
LEAF 5, "CMOVE"
CMOVE:
        ; WARNING No bound check
        ; tos source
        ; n destination
        ; w 1 or many, 0 does nothing

        ; get the counter
        pspull wrk_low, wrk_high

        ; preserve psp into rsp
        rspush psp_low, psp_high

        ; no offset

_CMOVE1:
        ; decrease counter
        sbiw wrk_low, 1
        brlt _CMOVE2

        ; read a byte
        movw xl, tos_low
        ld _work_, X+
        movw tos_low, xl

        ; write a byte
        movw xl, nds_low
        st X+, r0
        movw nds_low, xl

        ; again
        rjmp _CMOVE1

_CMOVE2:
        ; restore psp from rsp
        rspull psp_low, psp_high

;----------------------------------------------------------------------
; CMOVE> copy from source+w to destination+w, decrease w
LEAF 5, "CMOVE>"
CMOVEGT:
        ; WARNING No bound check
        ; tos source
        ; n destination
        ; w 1 or many, 0 does nothing

        ; get the counter
        pspull wrk_low, wrk_high

        ; preserve psp into rsp
        rspush psp_low, psp_high

        ; offset predecrements

        adiw wrk_low, 1

        add tos_low, wrk_low
        adc tos_high, wrk_high

        add nds_low, wrk_low
        adc nds_high, wrk_high

        sbiw wrk_low, 1

_CMOVEGT1:
        ; decrease counter
        sbiw wrk_low, 1
        brlt _CMOVEGT2

        ; read a byte
        movw xl, tos_low
        ld _work_, -X
        movw tos_low, xl

        ; write a byte
        movw xl, nds_low
        st -X, r0
        movw nds_low, xl

        ; again
        rjmp _CMOVEGT1

_CMOVEGT2:
        ; restore psp from rsp
        rspull psp_low, psp_high

        rjmp TRIDROP

;----------------------------------------------------------------------
;
; ok ALIGN, easy as cell is 2 bytes
; if lsb set sum 1
;
LEAF 5, "ALIGN"
ALLIGN:
		movw wrk_low, tos_low
		adiw wrk_low, 1
		movw tos_low, wrk_low
        lsr tos_low
        lsl tos_low
        rjmp CORE

;----------------------------------------------------------------------
;
; ok CELL is 2 ; size of a cell
;
LEAF 2, "CELL"
CELLSZ:
        ldi wrk_low, CELL_SZ
        eor wrk_high, wrk_high
        rjmp PUSHS

;----------------------------------------------------------------------
;
; ok CELL is 2, multiply by 2
;
LEAF 5, "CELLS"
CELLS:
        rjmp SHL

;----------------------------------------------------------------------
;
; ok add CELL_SZ
;
LEAF 5, "CELL+"
CELLPLUS:
        movw wrk_low, tos_low
        adiw wrk_low, CELL_SZ
        movw tos_low, wrk_low
        rjmp CORE

;----------------------------------------------------------------------
;
; ok sub CELL_SZ
;
LEAF 5, "CELL-"
CELLMINUS:
        rol nds_high
        rol tos_low
        rol tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ????
;
; http://www.avr-asm-tutorial.net/avr_en/apps/random_tn13/random_calc_tn13.html
;
;	good seeds
;
;	B167 4A3C 9879 B61E 7B26 
;	A858 1F88 50D5 419D 5537
;	0224 0527 5EB6 1E6D BCDC
;	92FF C206 0ECD 9361 2823
;	BE0B B303 6462 0E4C 3D24
;
LEAF 3, "_RND_"
RND:
;	load seed
		lds wrk_low, _RANDW
		lds wrk_high, _RANDW + 1
;
;	run magics
;
		eor	wrk_low, wrk_high
		swap wrk_low
		add wrk_high, wrk_low

;	save seed
		sts _RANDW, wrk_low
		sts _RANDW + 1, wrk_high
;
		rjmp PUSHS
	
;----------------------------------------------------------------------
;
; trampoline for 127 primitives
;
;----------------------------------------------------------------------
;
; order IS opcode sequence
;
;---------------------------------------------------------------------
JUMPS:

;---------------------------------------------------------------------
;
; do not change order, hard coded in macros
; opcode 0, 1, 2, 3, 4, 5, 6, 7
;
;---------------------------------------------------------------------
.balign 2

;---------------------------------------------------------------------
; those are checked first and directly
;
;        rjmp NOOP ; 
;        rjmp CORE ; 
;        rjmp ENTER ; 
;        rjmp EXIT ; 

;---------------------------------------------------------------------
; those are reserved
;
        rjmp RESET ; reserved
        rjmp CORE ; reserved
        rjmp CORE ; reserved
        rjmp CORE ; reserved

;---------------------------------------------------------------------
;
; could change order
;
;---------------------------------------------------------------------
.balign 2

        rjmp ABORT 
        rjmp ALLIGN 
        rjmp AND 
        rjmp AT 
        rjmp BITSCLEAR 
        rjmp BITSSET 
        rjmp BITSTOGGLE 
        rjmp BRANCH 
        rjmp BYE 
        rjmp CAT 
        rjmp CELLMINUS 
        rjmp CELLPLUS 
        rjmp CELLS 
        rjmp CELLSZ 
        rjmp CMOVE 
        rjmp CMOVEGT 
        rjmp CTO 
;        rjmp DOVAR 
        rjmp DROP 
        rjmp DSHL 
        rjmp DSHR 
        rjmp DUP 
        rjmp EMITQM 
        rjmp EQUAL 
        rjmp EXEC 
        rjmp GTHAN 
        rjmp GTR 
        rjmp INV 
        rjmp IOYO 
        rjmp KEYQM 
        rjmp LITL 
        rjmp LTHAN 
        rjmp MINUS 
        rjmp NEG 
        rjmp NOOP 
        rjmp ONEMINUS 
        rjmp ONENEG 
        rjmp ONEPLUS 
        rjmp OR 
        rjmp OVER 
        rjmp PLUS 
        rjmp PLUSTO 
        rjmp PSAT 
        rjmp PSTO 
        rjmp PUSHS 
        rjmp QMBRANCH 
        rjmp QMDUP 
        rjmp QUIT 
        rjmp RAT 
        rjmp RGT 
        rjmp ROT 
        rjmp RSAT 
        rjmp RSTO 
        rjmp SDIV 
        rjmp SHL 
        rjmp SHR 
        rjmp SMUL 
        rjmp SWAP 
        rjmp TO 
        rjmp TWODROP 
        rjmp TWODUP 
        rjmp TWOSWAP
        rjmp UMBYMOD 
        rjmp UMUL 
        rjmp UPLUS 
        rjmp XOR 
        rjmp ZERO 
        rjmp ZEROEQ 
        rjmp ZEROGT 
        rjmp ZEROLT 

;---------------------------------------------------------------------
;
; check in CORE have 3 dec
;
_CORE:
		
; offset by multiply by 2

        lsl r0
        rol r1

; load table address

        ldi wrk_low, lo8(JUMPS)
        ldi wrk_high, hi8(JUMPS)

; take offset

        add wrk_low, r0
        adc wrk_high, r1

; pseudo

        push wrk_low
        push wrk_high
        ret

;---------------------------------------------------------------------
;
; end trampoline
;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
; ????
LEAF 3, "D2/"
DSHR:
        lsr nds_low
        ror nds_high
        ror tos_low
        ror tos_high
        rjmp CORE

;----------------------------------------------------------------------
; ????
LEAF 3, "D2*"
DSHL:
        lsl nds_low
        rol nds_high
        rol tos_low
        rol tos_high
        rjmp CORE

;----------------------------------------------------------------------
;
; 	"div16u" - 16/16 Bit Unsigned Division
;
; ok UM/MOD
LEAF 6, "UM/MOD"
UMBYMOD:
;
;***** Subroutine Register Variables

#define drem16uL r14
#define drem16uH r15
#define dres16uL r16
#define dres16uH r17

#define dd16uL r16
#define dd16uH r17
#define dv16uL r18
#define dv16uH r19

#define dcnt16u r20

;
;	move operands
;
        movw r16, nds_low
		movw r18, tos_low
;
;***** Code

div16u: clr wrk_low ;clear remainder Low byte
        sub wrk_high,wrk_high;clear remainder High byte and carry
        ldi r16,17 ;init loop counter
d16u_1: rol nds_low ;shift left dividend
        rol nds_high
        dec r16 ;decrement counter
        brne d16u_2 ;if done
d16ures:
;
;	move operands
;
        movw nds_low, r16
		movw tos_low, r14
        rjmp CORE

d16u_2: rol wrk_low ;shift dividend into remainder
        rol wrk_high
        sub wrk_low,tos_low ;remainder = remainder - divisor
        sbc wrk_high,tos_high ;
        brcc d16u_3 ;if result negative
        add wrk_low,tos_low ; restore remainder
        adc wrk_high,tos_high
        clc ; clear carry to be shifted into result
        rjmp d16u_1 ;else
d16u_3: sec ; set carry to be shifted into result
        rjmp d16u_1


;----------------------------------------------------------------------
;
;	 "div16s" - 16/16 Bit Signed Division
;
; ok /
LEAF 1, "/"
SDIV:
;
;***** Subroutine Register Variables
;

#define drem16sL r14
#define drem16sH r15
#define dres16sL r16
#define dres16sH r17

#define dd16sL r16
#define dd16sH r17
#define dv16sL r18
#define dv16sH r19


#define dcnt16s r20

#define	d16s	r21

;
;	move operands
;
        movw r16, nds_low
		movw r18, tos_low
;
;***** Code
;
div16s: mov     d16s,dd16sH     ;move dividend High to sign register
        eor     d16s,dv16sH     ;xor divisor High with sign register
        sbrs    dd16sH,7        ;if MSB in dividend set
        rjmp    d16s_1
        com     dd16sH          ;    change sign of dividend
        com     dd16sL
        subi    dd16sL,lo8(-1)
        sbci    dd16sL,hi8(-1)
d16s_1: sbrs    dv16sH,7        ;if MSB in divisor set
        rjmp    d16s_2
        com     dv16sH          ;    change sign of divisor
        com     dv16sL
        subi    dv16sL,lo8(-1)
        sbci    dv16sL,hi8(-1)
d16s_2: clr     drem16sL        ;clear remainder Low byte
        sub     drem16sH,drem16sH;clear remainder High byte and carry
        ldi     dcnt16s,17      ;init loop counter

d16s_3: rol     dd16sL          ;shift left dividend
        rol     dd16sH
        dec     dcnt16s         ;decrement counter
        brne    d16s_5          ;if done
        sbrs    d16s,7          ;    if MSB in sign register set
        rjmp    d16s_4
        com     dres16sH        ;        change sign of result
        com     dres16sL
        subi    dres16sL,lo8(-1)
        sbci    dres16sH,hi8(-1)
d16s_4:                      ;    return
d16sres:
        movw nds_low, r16
		movw tos_low, r14
        rjmp CORE

d16s_5: rol     drem16sL        ;shift dividend into remainder
        rol     drem16sH
        sub     drem16sL,dv16sL ;remainder = remainder - divisor
        sbc     drem16sH,dv16sH ;
        brcc    d16s_6          ;if result negative
        add     drem16sL,dv16sL ;    restore remainder
        adc     drem16sH,dv16sH
        clc                     ;    clear carry to be shifted into result
        rjmp    d16s_3          ;else
d16s_6: sec                     ;    set carry to be shifted into result
        rjmp    d16s_3

;----------------------------------------------------------------------
;
;* "mpy16s" - 16x16 Bit Signed Multiplication
; ok *
LEAF 1, "*"
SMUL:
;***** Subroutine Register Variables

#define mc16sL r16
#define mc16sH r17      
#define mp16sL r18           
#define mp16sH r19           

#define m16s0 r18          
#define m16s1 r19         
#define m16s2 r20      
#define m16s3 r21        

#define mcnt16s r22           

;
;	move operands
;
        movw r16, nds_low
		movw r18, tos_low
;
;***** Code
mpy16s: clr     m16s3           ;clear result byte 3
        sub     m16s2,m16s2     ;clear result byte 2 and carry
        ldi     mcnt16s,16      ;init loop counter
m16s_1: brcc    m16s_2          ;if carry (previous bit) set
        add     m16s2,mc16sL    ;    add multiplicand Low to result byte 2
        adc     m16s3,mc16sH    ;    add multiplicand High to result byte 3
m16s_2: sbrc    mp16sL,0        ;if current bit set
        sub     m16s2,mc16sL    ;    sub multiplicand Low from result byte 2
        sbrc    mp16sL,0        ;if current bit set
        sbc     m16s3,mc16sH    ;    sub multiplicand High from result byte 3
        asr     m16s3           ;shift right result and multiplier
        ror     m16s2
        ror     m16s1
        ror     m16s0
        dec     mcnt16s         ;decrement counter
        brne    m16s_1          ;if not done, loop more
m16sres:
        mov nds_low, r16
        rjmp CORE

;----------------------------------------------------------------------
;
; "mpy16u" - 16x16 Bit Unsigned Multiplication
;
; ok UM*
LEAF 3, "UM*"
UMUL:
;
;***** Subroutine Register Variables

#define mc16uL r16
#define mc16uH r17
#define mp16uL r18
#define mp16uH r19

#define m16u0 r18           
#define m16u1 r19           
#define m16u2 r20           
#define m16u3 r21           

#define mcnt16u r22           

;
;	move operands
;
        movw r16, nds_low
		movw r18, tos_low
;
;***** Code
;
mpy16u: clr wrk_high ;clear 2 highest bytes of result
        clr wrk_low
        ldi r16,16 ;init loop counter
        lsr tos_high
        ror tos_low

m16u_1: brcc noad8 ;if bit 0 of multiplier set
        add wrk_low,nds_low ;add multiplicand Low to byte 2 of res
        adc wrk_high,nds_high ;add multiplicand high to byte 3 of res
noad8: ror wrk_high ;shift right result byte 3
        ror wrk_low ;rotate right result byte 2
        ror r19 ;rotate result byte 1 and multiplier High
        ror r18 ;rotate result byte 0 and multiplier Low
        dec r16 ;decrement loop counter
        brne m16u_1 ;if not done, loop more
m16ures:
;
;	move operands
;
        movw nds_low, r18
        rjmp CORE

;----------------------------------------------------------------------

;----------------------------------------------------------------------
;*************************************************************************
;*                                                                       *
;*                      Convert unsigned 16 bit to 5 digit ASCII         *
;*                                                                       *
;*              Author: Peter Dannegger                                  *
;*                                                                       *
;*************************************************************************
; https://www.avrfreaks.net/forum/smallest-and-fastest-binary-bcd-conversion?page=all
;
;
;input: R17, R16 = 16 bit value 0 ... 65535
;output: R20, R19, R18, R17, R16 = 5 digits (ASCII)
;cycle: 20 ... 170
;

bin16_ascii:

        ldi     r20, -1 + '0'
_bcd1:  inc     r20
        subi    r16, lo8(10000)         
        sbci    r17, hi8(10000)
        brcc    _bcd1

        ldi     r19, 10 + '0'
_bcd2:  dec     r19
        subi    r16, lo8(-1000)  
        sbci    r17, hi8(-1000)
        brcs    _bcd2

        ldi     r18, -1 + '0'
_bcd3:  inc     r18
        subi    r16, lo8(100)   
        sbci    r17, hi8(100)
        brcc    _bcd3

        ldi     r17, 10 + '0'
_bcd4:  dec     r17
        subi    r16, -10      
        brcs    _bcd4

        subi    r16, -'0'
        ret
;---------------------------------------------------------------------

#include "constants.inc" 

;----------------------------------------------------------------------

#include "variables.inc" 

;----------------------------------------------------------------------

;#include "twigs.inc" 

;----------------------------------------------------------------------

