

;----------------------------------------------------------------------
;	: VARIABLE CREATE  0 , ;
TWIG 8, "VARIABLE"
VARIABLE:, CREATE, LITERAL, 0x0000, COMMA, EXIT

;----------------------------------------------------------------------
;
TWIG 5, "ALLOT"
ALLOT:, LITERAL, CP, PLUSTO, EXIT

;----------------------------------------------------------------------
;
TWIG 4, "HERE"
HERE:, LITERAL, CP, AT, EXIT

;----------------------------------------------------------------------
;
TWIG 3, "PAD"
PAD:, HERE, LITERAL, BUFFER_SIZE, PLUS, EXIT

;----------------------------------------------------------------------
;
TWIG 5, "COUNT"
COUNT:, DUP, ONEPLUS, SWAP, CAT, EXIT

;----------------------------------------------------------------------
TWIG 5, "KEY"
KEY:, KEYQM, QMBRANCH, KEY, EXIT	

;----------------------------------------------------------------------
TWIG 5, "EMIT"
EMIT:, EMITQM, QMBRANCH, EMIT, EXIT	

;----------------------------------------------------------------------
TWIG 5, "CR"
CREMIT:, CR, EMIT, LF, EMIT, EXIT		

;----------------------------------------------------------------------
TWIG 5, "BL"
BLEMIT:, BL, EMIT, EXIT		

;----------------------------------------------------------------------
TWIG 10, "IMMEDIATE?"
IMMEDIATEQM:, LITERAL, F_IMMEDIATE, ZEROEQ, QMBRANCH, FTRUE, FFALSE, EXIT		

;----------------------------------------------------------------------
;	COMPILE?
TWIG 8, "COMPILE?"
COMPILEQM:, LITERAL, F_COMPILE, ZEROEQ, QMBRANCH, FTRUE, FFALSE, EXIT		

;----------------------------------------------------------------------
;	HIDDEN?
TWIG 7, "HIDDEN?"
HIDDEN:, LITERAL, F_HIDDEN, ZEROEQ, QMBRANCH, FTRUE, FFALSE, EXIT


;----------------------------------------------------------------------
; forth2012
;	but only ASCII, not UTF-8 aka CHAR
;
TWIG 5, "TYPE"
TYPE:, DUP, QMBRANCH, _TYPE1, OVER, CAT, EMIT, ONEMINUS, SWAP, ONEPLUS, SWAP, BRANCH, DUP	
_TYPE1:, TWODROP, EXIT		

;----------------------------------------------------------------------
; forth2012
;	but only ASCII, not UTF-8 aka CHAR
;
TWIG 5, "EXPECT"
EXPECT:, DUP, QMBRANCH, _EXPECT1, OVER, CAT, EMIT, ONEMINUS, SWAP, ONEPLUS, SWAP, BRANCH, DUP	
_EXPECT1:, TWODROP, EXIT		

;----------------------------------------------------------------------
;	ok	[	state is execute
TWIG 1, "["		
ISEXEC:, LITERAL, FFALSE, STATE, TO, EXIT

;----------------------------------------------------------------------
;	ok	]	state is compile
TWIG 1, "]"
ISCOMP:, LITERAL, FTRUE, STATE, TO, EXIT

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
TWIG 3, "OCT", LITERAL
.byte	OCT
.byte	NL, BASE	;	address of BASE variable, TO		;	!, EXIT	;	exit

;----------------------------------------------------------------------
; DECIMAL		;	0	\0	null
TWIG 3, "DEC", LITERAL
.byte	TEN
.byte	NL, BASE	;	address of BASE variable, TO		;	!, EXIT	;	exit

;----------------------------------------------------------------------
; HEX		;	0	\0	null
TWIG 3, "HEX", LITERAL
.byte	HEX
.byte	NL, BASE	;	address of BASE variable, TO		;	!, EXIT	;	exit

;----------------------------------------------------------------------
;----------------------------------------------------------------------




;----------------------------------------------------------------------
;----------------------------------------------------------------------
;----------------------------------------------------------------------
;----------------------------------------------------------------------
TWIG 5, "DIGIT", LITERAL, 0x0009, OVER, LTHAN, LITERAL, 0x0007, AND, PLUS, LITERAL, '0', PLUS, EXIT


;----------------------------------------------------------------------
TWIG 2, "<#"
BDIGS:, PAD, HLD, TO, EXIT

;----------------------------------------------------------------------
TWIG 5, "BEGIN", IMMEDIATE, HERE , EXIT

;----------------------------------------------------------------------
TWIG 5, "DO", IMMEDIATE, POSTPONE, TWOTOR, HERE , EXIT

;----------------------------------------------------------------------
TWIG 1, ":"
COLON:, ISCOMP, BEGIN, BL, FIND, DUP, IF, FFALSE, EQUAL	, IF, EXECUTE, STACKQ, ABORT"
.ascii	" stack empty\"", ELSE, COMMA, THEN, ELSE


;----------------------------------------------------------------------
TWIG 1, ";", POSTPONE, EXIT, REVEAL, POSTPONE, OPÊNCOL, EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 5, "CATCH"
CATCH:, SPAT, GTR, HANDLER, AT, GTR, RPAT, HANDLER, TO, EXECUTE, RGT, HANDLER, TO, RGT, DROP, FFALSE, EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 5, "THROW"
THROW:, HANDLER, AT, PSTO, RGT, HANDLER, TO, RGT, SWAP, RGT, SPTO, DROP, RGT, EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 1, ","
COMMA:, HERE, DUP, CELLPLUS, CP, TO, TO, EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 1, "'"
TICK:, TOKEN, NAMEQ, QMBRANCH, EXIT, THROW, EXIT

;----------------------------------------------------------------------
;	eforth	ok 
;
TWIG 4, "[COMPILE]"
COMPILEMD:, RGT, DUP, AT, COMMA, CELLPLUS, RGT, PLUSTO , EXIT

;----------------------------------------------------------------------
;	
;	create a word in dictionary, uses next word in TIB pointed by
;
TWIG 4, "CREATE", EXIT

;----------------------------------------------------------------------
;	
;	create a word in dictionary, uses next word in TIB pointed by
;
TWIG 4, "DOES>", EXIT

;----------------------------------------------------------------------
;
TWIG 4, "CONSTANT", CREATE, COMMA, DOES, AT, EXIT

;----------------------------------------------------------------------
;
TWIG 4, "VARIABLE", CREATE, LITERAL, 0x0000, COMMA, EXIT

;-----------------------------------------------------------------
; eforth
;
TWIG 4, "doVAR"
doVAR:, EXIT

;----------------------------------------------------------------------
; eforth
;
TWIG 4, "doVOC"
doVOC:, EXIT

;----------------------------------------------------------------------
; eforth
;
TWIG 4, "doUSER"
doUSER:, EXIT

;----------------------------------------------------------------------
; eforth
;
TWIG 4, "FORTH"
FORTH:, EXIT



