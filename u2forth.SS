
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

;----------------------------------------------------------------------
;
;    02/12/2020
;
;    u2forth
;
;    inspired on eforth from books and papers from C. H. Ting
;
;    just experience for small microcontrolers
;
;    emulates a virtual uC really
;
;    still no interrupts
;    still no multitasks
;
;    forth for ATMEGA8, 8k flash, 1k SRAM, 
;        internal clock 8 MHz, USART 9600,8,N,1
;
;    using GCC avr-as -mmcu=atmega8 
;    
;    Alvaro Gomes Sobral Barcellos
;
;    "The first register is always the target register !"
;
;    .equ assign a constant value to a label
;
;    .set assign a variable value to a label
;
;    .rept    number \n " codes " \n .endr ; repeats "codes" number times
;
        .NOLIST
        .LIST

;----------------------------------------------------------------------
;        .device "ATMEGA8"

;----------------------------------------------------------------------
;
;	must use gnu cpp 
;	use with .S (upper S) or
;	use with -x assembler-with-cpp
;
;----------------------------------------------------------------------
; generic use
#define         _work_    r0    

; always zero
#define         _zero_    r1    

; Z instruction pointer for access sram and flash memory
#define 		iph     r31    

; Z instruction pointer for access sram and flash memory
#define 		ipl     r30    

; Y return stack pointer for access sram
#define         rsph    r29    

; Y return stack pointer for access sram
#define         rspl    r28    

; X parameter stack pointer for access sram
#define         psph    r27    

; X parameter stack pointer for access sram
#define         pspl    r26    

; fist value parameter stack
#define         th    r21    

; fist value parameter stack
#define         tl    r20    

; second value parameter stack
#define         nh    r23    

; second value parameter stack
#define         nl    r22    

; work registers
#define         wh    r25    

; work registers
#define         wl    r24    

;----------------------------------------------------------------------
;
;      	assign stacks address
;		for atmega8
;
        SRAM_START = 0x060
        SRAM_END = 0x4FF

;----------------------------------------------------------------------
;
;    default sizes
        STACK_SIZE = 0x20    ;  32 bytes
        TERMS_SIZE = 0x50    ;  80 bytes
        BUFFER_SIZE = 0x80    ; 128 bytes
;----------------------------------------------------------------------
;
;    grows downwards  SP = SP - 1
        SPP_TOP = SRAM_END
        RSP_TOP = SPP_TOP - STACK_SIZE
        PSP_TOP = RSP_TOP - STACK_SIZE
;----------------------------------------------------------------------
;
;    grows upwards PT = PT + 1
        TIB_TOP = PSP_TOP - STACK_SIZE - TERMS_SIZE     
        PAD0_TOP = TIB_TOP - BUFFER_SIZE     
        PAD1_TOP = PAD0_TOP - BUFFER_SIZE      

;----------------------------------------------------------------------
;
;   flags for words
;
        F_IMMED = 0x080
        F_COMPD = 0x040
        F_HIDDE = 0x020
        F_MASKS = 0x01F

;----------------------------------------------------------------------
;
; version information
;
        vers = 1
        ions = 0

;----------------------------------------------------------------------
;
;     define constants 
;
        FALSE = 0x00
        TRUE = 0xFF
        CELL = 0x02

;----------------------------------------------------------------------
;
;     define ascii constants 
;
        BS = 8		;	^h	\b	backspace
        TB = 9		;	^i	\t	horizontal tab
        LF = 10		;	^j	\n	line feed
        FF = 12		;	^l	\f	form feed
		CR = 13		;	^m	\r	carriage return
        ES = 27		;	^[	\e	escape
		BL = 32		;	blank character

        BASEE = 16

;----------------------------------------------------------------------
;
; start value for reverse linked list
;
.set	_WORD ,  0x0
.set    _LINK ,  0x0

;----------------------------------------------------------------------
;
; header of word in dictionary
;
.macro CODE size , name 
.word    _LINK
.byte    \size
.ascii   "\name"
.set     _LINK ,  .
.set	 _WORD , _WORD + 1
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
.macro    peek byte , address
        .if (\address < $40) 
         in \byte , \address
        .else
         lds \byte , \address
        .endif
.endm

;----------------------------------------------------------------------
.macro    poke byte , address
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
		.global variables
        .type   variables, @object
        .size   variables, 37
variables:
.word BASEE      ; BASE
.word TIB_TOP    ; TIB0 
.word PAD0_TOP   ; PAD0 
.word PAD1_TOP   ; PAD1 
.word KEYQ       ; 'KEY?
.word EMITQ      ; 'EMIT?
.word EXPECT     ; 'EXPECT
.word TAP        ; 'TAP
.word ECHO       ; 'ECHO
.word PROMPT     ; 'PROMPT
.word EVAL       ; 'EVAL
.word NUMBER     ; 'NUMBER
.word NAME       ; 'NAME

.equ	FORTH_VARIABLES_END, .
;----------------------------------------------------------------------
;
.data    ; start data segment (sram)
.org     0x00060
TOPRAM:
.equ     BASE , .
.equ     TIB0 , .
.equ     PAD0 , .
.equ     PAD1 , .
.equ     TKEYQ , .
.equ     TEMITQ , .
.equ     TEXPECT , .
.equ     TTAP , .
.equ     TECHO , .
.equ     TPROMPT , .
.equ     TEVAL , .
.equ     TNUMBER , .
.equ     TNAME , .
;
;	free 
;
.equ     TMP , .
.equ     SPAN , .
.equ     TIN , .
.equ     TIB , .
.equ     HLD , .
.equ     CSP , .
.equ     CONTEXT , .
.equ     CURRENT , .
.equ     CURSOR , .
.equ     HANDLER , .
.equ     LAST , .
.equ     SP0 , .
.equ     RP0 , .
.equ     UP , .
.equ     DP , .

;----------------------------------------------------------------------
;
;        code segment, flash
;
        .section .text
        .global main
main:
.org    0x00000

;----------------------------------------------------------------------
;
;        interrup table
;
        rjmp   RESET        ; Reset Handler
        reti       ;        rjmp   EXT_INT0     ; IRQ0 Handler
        reti       ;        rjmp   EXT_INT1     ; IRQ1 Handler
        reti       ;        rjmp   TIM2_COMP    ; Timer2 Compare Handler
        reti       ;        rjmp   TIM2_OVF     ; Timer2 Overflow Handler
        reti       ;        rjmp   TIM1_CAPT    ; Timer1 Capture Handler
        reti       ;        rjmp   TIM1_COMPA   ; Timer1 CompareA Handler
        reti       ;        rjmp   TIM1_COMPB   ; Timer1 CompareB Handler
        reti       ;        rjmp   TIM1_OVF     ; Timer1 Overflow Handler
        reti       ;        rjmp   TIM0_OVF     ; Time_work_ Overflow Handler
        reti       ;        rjmp   SPI_STC      ; SPI Transfer Complete Handler
        reti       ;        rjmp   USART_RXC    ; USART RX Complete Handler
        reti       ;        rjmp   USART_UDRE   ; UDR Empty Handler
        reti       ;        rjmp   USART_TXC    ; USART TX Complete Handler
        reti       ;        rjmp   ADC         ; ADC Conversion Complete Handler
        reti       ;        rjmp   EE_RDY       ; EEPROM Ready Handler
        reti       ;        rjmp   ANA_COMP     ; Analog Comparator Handler
        reti       ;        rjmp   TWSI        ; Two-wire Serial Interface Handler
        reti       ;        rjmp   SPM_RDY      ; Store Program Memory Ready Handler;

;----------------------------------------------------------------------
;
;
;----------------------------------------------------------------------
        __SREG__ = 0x3f
        __SP_H__ = 0x3e
        __SP_L__ = 0x3d

;----------------------------------------------------------------------
;
; start of dictionary
;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;    init instruction pointer and etc
CODE 5, "RESET"
RESET:     
;    clear interrupts
        cli 
;    init r1 as zero
        eor r1, r1               ; exclusive or, xor
        out __SREG__, r1         ; clear sreg
;    init real sp at end of sram
        ldi wh, hi8(SPP_TOP)
        out __SP_H__, wh
        ldi wl, lo8(SPP_TOP)
        out __SP_L__, wl
        ;        sei                        ; Enable interrupts

;----------------------------------------------------------------------
;    init instruction pointer and etc
CODE 3, "BYE"
BYE:
		; clear tos, sec, wrk

        eor th, th
        eor tl, tl
        
        eor nh, nh
        eor nl, nl
        
        eor wh, wh
        eor wl, wl

;----------------------------------------------------------------------
;
;    init return stack
;
CODE 5, "ABORT"
ABORT:
        ldi rsph, hi8(RSP_TOP)
        ldi rspl, lo8(RSP_TOP)

;----------------------------------------------------------------------
;
;    init parameter stack
;
CODE 4, "QUIT"
QUIT:
;    init parameter stack
        ldi psph, hi8(PSP_TOP)
        ldi pspl, lo8(PSP_TOP)

;----------------------------------------------------------------------
;
;    init variables
;
		rspush pspl, psph

		ldi zh, hi8(variables)
		ldi zl, lo8(variables)
		ldi xh, hi8(TOPRAM)
		ldi xl, lo8(TOPRAM)
		; ???? size in wl,wh
_COPY:		
		ld _work_, Z+
		st X+, _work_
        sbiw wl, 1
        brge _COPY
		
		rspull pspl, psph
		
        ; must point to real start
        
		eor iph, iph
        eor ipl, ipl
		rjmp WXYZ

;----------------------------------------------------------------------
;
;    start forth, 
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;    trampoline for 127 primitives
;
;        rjmp WXYZ
;
.align   2
JUMPS:
		rjmp WZYZ

;---------------------------------------------------------------------
;
;    read a opcode in [ip] 
;
CODE 4, "WXYZ"
WXYZ:
; trampoline 

        lpm _work_, Z+
        ldi wl, lo8(JUMPS)
		ldi wh, hi8(JUMPS)
		
; offset by multiply by 2
		lsl _work_
        add wl, _work_
        adc wh, _zero_

; pseudo 
        push wl
        push wh
        ret

;----------------------------------------------------------------------
;
;    ok    non block, test if can receive a char ( -- 0x00 | ch 0xFF )
;
CODE 4, "KEY?"
RXAT:
        sbis 0xb, 7
        rjmp FFALSE
        in wl, 0xc
        pspush nl, nh
        movw nl, tl
        rjmp FTRUE

;----------------------------------------------------------------------
;
;    ok    non block, test if can send a char ( ch -- ch 0x00 | 0xFF )
;
CODE 5, "EMIT?"
TXTO:
        sbis 0xb, 5
        rjmp FFALSE
        out 0xc, tl
        movw wl, nl
        pspull nl, nh
        rjmp FTRUE

;----------------------------------------------------------------------
;
;    init usart, from avr-gcc public code, io ports as constants 
;
CODE 3, "!IO"
IOYO:
		eor wl, wl 
        out 0x20, wl
        ldi wl,lo8(52)
        out 0x9,wl
        in wl,0xa
        ori wl,lo8(24)
        out 0xa,wl
        ldi wl,lo8(-114)
        out 0x20,wl
        in wl,0x20
        ori wl,lo8(64)
        out 0x20,wl
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    push a value from flash
CODE 4, "doLIT"
DOLIT:
        pspush nl, nh
        movw nl, tl
        ipread tl
        ipread th
        rjmp WXYZ

;----------------------------------------------------------------------
;    test index loop in rsp, if 0< exit loop else next 
CODE 4, "doNext"
DONEXT:
        rspull wl, wh
        sbiw wl, 1
        brge _DONEXT1	; ????
		rjmp EXIT		
_DONEXT1:
		adiw wl, 1
        rspush wl, wh        
        rjmp WXYZ
        
;----------------------------------------------------------------------
;
;	ok 	pop tos and test if less than zero, leave seg
;
TSTOP:
        movw wl, tl
        movw tl, nl
        pspull nl, nh
		sbiw wl, 1
		ret

;----------------------------------------------------------------------
;    ok	if 0 branch
CODE 7, "?BRANCH"
QBRANCH:
		rcall TSTOP
        breq BRANCH
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok branch
CODE 6, "BRANCH"
BRANCH:
        ipread  wl
        ipread  wh
        rjmp GOES

;----------------------------------------------------------------------
;    ok exit    pop new ip from return stack
CODE 4, "EXIT"
EXIT:
        rspull zl, zh
        rjmp ENTER    ; not need maybe
;----------------------------------------------------------------------
;    ok enter
CODE 5, "ENTER"
ENTER:
        ipread wl
        ipread wh
        rspush zl, zh
GOES:
        movw zl, wl
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok 2drop
CODE 5, "2DROP"
TWODROP:
        pspull tl, th
        pspull nl, nh
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok 2dup
CODE 4, "2DUP"
TWODUP:
        pspush nl, nh
        pspush tl, th
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    to 	(works only in sram)    
CODE 1, "!"
TO:
        rspush xl, xh
		movw xl, tl
		st X+,	nh
		st X+,	nl
_TO1:
		rspull xl, xh
        pspush nl, nh
        rjmp TWODROP

;----------------------------------------------------------------------
;    cstore
CODE 1, "C!"
CTO:
        rspush xl, xh
		movw xl, tl
		st X+,	nl
		rjmp _TO1

;----------------------------------------------------------------------
;    ok    at	(works only in sram)
CODE 1, "@"
AT:
        rspush xl, xh
        movw xl, tl
		ld th, x+
		ld tl, x+
_AT1:
        rspull xl, xh
        rjmp WXYZ

;----------------------------------------------------------------------
;    cat
CODE 1, "C@"
CAT:
        rspush xl, xh
        movw xl, tl
		ld tl, x+
		eor th, th
        rjmp _AT1

;----------------------------------------------------------------------
;    ok    R@
CODE 2, "R@"
RAT:
        pspush nl, nh
        movw nl, tl 
        rspull tl, th
        sbiw yl, 1
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    R>
CODE 2, "R>"
RTO:
        pspush nl, nh
        movw nl, tl 
        pspull tl, th
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    >R
CODE 2, ">R"
TOR:
        rspush tl, th
        rjmp DROP

;----------------------------------------------------------------------
;    ok   RDROP
CODE 4, "RDROP"
RDROP:
        rspull wl, wh
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok   RP@
CODE 3, "RP@"
RPAT:
        pspush nl, nh
        movw nl, tl
        movw tl, rspl
        rjmp WXYZ

;----------------------------------------------------------------------
;   RP!
CODE 3, "RP!"
RPTO:
        movw rspl, tl
        rjmp DROP

;----------------------------------------------------------------------
;    ok    DROP
CODE 4, "DROP"
DROP:
        movw tl, nl 
        pspull nl, nh
        rjmp WXYZ

;----------------------------------------------------------------------
;   ok     DUP
CODE 3, "DUP"
DUP:
        pspush nl, nh
        movw tl, nl
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok     SWAP
CODE 4, "SWAP"
SWAP:
        movw wl, nl
        movw nl, tl
        movw tl, wl
        rjmp WXYZ

;----------------------------------------------------------------------
;   ok     OVER
CODE 4, "OVER"
OVER:
        movw wl, nl

;
;    ok    push a value or a flag, to tos
;
PFLAG:
        pspush nl, nh
        movw nl, tl
        movw tl, wl
        rjmp WXYZ

;----------------------------------------------------------------------
;
;    ok    push a false
;
CODE 5, "FALSE"
FFALSE:
        ldi	wl, 0x00
        ldi	wh, 0x00
        rjmp PFLAG
        
;----------------------------------------------------------------------
;
;    ok    push a true
;
CODE 4, "TRUE"
FTRUE:
        ldi	wl, 0xFF
        ldi	wh, 0xFF
        rjmp PFLAG
        
;----------------------------------------------------------------------
;    ok    0<
CODE 2, "0<"
ZLESS:
        rcall TSTOP
        brge FFALSE
		rjmp FTRUE

;----------------------------------------------------------------------
;    ok    0=
CODE 2, "0="
ZEQU:
        rcall TSTOP
        brge FFALSE ; ????
        rjmp FTRUE

;----------------------------------------------------------------------
;   ok    XOR
CODE 3, "XOR"
XOR:
        eor nl, tl
        eor nh, th
        rjmp DROP
        
;----------------------------------------------------------------------
;   ok    AND
CODE 3, "AND"
AND:
        and nl, tl
        and nh, th
        rjmp DROP

;----------------------------------------------------------------------
;    ok    OR
CODE 2, "OR"
OR:
        or  nl, tl
        or  nh, th
        rjmp DROP

;----------------------------------------------------------------------
;     +
CODE 1, "+"
PLUS:
        add nl, tl
        adc nh, th
		rjmp DROP

;----------------------------------------------------------------------
;     -
CODE 1, "-"
MINUS:
        sub nl, tl
        sbc nh, th
		rjmp DROP

;----------------------------------------------------------------------
;    ok    INV
CODE 3, "INV"
INV:
        com tl
        com th
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    NEG
CODE 3, "NEG"
NEG:
        neg tl
        neg th
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    2*
CODE 2, "2*"
SHL:
        lsl tl
        rol th
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    2/
CODE 2, "2/"
SHR:
        lsr th
        ror tl
        rjmp WXYZ

;----------------------------------------------------------------------
;     UM+
CODE 3, "UM+"
UPLUS:
        add nl, tl
        adc nh, th
        eor tl, tl
        eor th, th
        rol tl
        rjmp WXYZ

;----------------------------------------------------------------------
;    
;    CMOVE  copy from source++ to destination++, decrease w
CODE 5, "CMOVE" 
CMOVE:
        ; WARNING No bound check
        ; tos     source
        ; n        destination
        ; w        1 or many, 0 does nothing

        ; get the counter
        pspull wl, wh
        
        ; preserve psp into rsp
        rspush xl, xh

		; no offset

_CMOVE1:
        ; decrease counter
        sbiw wl, 1
        brlt _CMOVE2

        ; read a byte
        movw xl, tl
        ld r0, X+
        movw tl, xl

        ; write a byte
        movw xl, nl
        st X+, r0
        movw nl, xl

        ; again
        rjmp _CMOVE1

_CMOVE2:
        ; restore psp from rsp
        rspull xl, xh

TRIDROP:
        ; drop arguments
        adiw xl, 1
        rjmp TWODROP

;----------------------------------------------------------------------
;    CMOVE>  copy from source+w to destination+w, decrease w
CODE 5, "CMOVE>" 
CMOVET:
        ; WARNING No bound check
        ; tos     source
        ; n        destination
        ; w        1 or many, 0 does nothing

        ; get the counter
        pspull wl, wh
        
        ; preserve psp into rsp
        rspush xl, xh

		; offset predecrements
		
		adiw wl, 1

		add tl, wl
		adc th, wh

		add nl, wl
		adc nh, wh

		sbiw wl, 1

_CMOVET1:

        ; decrease counter
        sbiw wl, 1
        brlt _CMOVET2

        ; read a byte
        movw xl, tl
        ld r0, -X
        movw tl, xl

        ; write a byte
        movw xl, nl
        st -X, r0
        movw nl, xl

        ; again
        rjmp _CMOVET1

_CMOVET2:
        ; restore psp from rsp
        rspull xl, xh

		rjmp TRIDROP

;----------------------------------------------------------------------
;
;	ok	UM/MOD
CODE 6, "UM/MOD"
		rjmp WXYZ
;----------------------------------------------------------------------
;
;	ok	UM*
CODE 3, "UM*"
		rjmp WXYZ
		
;----------------------------------------------------------------------
;----------------------------------------------------------------------
;    ok    "D*" ( w1 w2 -- w3 w4 w5 w6 ) multiply two 16 bit
CODE 3, "D*" 
DMUL:
        rspush    xl, xh        ; preserve psp

        mul th, nh        ;Multiply high bytes AH x BH
        movw xl, r0       ;Move two-byte result into answer

        mul tl, nl        ;Multiply low bytes AL x BL
        movw wl, r0       ;Move two-byte result into answer

        clr    r2

        mul th, nl        ;Multiply AHxBL
        add wh, r0        ;Add result to answer
        adc xl, r1        ;
        adc xh, r2        ;Add the Carry Bit

        clr    r2

        mul nh, tl        ;Multiply BH x AL
        add wh, r0        ;Add result to answer
        adc xl, r1        ;
        adc xh, r2        ;Add the Carry Bit

        movw tl, xl       ; result to parameter stack
        movw nl, wl       ; result to parameter stack 

        rspull xl, xh     ; restore psp

        eor r1, r1        ; keep R1 as zero

        rjmp WXYZ
        

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

