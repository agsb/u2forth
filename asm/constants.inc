
/*
;----------------------------------------------------------------------
;
;     define ascii constants 
;
; from forth std 2012
\z	NUL(no character,ASCII 0)
\a	BEL(alert,ASCII 7)
\b	BS(backspace,ASCII 8)
\t	HT(horizontal tab,ASCII 9)
\v	VT(vertical tab,ASCII 11)
\f	FF(form feed,ASCII 12)
\r	CR(carriage return,ASCII 13)
\l	LF(line feed,ASCII 10)
\m	CR/LF pair(ASCII 13, 10)
\n	newline (implementation dependent , e.g., CR/LF, CR, LF, LF/CR)
\e	ESC(escape,ASCII 27)
\q	double-quote (ASCII 34)
\"	double-quote(ASCII 34)
\\	backslash itself(ASCII 92)
\x	〈hexdigit〉〈hexdigit〉	The resulting character is the conversion of these two hexadecimal digits. 
							An ambiguous conditions exists if \x is not followed by two hexadecimal characters.
*/

/*
: ':'
	[		\ go into immediate mode (temporarily)
	CHAR :		\ push the number 58 (ASCII code of colon) on the parameter stack
	]		\ go back to compile mode
	LITERAL		\ compile LIT 58 as the definition of ':' word
;

\ A few more character constants defined the same way as above.
: ';' [ CHAR ; ] LITERAL ;
: '(' [ CHAR ( ] LITERAL ;
: ')' [ CHAR ) ] LITERAL ;
: '"' [ CHAR " ] LITERAL ;
: 'A' [ CHAR A ] LITERAL ;
: '0' [ CHAR 0 ] LITERAL ;
: '-' [ CHAR - ] LITERAL ;
: '.' [ CHAR . ] LITERAL ;
*/


		NL = 0		;  	\0	null
        BE = 7		;	^g	\a	bell mark
        BS = 8		;	^h	\b	backspace
        TB = 9		;	^i	\t	horizontal tab
        LF = 10		;	^j	\n	line feed
        VT = 11		;	^v	\v	ivertical tab
        FF = 12		;	^l	\f	form feed
		CR = 13		;	^m	\r	carriage return
        ES = 27		;	^[	\e	escape

		BL = 32		;	space blank character
		QK = 34		;	" quotation mark
		BH = 92		;	\ backslash
		OP = 40		; 	( open
		CP = 41		;   ) close

;----------------------------------------------------------------------
;       NL = 0		;	0	\0	null
TWIG 2, "NL"
NL:
.word	LITL
.byte	NL
.byte	NL
.word	EXIT	;	exit
		
;----------------------------------------------------------------------
;       BE = 7		;	^g	\a	bell mark
;TWIG 2, "BE"
;.word	LITL
;.byte	BE
;.byte	NL
;.word	EXIT	;	exit
		
;----------------------------------------------------------------------
;       BS = 8		;	^h	\b	backspace
TWIG 2, "BS"
BS:
.word	LITL
.byte	BS
.byte	NL
.word	EXIT	;	exit
		
;----------------------------------------------------------------------
;       TB = 9		;	^i	\t	horizontal tab
TWIG 2, "TB"
TB:
.word	LITL
.byte	TB
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       LF = 10		;	^j	\n	line feed
TWIG 2, "LF"
LF:
.word	LITL
.byte	LF
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       VT = 11		;	^v	\v	vertical tab
;TWIG 2, "VT"
;.word	LITL
;.byte	VT
;.byte	NL
;.word	EXIT	;	exit

;----------------------------------------------------------------------
;       FF = 12		;	^l	\f	form feed, Ctrl-Enter
;TWIG 2, "FF"
;.word	LITL
;.byte	FF
;.byte	NL
;.word	EXIT	;	exit

;----------------------------------------------------------------------
;       CR = 13		;	^m	\r	carriage return
TWIG 2, "CR"
CR:
.word	LITL
.byte	CR
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       CN = 24		;	CANCEL
;TWIG 2, "CN"
;.word	LITL
;.byte	CN
;.byte	NL
;.word	EXIT	;	exit

;----------------------------------------------------------------------
;       ES = 27		;	^[	\e	escape
;TWIG 2, "ES"
ES:
.word	LITL
.byte	ES
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;		BL = 32		;	space blank character
TWIG 2, "BL"
BL:
.word	LITL
.byte	BL
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;----------------------------------------------------------------------
;
;	why not ? just for fun
;
;	ROULETTE	37 numbers of roullete in european order
;
TWIG 8, "ROULETTE"
ROULETTE:
.word	EXIT
.word   0
.word   32
.word   15
.word   19
.word   4
.word   21
.word   2
.word   25
.word   17
.word   34
.word   6
.word   27
.word   13
.word   36
.word   11
.word   30
.word   8
.word   23
.word   10
.word   5
.word   24
.word   16
.word   33
.word   1
.word   20
.word   14
.word   31
.word   9
.word   22
.word   18
.word   29
.word   7
.word   28
.word   12
.word   35
.word   3
.word   26
.word	0
;----------------------------------------------------------------------
