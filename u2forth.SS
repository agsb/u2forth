
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
;   "The first register is always the target register !"
;
;    .rept    number \n " codes " \n .endr ; repeats "codes" number times
;
        .NOLIST
        .LIST

;----------------------------------------------------------------------
;        .device "ATMEGA8"

;----------------------------------------------------------------------
;
;      assign a label as constant
;
.set         SRAM_START    ,     0x100
.set         SRAM_SIZE     ,     0x400
.set         SRAM_END      ,     0x4FF
.set         STACK_SIZE    ,     0x20
.set         FALSE         ,     0x00
.set         TRUE          ,     0xFF
.set         CELL          ,     0x02
.set         F_IMMED       ,     0x80
.set         F_HIDEN       ,     0x40
.set         F_RESER       ,     0x20
.set         F_MASKS       ,     0x1F

;----------------------------------------------------------------------
;
;    .set assign a value to a label
;
.set         SPP_TOP       ,     SRAM_END
.set         RSP_TOP       ,     SPP_TOP - STACK_SIZE
.set         PSP_TOP       ,     RSP_TOP - STACK_SIZE

;----------------------------------------------------------------------
;
;     assign a name to a register
;
.set         __SREG__ ,  0x3f
.set         __SP_H__ ,  0x3e
.set         __SP_L__ ,  0x3d

.set         _work_   ,  r0    ; generic use
.set         _zero_   ,  r1    ; always zero

.set         iph     ,  r31    ; Z instruction pointer for access sram and flash memory
.set         ipl     ,  r30    ; Z instruction pointer for access sram and flash memory
.set         rsph    ,  r29    ; Y return stack pointer for access sram
.set         rspl    ,  r28    ; Y return stack pointer for access sram
.set         psph    ,  r27    ; X parameter stack pointer for access sram
.set         pspl    ,  r26    ; X parameter stack pointer for access sram

.set         th    ,  r25    ; fist value parameter stack
.set         tl    ,  r24    ; fist value parameter stack
.set         nh    ,  r23    ; second value parameter stack
.set         nl    ,  r22    ; second value parameter stack
.set         wh    ,  r21    ; work registers
.set         wl    ,  r20    ; work registers

/* used in istructions as MUL */

.set         R0 ,  r0
.set         R1 ,  r1
.set         R2 ,  r2
.set         R3 ,  r3 

;----------------------------------------------------------------------
;
; flags for words
;
.set         F_IMMED ,  0x080
.set         F_COMPD ,  0x040
.set         F_HIDDE ,  0x020
.set         F_MASKS ,  0x01F

;----------------------------------------------------------------------
;
; version information
;
.set         vers    ,  1
.set         ions    ,  0

;----------------------------------------------------------------------
;
; default values have extra last letter
;
.set         BS ,  8
.set         LF ,  10
.set         CR ,  13
.set         ESC ,  27

.set         CELL ,  2
.set         FALSE ,  0x0000
.set         TRUE ,  0xFFFF
.set         BASEE ,  16

.set         STKSZ ,  32        ; 16 words all stacks

.set         SPP    ,  RAMEND    ; real stack
.set         RSPP ,  SPP - STKSZ
.set         PSPP ,  RSPP - STKSZ

.set         TIBB ,  0x0
.set         PAD0 ,  0x0
.set         PAD1 ,  0x0
.set         DPP ,  0x0
.set         UPP ,  0x0

;----------------------------------------------------------------------
;
; start value for reverse linked list
;
.set    _LINK,  0x0
.set    _CODES, 0x0

;----------------------------------------------------------------------
;
; header of word in dictionary
;
.macro CODE size, name 
.set    _CODES, _CODES + 1
.ascii "; count code _CODES"
.word      _LINK
.set     _LINK,  .
.ascii "; this code _LINK"
.byte    \size
.ascii     "\name"
.endm

;----------------------------------------------------------------------
.macro rspush low, high 
        st -Y, \low
        st -Y, \high
.endm

;----------------------------------------------------------------------
.macro rspull low, high
        ld \high, Y+
        ld \low, Y+
.endm

;----------------------------------------------------------------------
.macro pspush low, high
        st -X, \low
        st -X, \high
.endm

;----------------------------------------------------------------------
.macro pspull low, high
        ld \high, X+
        ld \low, X+
.endm

;----------------------------------------------------------------------
.macro    peek byte, address
        .if (\address < $40) 
            in \byte, \address
        .else
            lds \byte, \address
        .endif
.endm

;----------------------------------------------------------------------
.macro    poke byte, address
        .if (\address < $40) 
            out \byte, \address
        .else
            sts \byte, \address
        .endif
.endm

;----------------------------------------------------------------------
.macro ipread register
        lpm \register, Z+
.endm

;----------------------------------------------------------------------
;
.data    ; start data segment (sram)
.org     0x00060

.word BASEE   ; BASE
.word 0x0     ; TMP
.word 0x0     ; SPAN
.word 0x0     ; >IN
.word 0x0     ; #TIB
.word 0x0     ; HLD 
.word 0x0     ; CSP
.word 0x0     ; CONTEXT
.word 0x0     ; CURRENT
.word 0x0     ; CURSOR
.word 0x0     ; HANDLER
.word 0x0     ; LAST

;----------------------------------------------------------------------
; pointer to buffers
.word TIBB    ; TIB0 
.word PAD0    ; PAD0 
.word PAD1    ; PAD1 
.word 0x0     ; DP
.word 0x0     ; UP
.word 0x0     ; SP0
.word 0x0     ; RP0

;----------------------------------------------------------------------
; pointers to words
.word 0x0        ; '?KEY
.word 0x0        ; 'EMIT
.word 0x0        ; 'EXPECT
.word 0x0        ; 'TAP
.word 0x0        ; 'ECHO
.word 0x0        ; 'PROMPT
.word 0x0        ; 'EVAL
.word 0x0        ; 'NUMBER
.word 0x0        ; 'NAME

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
        reti       ;          rjmp   EXT_INT0     ; IRQ0 Handler
        reti       ;          rjmp   EXT_INT1     ; IRQ1 Handler
        reti       ;          rjmp   TIM2_COMP    ; Timer2 Compare Handler
        reti       ;          rjmp   TIM2_OVF     ; Timer2 Overflow Handler
        reti       ;          rjmp   TIM1_CAPT    ; Timer1 Capture Handler
        reti       ;          rjmp   TIM1_COMPA   ; Timer1 CompareA Handler
        reti       ;          rjmp   TIM1_COMPB   ; Timer1 CompareB Handler
        reti       ;          rjmp   TIM1_OVF     ; Timer1 Overflow Handler
        reti       ;          rjmp   TIM0_OVF     ; Time_work_ Overflow Handler
        reti       ;          rjmp   SPI_STC      ; SPI Transfer Complete Handler
        reti       ;          rjmp   USART_RXC    ; USART RX Complete Handler
        reti       ;          rjmp   USART_UDRE   ; UDR Empty Handler
        reti       ;          rjmp   USART_TXC    ; USART TX Complete Handler
        reti       ;          rjmp   ADC          ; ADC Conversion Complete Handler
        reti       ;          rjmp   EE_RDY       ; EEPROM Ready Handler
        reti       ;          rjmp   ANA_COMP     ; Analog Comparator Handler
        reti       ;          rjmp   TWSI         ; Two-wire Serial Interface Handler
        reti       ;          rjmp   SPM_RDY      ; Store Program Memory Ready Handler;

;----------------------------------------------------------------------
;----------------------------------------------------------------------
;
RESET:     ; Set Stack Pointer to top of RAM
;    clear interrupts
        cli 
;    init r1 as zero
        eor r1, r1                  ; exclusive or, xor
        out 0x3f, r1                ; clear sreg
;    init real sp at end of sram
        ldi r25, hi8(SPP)
        out sph, r25
        ldi r24, lo8(SPP)
        out spl, r24
        ;          sei                           ; Enable interrupts
;----------------------------------------------------------------------
;    init instruction pointer and etc
CODE 3, "BYE"
BYE:
        ; must point to real start
        eor iph, iph
        eor ipl, ipl

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
        ldi yh, hi8(RSP_TOP)
        ldi yl, lo8(RSP_TOP)

;----------------------------------------------------------------------
;
;    init parameter stack and variables
;
CODE 4, "QUIT"
QUIT:
;    init parameter stack
        ldi xh, hi8(PSP_TOP)
        ldi xl, lo8(PSP_TOP)

;----------------------------------------------------------------------
;
;    start forth, 
;----------------------------------------------------------------------


;----------------------------------------------------------------------
;
; start of dictionary
;
;----------------------------------------------------------------------


;---------------------------------------------------------------------
;
;        rjmp to opcode 
.align
.equ    trampoline, .
        rjmp  DUP

;---------------------------------------------------------------------
;
;    read a opcode in [ip] 
;
CODE 4, "WXYZ"
WXYZ:
; trampoline 

        lpm _work_, Z+
        ; ????????
        ;ldiw wl, trampoline
        add wl, _work_
        adc wh, _zero_
        push wl
        push wh
        ret
        ; rjmp WHERETO

;----------------------------------------------------------------------
;    trampoline for 254 primitives
;
;        rjmp WXYZ
;----------------------------------------------------------------------
;

;----------------------------------------------------------------------
;
;    ok    push a flag, FALSE or TRUE, to tos
;

;----------------------------------------------------------------------
;
;    ok    false
;
CODE 5, "FALSE"
FFALSE:
        clr wl
        clr wh
        rjmp PFLAG
        
;----------------------------------------------------------------------
;
;    ok    true
;
CODE 4, "TRUE"
FTRUE:
        ser wl
        ser wh
        rjmp PFLAG
        
;----------------------------------------------------------------------
;----------------------------------------------------------------------
;
;    ok    non block, receive char and put true or if none put false
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
;    send char to tx usart
;
CODE 5, "EMIT?"
TXTO:
        sbis 0xb,5
        rjmp FFALSE
        out 0xc, tl
        movw tl, nl
        pspull nl, nh
        rjmp FTRUE

;----------------------------------------------------------------------
;
;    init usart, from avr-gcc public code, constants 
;
CODE 3, "!IO"
IOYO:
        movw wl, tl
        out 0x20,__zero_reg__
        ldi tl,lo8(52)
        out 0x9,tl
        in tl,0xa
        ori tl,lo8(24)
        out 0xa,tl
        ldi tl,lo8(-114)
        out 0x20,tl
        in tl,0x20
        ori tl,lo8(64)
        out 0x20,tl
        movw tl, wl
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
        subi wl, 1
        sbci wh, 0
        brge DONEXt1
		; ??????? 
        rspush wl, wh        
WNEXT1:
        rjmp WXYZ
        
;----------------------------------------------------------------------
;    ok    if 0 branch
CODE 7, "?BRANCH"
QBRAN:
        movw wl, tl
        movw tl, nl
        pspull nl, nh
		sbiw wl, 1
        breq WBRAN
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    branch
CODE 6, "BRANCH"
BRAN:
        ipread  wl
        ipread  wh
        rjmp GOES

;----------------------------------------------------------------------
;    ok    exit    pop new ip from return stack
CODE 4, "EXIT"
EXIT:
        rspull zl, zh
		rjmp ENTER	; not need maybe
;----------------------------------------------------------------------
;    ok  enter
CODE 5, "ENTER"
ENTER:
        ipread wl
        ipread wh
        rspush zl, zh
GOES:
        movw zl, wl
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok     2drop
CODE 5, "2DROP"
TWODROP:
        pspull tl, th
        pspull nl, nh
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    2dup
CODE 4, "2DUP"
TWODUP:
        pspush nl, nh
        pspush tl, th
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    to    
CODE 1, "!"
TO:
        rspush xl, xh
        movw xl, tl
        pspush nl, nh
        rspull xl, xh
        rjmp TWODROP

;----------------------------------------------------------------------
;    ok    at
CODE 1, "@"
AT:
        rspush xl, xh
        movw xl, tl
        pspull tl, th
        rspull xl, xh
        rjmp WXYZ

;----------------------------------------------------------------------
;    cstore
CODE 1, "C!"
WCTO:

;----------------------------------------------------------------------
;    cat
CODE 1, "C@"
WCAT:

;----------------------------------------------------------------------
;    ok    R@
CODE 2, "R@"
RAT:
        pspush nl, nh
        movw nl, tl 
        rspull tl, th
        subi yl, 1
        sbci yh, 0
        rjmp WYXZ

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
CODE 4, "RPROP"
RDRROP:
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
        movw tp, nl 
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
;    ok    push a flag, FALSE or TRUE, to tos
;
PFLAG:
        pspush nl, nh
        movw nl, tl
        movw tl, wl
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    0<
CODE 2, "0<"
ZLESS:
        tst th
        mov tl, _zero_
        mov th, _zero_
        brge ISFALSE
ISTRUE:
        subi tl, 1
        sbci th, 0
ISFALSE:
        rjmp WXYZ

;----------------------------------------------------------------------
;    ok    0=
CODE 2, "0="
ZEQU:
        or th, tl
        mov tl, _zero_
        mov th, _zero_
        brge ISFALSE
        rjmp ISTRUE

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
WUPLUS:
        add nl, tl
        adc nh, th
        eor tl, tl
        eor th, th
        rol tl
        rjmp WXYZ

;----------------------------------------------------------------------
;    CMOVE
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

CMOME1:
        ; decrease counter
        subi wl, 1
        sbci wh, 0
        brlt CMOVE2

        ; read a byte
        movw xl, tl
        ld r0, X+
        movw tl, xl

        ; write a byte
        movw xl, nl
        st X+, r0
        movw nl, xl

        ; again
        rjmp CMOVE1

CMOVE2:
        ; restore psp from rsp
        rspull xl, xh

THREDROP:
        ; drop arguments
        adiw xl, 1
        rjmp WTWODROP

;----------------------------------------------------------------------
;----------------------------------------------------------------------
;    ok    "D*" ( w1 w2 -- w3 w4 w5 w6 ) multiply two 16 bit
CODE 3, "D*" 
DMUL:
        rspush    xl, xh         ; preserve psp

        clr    R2
        mul th, nh           ;Multiply high bytes AHxBH
        movw xl, R0          ;Move two-byte result into answer

        mul tl, nl           ;Multiply low bytes ALxBL
        movw wl, R0          ;Move two-byte result into answer

        mul th, nl           ;Multiply AHxBL
        add wh, R0           ;Add result to answer
        adc xl, R1           ;
        adc xh, R2           ;Add the Carry Bit

        mul nh, tl           ;Multiply BHxAL
        add wh, R0           ;Add result to answer
        adc xl, R1           ;
        adc xh, R2           ;Add the Carry Bit

        movw tl, xl          ; result to parameter stack
        movw nl, wl          ; result to parameter stack 
        
        eor R1, R1           ; keep R1 as zero

        rspull xl, xh        ; restore psp

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

