
;----------------------------------------------------------------------
;	: VARIABLE  CREATE   0  ,  ;
TWIG 5, "VARIABLE"
VARIABLE:
.word CREATE
.word LITERAL
.word 0x0000
.word COMMA
.word EXIT

;----------------------------------------------------------------------
;
TWIG 5, "ALLOT"
ALLOT:
.word LITERAL
.word CP
.word PLUSTO
.word EXIT

;----------------------------------------------------------------------
;
TWIG 4, "HERE"
HERE:
.word LITERAL
.word CP
.word AT
.word EXIT

;----------------------------------------------------------------------
;
TWIG 3, "PAD"
PAD:
.word HERE
.word LITERAL
.word BUFFER_SIZE
.word PLUS
.word EXIT

;----------------------------------------------------------------------
;
TWIG 5, "COUNT"
COUNT:
.word DUP
.word ONEPLUS
.word SWAP
.word CAT
.word EXIT

;----------------------------------------------------------------------
TWIG 5, "KEY"
KEY:
.word KEYQM
.word QMBRANCH
.word KEY		
.word EXIT	

;----------------------------------------------------------------------
TWIG 5, "EMIT"
EMIT:
.word EMITQM
.word QMBRANCH
.word EMIT		
.word EXIT	

;----------------------------------------------------------------------
TWIG 5, "CR"
CREMIT:
.word CR
.word EMIT
.word LF
.word EMIT
.word EXIT		

;----------------------------------------------------------------------
TWIG 5, "BL"
BLEMIT:
.word BL
.word EMIT
.word EXIT		

;----------------------------------------------------------------------
TWIG 10, "IMMEDIATE?"
IMMEDIATEQM:
.word LITERAL
.word F_IMMEDIATE
.word ZEROEQ
.word QMBRANCH
.word FTRUE
.word FFALSE
.word EXIT		

;----------------------------------------------------------------------
;	COMPILE?
TWIG 8, "COMPILE?"
COMPILEQM:
.word LITERAL
.word F_COMPILE
.word ZEROEQ
.word QMBRANCH, FTRUE
.word FFALSE
.word EXIT		

;----------------------------------------------------------------------
;	HIDDEN?
TWIG 7, "HIDDEN?"
HIDDEN:
.word LITERAL
.word F_HIDDEN
.word ZEROEQ
.word QMBRANCH, FTRUE
.word FFALSE
.word EXIT


;----------------------------------------------------------------------
; forth2012
;	but only ASCII, not UTF-8 aka CHAR
;
TWIG 5, "TYPE"
TYPE:
.word DUP
.word QMBRANCH
.word _TYPE1
.word OVER
.word CAT
.word EMIT
.word ONEMINUS
.word SWAP
.word ONEPLUS
.word SWAP
.word BRANCH
.word DUP	
_TYPE1:
.word TWODROP
.word EXIT		

;----------------------------------------------------------------------
; forth2012
;	but only ASCII, not UTF-8 aka CHAR
;
TWIG 5, "EXPECT"
EXPECT:
.word DUP
.word QMBRANCH
.word _EXPECT1
.word OVER
.word CAT
.word EMIT
.word ONEMINUS
.word SWAP
.word ONEPLUS
.word SWAP
.word BRANCH
.word DUP	
_EXPECT1:
.word TWODROP
.word EXIT		

;----------------------------------------------------------------------
;	ok	[	state is execute
TWIG 1, "["		
ISEXEC:
.word FFALSE
.word LITERAL
.word STATE
.word TO
.word EXIT

;----------------------------------------------------------------------
;	ok	]	state is compile
TWIG 1, "]"
ISCOMP:
.word FTRUE
.word LITERAL
.word STATE
.word TO
.word EXIT

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
; OCTAL		;	0	\0	null
TWIG 3, "OCT"
.word LITERAL
.byte	OCT
.byte	NL
.word BASE	;	address of BASE variable
.word TO		;	!
.word EXIT	;	exit

;----------------------------------------------------------------------
; DECIMAL		;	0	\0	null
TWIG 3, "DEC"
.word LITERAL
.byte	TEN
.byte	NL
.word BASE	;	address of BASE variable
.word TO		;	!
.word EXIT	;	exit

;----------------------------------------------------------------------
; HEX		;	0	\0	null
TWIG 3, "HEX"
.word LITERAL
.byte	HEX
.byte	NL
.word BASE	;	address of BASE variable
.word TO		;	!
.word EXIT	;	exit

;----------------------------------------------------------------------
;----------------------------------------------------------------------




;----------------------------------------------------------------------
;----------------------------------------------------------------------
;----------------------------------------------------------------------
;----------------------------------------------------------------------
TWIG 5, "DIGIT"
.word LITERAL
.word 0x0009
.word OVER
.word LTHAN
.word LITERAL
.word 0x0007
.word AND
.word PLUS
.word LITERAL
.word '0'
.word PLUS
.word EXIT


;----------------------------------------------------------------------
TWIG 2, "<#"
BDIGS:
.word PAD
.word HLD
.word TO
.word EXIT

;----------------------------------------------------------------------
TWIG 5, "BEGIN"
.word IMMEDIATE
.word HERE 
.word EXIT

;----------------------------------------------------------------------
TWIG 5, "DO"
.word IMMEDIATE
.word POSTPONE
.word TWOTOR
.word HERE 
.word EXIT

;----------------------------------------------------------------------
TWIG 1, ":"
COLON:
.word ISCOMP
.word BEGIN
.word BL
.word FIND
.word DUP
.word IF
.word FFALSE
.word EQUAL	
.word IF
.word EXECUTE
.word STACKQ
.word ABORT"
.ascii	" stack empty\""
.word ELSE
.word COMMA
.word THEN
.word ELSE


;----------------------------------------------------------------------
TWIG 1, ";"
.word POSTPONE
.word EXIT
.word REVEAL
.word POSTPONE
.word OPÊNCOL
.word EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 5, "CATCH"
CATCH:
.word SPAT
.word GTR
.word HANDLER
.word AT
.word GTR
.word RPAT
.word HANDLER
.word TO
.word EXECUTE
.word RGT
.word HANDLER
.word TO
.word RGT
.word DROP
.word FFALSE
.word EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 5, "THROW"
THROW:
.word HANDLER
.word AT
.word PSTO
.word RGT
.word HANDLER
.word TO
.word RGT
.word SWAP
.word RGT
.word SPTO
.word DROP
.word RGT
.word EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 1, ","
COMMA:
.word HERE
.word DUP
.word CELLPLUS
.word CP
.word TO
.word TO
.word EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 1, "'"
TICK:
.word TOKEN
.word NAMEQ
.word QMBRANCH
.word EXIT
.word THROW
.word EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 4, "[COMPILE]"
COMPILEMD:
.word RGT
.word DUP
.word AT
.word COMMA
.word CELLPLUS
.word RGT
.word PLUSTO 
.word EXIT

;----------------------------------------------------------------------
;	
;	create a word in dictionary, uses next word in TIB pointed by
;
TWIG 4, "CREATE"
.word EXIT

;----------------------------------------------------------------------
;	
;	create a word in dictionary, uses next word in TIB pointed by
;
TWIG 4, "DOES>"
.word EXIT

;----------------------------------------------------------------------
;
TWIG 4, "CONSTANT"
.word CREATE
.word COMMA
.word DOES
.word AT
.word EXIT

;----------------------------------------------------------------------
;
TWIG 4, "VARIABLE"
.word CREATE
.word LITERAL
.word 0x0000
.word COMMA
.word EXIT

;-----------------------------------------------------------------
; eforth
;
TWIG 4, "doVAR"
doVAR:
.word EXIT

;----------------------------------------------------------------------
; eforth
;
TWIG 4, "doVOC"
doVOC:
.word EXIT

;----------------------------------------------------------------------
; eforth
;
TWIG 4, "doUSER"
doUSER:
.word EXIT

;----------------------------------------------------------------------
; eforth
;
TWIG 4, "FORTH"
FORTH:
.word EXIT



