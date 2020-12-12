
;----------------------------------------------------------------------
;
;	SRAM for user start at 0x060, 
;	forth reserves 0x060 to 0x0BF, about 48 words
;	user  variables starts at 0x0C0
;
;	Better Save Space.' Since the BSS segment only holds variables that don't have any value yet,
;
;----------------------------------------------------------------------
;
;	puts literal (word) into parameter stack
;

;----------------------------------------------------------------------
;
;	ok  push address of "" into parameter stack
;
;	.s/.equ \+\(.\+\) ,.\+/TWIG 0, "\1"\r;ISVARIABLE \1\r/

;
;----------------------------------------------------------------------

;----------------------------------------------------------------------
;
;	creates forth variables, pushes the address
;
TWIG 0, "BASE"
;ISVARIABLE BASE
.word LITERAL
.word BASE
.word EXIT

TWIG 0, "TIB"
;ISVARIABLE TIB
.word LITERAL
.word TIB
.word EXIT

TWIG 0, ">IN"
;ISVARIABLE TIN
.word LITERAL
.word TIN
.word EXIT

TWIG 0, "CUR"
;ISVARIABLE CUR
.word LITERAL
.word CUR
.word EXIT

TWIG 0, "CSP"
;ISVARIABLE CSP
.word LITERAL
.word CSP
.word EXIT

TWIG 0, "CONTEXT"
;ISVARIABLE CONTEXT
.word LITERAL
.word CONTEXT
.word EXIT

TWIG 0, "CURRENT"
;ISVARIABLE CURRENT
.word LITERAL
.word CURRENT
.word EXIT

TWIG 0, "HANDLER"
;ISVARIABLE HANDLER
.word LITERAL
.word HANDLER
.word EXIT

TWIG 0, "HLD"
;ISVARIABLE HLD
.word LITERAL
.word HLD
.word EXIT

TWIG 0, "SPAN"
;ISVARIABLE SPAN
.word LITERAL
.word SPAN
.word EXIT

TWIG 0, "SP0"
;ISVARIABLE SP0
.word LITERAL
.word SP0
.word EXIT

TWIG 0, "RP0"
;ISVARIABLE RP0
.word LITERAL
.word RP0
.word EXIT

TWIG 0, "UP"
;ISVARIABLE UP
.word LITERAL
.word UP
.word EXIT

TWIG 0, "CP"
;ISVARIABLE CP
.word LITERAL
.word CP
.word EXIT

TWIG 0, "STATE"
;ISVARIABLE STATE
.word LITERAL
.word STATE
.word EXIT

TWIG 0, "TIMER"
;ISVARIABLE TIMER
.word LITERAL
.word TIMER
.word EXIT

TWIG 0, "LAST"
;ISVARIABLE LAST
.word LITERAL
.word LAST
.word EXIT


.section .data
.global variables
variables:

 BASE: .word 1
 TIB: .word 1
 TIN: .word 1
 CUR: .word 1
 CSP: .word 1
 CONTEXT: .word 1
 CURRENT: .word 1
 HANDLER: .word 1
 HLD: .word 1
 SPAN: .word 1
 SP0: .word 1
 RP0: .word 1
 UP: .word 1
 CP: .word 1
 STATE: .word 1
 TIMER: .word 1
 LAST: .word 1



