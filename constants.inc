;----------------------------------------------------------------------
;
;     define ascii constants 
;

		NL = 0		;  	\0	null
        BE = 7		;	^g	\a	bell mark
        BS = 8		;	^h	\b	backspace
        TB = 9		;	^i	\t	horizontal tab
        LF = 10		;	^j	\n	line feed
        VT = 11		;	^v	\v	ivertical tab
        FF = 12		;	^l	\f	form feed
		CR = 13		;	^m	\r	carriage return
        CN = 24		;	Cancel
        ES = 27		;	^[	\e	escape
		BL = 32		;	blank character
		QK = 34		;	quotation mark
		BH = 92		;	backslash

;----------------------------------------------------------------------
;       NL = 0		;	0	\0	null
TWIG 2,"NL"
.word	LITERAL
.byte	NL
.byte	NL
.word	EXIT	;	exit
		
;----------------------------------------------------------------------
;       BE = 7		;	^g	\a	bell mark
TWIG 2,"BE"
.word	LITERAL
.byte	BE
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
;       VT = 11		;	^v	\v	vertical tab
TWIG 2,"VT"
.word	LITERAL
.byte	VT
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;       FF = 12		;	^l	\f	form feed, Ctrl-Enter
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
;       CN = 24		;	CANCEL
TWIG 2,"CN"
.word	LITERAL
.byte	CN
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
;		BL = 32		;	space blank character
TWIG 2,"BL"
.word	LITERAL
.byte	BL
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;		QK = 34		;	"	quotation mark
TWIG 2,"QK"
.word	LITERAL
.byte	QK
.byte	NL
.word	EXIT	;	exit

;----------------------------------------------------------------------
;		BH = 92		;	\	backslash
TWIG 2,"BH"
.word	LITERAL
.byte	BH
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
