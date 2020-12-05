
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

;---------------------------------------------------------------------
;
;	default base
;
		BASEE = 16
;----------------------------------------------------------------------
;
; version information
;
.equ	version, 0x0100

;----------------------------------------------------------------------
;
; start reverse linked list
;
.set	_WORD ,  0x0
.set    _LINK ,  0x0

;----------------------------------------------------------------------
;
;	idents for first opcode in macros
;
.equ	isNOOP, 0
.equ	isLEAF, 1
.equ	isTWIG, 2

;----------------------------------------------------------------------
;
; header of word in dictionary
;	opcode for CODE ( execute a opcode )
;	must end with CODE :)
;
.macro LEAF size , name 
.word    _LINK
.byte    \size
.ascii   "\name"
.byte	 isLEAF
.set     _LINK ,  .
.set	 _WORD , _WORD + 1
.endm

;----------------------------------------------------------------------
;
; header of word in dictionary
;	opcode for TWIG ( as colon )
;	must end with EXIT :)
;
.macro TWIG size , name 
.word    _LINK
.byte    \size
.ascii   "\name"
.byte	 isTWIG
.set     _LINK ,  .
.set	 _WORD , _WORD + 1
.endm

;----------------------------------------------------------------------
;
;	must end with EXIT :)
;
.macro HASRAM name 
.word	LITERAL
.word	\name
.word	EXIT
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
;----------------------------------------------------------------------

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

;----------------------------------------------------------------------
;
; start of dictionary
;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;
;    init instruction pointer and etc
;
        __SREG__ = 0x3f
        __SP_H__ = 0x3e
        __SP_L__ = 0x3d

LEAF 5, "RESET"
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
LEAF 3, "BYE"
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
LEAF 5, "ABORT"
ABORT:
        ldi rsph, hi8(RSP_TOP)
        ldi rspl, lo8(RSP_TOP)

;----------------------------------------------------------------------
;
;    init parameter stack
;
LEAF 4, "QUIT"
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
		rjmp CODE

;----------------------------------------------------------------------
;
;    start forth, 
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;    trampoline for 127 primitives
;
;    order IS opcode sequence
;
.align   2
JUMPS:
;
;	 do not change order, hard coded in macros 
;	opcode 0, 1, 2, 3, 4, 5, 6, 7	 
;
		rjmp NOOP	;	isNOOP
		rjmp CODE	; 	isLEAF
		rjmp ENTER	;	isTWIG
		rjmp EXIT	;	
		rjmp CODE	; 	reserved
		rjmp CODE	; 	reserved
		rjmp CODE	; 	reserved
		rjmp CODE	; 	reserved

;
;	 could change order 
;	opcode 8, .. 255

;---------------------------------------------------------------------
;
;    read a opcode in [ip] 
;
LEAF 4, "NOOP"
NOOP:
		rjmp CODE
;---------------------------------------------------------------------
;
;    read a opcode in [ip] 
;
LEAF 4, "CODE"
CODE:
; trampoline 

        lpm _work_, Z+
        ldi wl, lo8(JUMPS)
		ldi wh, hi8(JUMPS)
		
; offset by multiply by 2
		lsl _work_
		rol _zero_

; take offset		
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
LEAF 4, "KEY?"
KEYQ:
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
LEAF 5, "EMIT?"
EMITQ:
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
LEAF 3, "!IO"
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
        rjmp CODE

;----------------------------------------------------------------------
;    ok    push a value from flash into parameter stack
LEAF 7, "LITERAL"
LITERAL:
        pspush nl, nh
        movw nl, tl
        ipread tl
        ipread th
        rjmp EXIT

;----------------------------------------------------------------------
;    ok    push a address  from sram
LEAF 5, "doVAR"
doVAR:
        pspush nl, nh
        movw nl, tl
	; ????	
        rjmp CODE

;----------------------------------------------------------------------
;    ok    push a value from flash
LEAF 5, "doCON"
doCON:
        pspush nl, nh
        movw nl, tl
	; ????
        rjmp CODE

;----------------------------------------------------------------------
;    test index loop in rsp, if 0< exit loop else next 
LEAF 4, "doNext"
DONEXT:
        rspull wl, wh
        sbiw wl, 1
        brge _DONEXT1	; ????
		rjmp EXIT		
_DONEXT1:
		adiw wl, 1
        rspush wl, wh        
        rjmp CODE
        
;----------------------------------------------------------------------
;
;	ok 	pop tos and test if less than zero, leave seg register
;
TSTOP:
        movw wl, tl
        movw tl, nl
        pspull nl, nh
		sbiw wl, 1
		ret

;----------------------------------------------------------------------
;    ok	if 0 branch
LEAF 7, "?BRANCH"
QBRANCH:
		rcall TSTOP
        breq BRANCH
        rjmp CODE

;----------------------------------------------------------------------
;    ok branch
LEAF 6, "BRANCH"
BRANCH:
        ipread  wl
        ipread  wh
        rjmp GOES

;----------------------------------------------------------------------
;    ok exit    pop new ip from return stack
LEAF 4, "EXIT"
EXIT:
        rspull zl, zh
        ; rjmp ENTER    ; not need maybe
;----------------------------------------------------------------------
;    ok enter
LEAF 5, "ENTER"
ENTER:
        ipread wl
        ipread wh
        rspush zl, zh
GOES:
        movw zl, wl
        rjmp CODE

;----------------------------------------------------------------------
;    ok 2drop
LEAF 5, "2DROP"
TWODROP:
        pspull tl, th
        pspull nl, nh
        rjmp CODE

;----------------------------------------------------------------------
;    ok 2dup
LEAF 4, "2DUP"
TWODUP:
        pspush nl, nh
        pspush tl, th
        rjmp CODE

;----------------------------------------------------------------------
;    ok    to 	(works only in sram)    
LEAF 1, "!"
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
LEAF 1, "C!"
CTO:
        rspush xl, xh
		movw xl, tl
		st X+,	nl
		rjmp _TO1

;----------------------------------------------------------------------
;    ok    at	(works only in sram)
LEAF 1, "@"
AT:
        rspush xl, xh
        movw xl, tl
		ld th, x+
		ld tl, x+
_AT1:
        rspull xl, xh
        rjmp CODE

;----------------------------------------------------------------------
;    cat
LEAF 1, "C@"
CAT:
        rspush xl, xh
        movw xl, tl
		ld tl, x+
		eor th, th
        rjmp _AT1

;----------------------------------------------------------------------
;    ok    R@
LEAF 2, "R@"
RAT:
        pspush nl, nh
        movw nl, tl 
        rspull tl, th
        sbiw yl, 1
        rjmp CODE

;----------------------------------------------------------------------
;    ok    R>
LEAF 2, "R>"
RTO:
        pspush nl, nh
        movw nl, tl 
        rspull tl, th
        rjmp CODE

;----------------------------------------------------------------------
;    ok    >R
LEAF 2, ">R"
TOR:
        rspush tl, th
        rjmp DROP

;----------------------------------------------------------------------
;    ok   RS@
LEAF 3, "RS@"
RSAT:
        pspush nl, nh
        movw nl, tl
        movw tl, rspl
        rjmp CODE

;----------------------------------------------------------------------
;   ok	RS!
LEAF 3, "RS!"
RSTO:
        movw rspl, tl
        rjmp DROP

;----------------------------------------------------------------------
;    ok   PS@
LEAF 4, "PS@"
PSAT:
		movw wl, xl
		adiw wl, 3
		rjmp PFLAG

;----------------------------------------------------------------------
;    ok   PS!
LEAF 4, "PS!"
PSTO:
        movw wl, tl
        rjmp CODE

;----------------------------------------------------------------------
;    ok    DROP
LEAF 4, "DROP"
DROP:
        movw tl, nl 
        pspull nl, nh
        rjmp CODE

;----------------------------------------------------------------------
;   ok     DUP
LEAF 3, "DUP"
DUP:
        pspush nl, nh
        movw tl, nl
        rjmp CODE

;----------------------------------------------------------------------
;    ok     SWAP
LEAF 4, "SWAP"
SWAP:
        movw wl, nl
        movw nl, tl
        movw tl, wl
        rjmp CODE

;----------------------------------------------------------------------
;   ok     OVER
LEAF 4, "OVER"
OVER:
        movw wl, nl
		; rjmp PFLAG	; maybe not need
;
;    ok    push a value or a flag, to tos
;
PFLAG:
        pspush nl, nh
        movw nl, tl
        movw tl, wl
        rjmp CODE

;----------------------------------------------------------------------
;
;    ok    push a false
;
LEAF 5, "FALSE"
FFALSE:
        ldi	wl, 0x00
        ldi	wh, 0x00
        rjmp PFLAG
        
;----------------------------------------------------------------------
;
;    ok    push a true
;
LEAF 4, "TRUE"
FTRUE:
        ldi	wl, 0xFF
        ldi	wh, 0xFF
        rjmp PFLAG
        
;----------------------------------------------------------------------
;    ok    0<
LEAF 2, "0<"
ZLESS:
        rcall TSTOP
        brge FFALSE
		rjmp FTRUE

;----------------------------------------------------------------------
;    ok    0=
LEAF 2, "0="
ZEQU:
        rcall TSTOP
        brge FFALSE ; ????
        rjmp FTRUE

;----------------------------------------------------------------------
;   ok    XOR
LEAF 3, "XOR"
XOR:
        eor nl, tl
        eor nh, th
        rjmp DROP
        
;----------------------------------------------------------------------
;   ok    AND
LEAF 3, "AND"
AND:
        and nl, tl
        and nh, th
        rjmp DROP

;----------------------------------------------------------------------
;    ok    OR
LEAF 2, "OR"
OR:
        or  nl, tl
        or  nh, th
        rjmp DROP

;----------------------------------------------------------------------
;     +
LEAF 1, "+"
PLUS:
        add nl, tl
        adc nh, th
		rjmp DROP

;----------------------------------------------------------------------
;     -
LEAF 1, "-"
MINUS:
        sub nl, tl
        sbc nh, th
		rjmp DROP

;----------------------------------------------------------------------
;    ok    INV
LEAF 3, "INV"
INV:
        com tl
        com th
        rjmp CODE

;----------------------------------------------------------------------
;    ok    NEG
LEAF 3, "NEG"
NEG:
        neg tl
        neg th
        rjmp CODE

;----------------------------------------------------------------------
;    ok    2*
LEAF 2, "2*"
SHL:
        lsl tl
        rol th
        rjmp CODE

;----------------------------------------------------------------------
;    ok    2/
LEAF 2, "2/"
SHR:
        lsr th
        ror tl
        rjmp CODE

;----------------------------------------------------------------------
;     UM+
LEAF 3, "UM+"
UPLUS:
		; do signed plus
        add nl, tl
        adc nh, th
		; preserve carry at tos
        eor tl, tl
        eor th, th
        rol tl
        rjmp CODE

;----------------------------------------------------------------------
;    
;    CMOVE  copy from source++ to destination++, decrease w
LEAF 5, "CMOVE" 
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
LEAF 5, "CMOVE>" 
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
LEAF 6, "UM/MOD"
		rjmp CODE

;----------------------------------------------------------------------
;
;	ok	UM*
LEAF 3, "UM*"
		rjmp CODE
		
;----------------------------------------------------------------------
;    ok    "D*" ( w1 w2 -- w3 w4 w5 w6 ) multiply two 16 bit
LEAF 3, "D*" 
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

        rjmp CODE
        

;----------------------------------------------------------------------
;
TWIG 4, "CREATE"
.word	EXIT
;----------------------------------------------------------------------
;
TWIG 4, "VARIABLE"
.word	LITERAL
.word	DPP
.word 	AT
.word	EXIT

;----------------------------------------------------------------------
;
;	ok  push address of "" into parameter stack
;
;----------------------------------------------------------------------
TWIG 4, "BASE"
HASRAM TBASE
;----------------------------------------------------------------------
TWIG 5, "'TIB0"
HASRAM TIB0 
;----------------------------------------------------------------------
TWIG 5, "'PAD0"
HASRAM TPAD0 
;----------------------------------------------------------------------
TWIG 5, "'PAD1"
HASRAM TPAD1 
;----------------------------------------------------------------------
TWIG 5, "'KEYQ"
HASRAM TKEYQ 
;----------------------------------------------------------------------
TWIG 6, "'iEMITQ"
HASRAM TEMITQ 
;----------------------------------------------------------------------
TWIG 7, "'EXPECT"
HASRAM TEXPECT 
;----------------------------------------------------------------------
TWIG 4, "'TAP"
HASRAM TTAP 
;----------------------------------------------------------------------
TWIG 5, "'ECHO"
HASRAM TECHO 
;----------------------------------------------------------------------
TWIG 7, "'PROMPT"
HASRAM TPROMPT 
;----------------------------------------------------------------------
TWIG 5, "'EVAL"
HASRAM TEVAL 
;----------------------------------------------------------------------
TWIG 7, "'NUMBER"
HASRAM TNUMBER 
;----------------------------------------------------------------------
TWIG 5, "'NAME"
HASRAM TNAME 
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;
;	define base constants
;
		ONE	= 1
		TWO = 2
		SIX = 6
		OCT = 8
		TEN = 10
		DUO = 12
		HEX = 16

;----------------------------------------------------------------------
;       OCTAL		;	0	\0	null
TWIG 3, "OCT"
.word	LITERAL
.byte	OCT
.byte	NL
.word	BASE	;	address of BASE variable
.word	TO		;	!
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       DECIMAL		;	0	\0	null
TWIG 3, "DEC"
.word	LITERAL
.byte	TEN
.byte	NL
.word	BASE	;	address of BASE variable
.word	TO		;	!
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       HEX		;	0	\0	null
TWIG 3, "HEX"
.word	LITERAL
.byte	HEX
.byte	NL
.word	BASE	;	address of BASE variable
.word	TO		;	!
.word	EXIT	;	exit

;----------------------------------------------------------------------
;
;     define ascii constants 
;

		NL = 0		;  	\0	null
        BS = 8		;	^h	\b	backspace
        TB = 9		;	^i	\t	horizontal tab
        LF = 10		;	^j	\n	line feed
        FF = 12		;	^l	\f	form feed
		CR = 13		;	^m	\r	carriage return
        ES = 27		;	^[	\e	escape
		BL = 32		;	blank character

;----------------------------------------------------------------------
;       NL = 0		;	0	\0	null
TWIG 2,"NL"
.word	LITERAL
.byte	NL
.byte	NL
.word	EXIT	;	exit
		
;----------------------------------------------------------------------
;       BS = 8		;	^h	\b	backspace
TWIG 2,"BS"
.word	LITERAL
.byte	BS
.byte	NL
.word	EXIT	;	exit
		
;----------------------------------------------------------------------
;       TB = 9		;	^i	\t	horizontal tab
TWIG 2,"TB"
.word	LITERAL
.byte	TB
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       LF = 10		;	^j	\n	line feed
TWIG 2,"LF"
.word	LITERAL
.byte	LF
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       FF = 12		;	^l	\f	form feed
TWIG 2,"FF"
.word	LITERAL
.byte	FF
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       CR = 13		;	^m	\r	carriage return
TWIG 2,"CR"
.word	LITERAL
.byte	CR
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       ES = 27		;	^[	\e	escape
TWIG 2,"ES"
.word	LITERAL
.byte	ES
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;		BL = 32		;	blank character
TWIG 2,"BL"
.word	LITERAL
.byte	BL
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;		CELL = 2	;	size of a cell 
TWIG 2,"CELL"
.word	LITERAL
.byte	TWO
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;
;	ROULETTE	numbers
;
TWIG 8, "ROULETTE"
.word	LITERAL
.byte	37
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
.byte   0
.word	EXIT	;	exit
;----------------------------------------------------------------------


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
TOPRAM:
.equ     TBASE , .
.equ     TTIB0 , .
.equ     TPAD0 , .
.equ     TPAD1 , .
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
.equ     TIN , .
.equ     TIB , .
.equ     HLD , .
.equ     CSP , .
.equ     CONTEXT , .
.equ     CURRENT , .
.equ     CURSOR , .
.equ     HANDLER , .
.equ     SPAN , .
.equ     LAST , .
.equ     SP0 , .
.equ     RP0 , .
.equ     UP , .
.equ     DP , .

