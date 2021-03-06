
KEY ( -- c ) HEADER(3,"KEY"); int KEY=COLON(0); BEGIN(1,QKEY); UNTIL(1,EXITT);
WITHIN ( u ul uh -- t ) HEADER(6,"WITHIN"); int WITHI=COLON(7,OVER,SUBBB,TOR,SUBBB,RFROM,ULESS,EXITT);
>CHAR ( c -- c ) HEADER(5,">CHAR"); int TCHAR=COLON(8,DOLIT,0x7F,ANDD,DUPP,DOLIT,127,BLANK,WITHI); IF(3,DROP,DOLIT,0X5F); THEN(1,EXITT);
ALIGNED ( b -- a )HEADER(7,"ALIGNED"); int ALIGN=COLON(7,DOLIT,3,PLUS,DOLIT,0XFFFFFFFC,ANDD,EXITT);
HERE ( -- a ) HEADER(4,"HERE"); int HERE=COLON(3,CP,AT,EXITT);
PAD ( -- a ) HEADER(3,"PAD"); int PAD=COLON(5,HERE,DOLIT,80,PLUS,EXITT);
TIB ( -- a ) HEADER(3,"TIB"); int TIB=COLON(3,TTIB,AT,EXITT);
@EXECUTE ( a -- ) HEADER(8,"@EXECUTE"); int ATEXE=COLON(2,AT,QDUP); IF(1,EXECU); THEN(1,EXITT);
CMOVE ( b b u -- ) HEADER(5,"CMOVE"); int CMOVEE=COLON(0); FOR(0); AFT(8,OVER,CAT,OVER,CSTOR,TOR,ONEP,RFROM,ONEP); THEN(0); NEXT(2,DDROP,EXITT);
MOVE ( b b u -- ) HEADER(4,"MOVE"); int MOVE=COLON(1,CELLD); FOR(0); AFT(8,OVER,AT,OVER,STORE,TOR,CELLP,RFROM,CELLP); THEN(0); NEXT(2,DDROP,EXITT);
FILL( b u c -- ) HEADER(4,"FILL"); int FILL=COLON(1,SWAP); FOR(1,SWAP); AFT(3,DDUP,CSTOR,ONEP); THEN(0); NEXT(2,DDROP,EXITT);

\ Number Conversions

DIGIT ( u -- c ) HEADER(5,"DIGIT"); int DIGIT=COLON(12,DOLIT,9,OVER,LESS,DOLIT,7,ANDD,PLUS,DOLIT,0X30,PLUS,EXITT);
EXTRACT( n base -- n c ) HEADER(7,"EXTRACT"); int EXTRC=COLON(7,DOLIT,0,SWAP,UMMOD,SWAP,DIGIT,EXITT);
<# ( -- ) HEADER(2,"<#"); int BDIGS=COLON(4,PAD,HLD,STORE,EXITT);
HOLD ( c -- ) HEADER(4,"HOLD"); int HOLD=COLON(8,HLD,AT,ONEM,DUPP,HLD,STORE,CSTOR,EXITT);
# (dig) ( u -- u ) HEADER(1,"#"); int DIG=COLON(5,BASE,AT,EXTRC,HOLD,EXITT);
#S (digs) ( u -- 0 ) HEADER(2,"#S"); int DIGS=COLON(0); BEGIN(2,DIG,DUPP); WHILE(0); REPEAT(1,EXITT);
SIGN ( n -- ) HEADER(4,"SIGN"); int SIGN=COLON(1,ZLESS); IF(3,DOLIT,0X2D,HOLD); THEN(1,EXITT);
#> ( w -- b u ) HEADER(2,"#>"); int EDIGS=COLON(7,DROP,HLD,AT,PAD,OVER,SUBBB,EXITT);
str ( n -- b u ) HEADER(3,"str"); int STRR=COLON(9,DUPP,TOR,ABSS,BDIGS,DIGS,RFROM,SIGN,EDIGS,EXITT);
HEX ( -- ) sets HEADER(3,"HEX"); int HEXX=COLON(5,DOLIT,16,BASE,STORE,EXITT);
DECIMAL ( -- ) HEADER(7,"DECIMAL"); int DECIM=COLON(5,DOLIT,10,BASE,STORE,EXITT);
wupper ( w -- w' ) HEADER(6,"wupper"); int UPPER=COLON(4,DOLIT,0x5F5F5F5F,ANDD,EXITT);
>upper ( c -- UC ) HEADER(6,">upper"); int TOUPP=COLON(6,DUPP,DOLIT,0x61,DOLIT,0x7B,WITHI); IF(3,DOLIT,0x5F,ANDD); THEN(1,EXITT);
DIGIT? ( c base -- u t ) HEADER(6,"DIGIT?"); int DIGTQ=COLON(9,TOR,TOUPP,DOLIT,0X30,SUBBB,DOLIT,9,OVER,LESS); IF(8,DOLIT,7,SUBBB,DUPP,DOLIT,10,LESS,ORR); THEN(4,DUPP,RFROM,ULESS,EXITT);
NUMBER? ( a -- n T | a F ) HEADER(7,"NUMBER?"); int NUMBQ=COLON(12,BASE,AT,TOR,DOLIT,0,OVER,COUNT,OVER,CAT,DOLIT,0X24,EQUAL); IF(5,HEXX,SWAP,ONEP,SWAP,ONEM); THEN(13,OVER,CAT,DOLIT,0X2D,EQUAL,TOR,SWAP,RAT,SUBBB,SWAP,RAT,PLUS,QDUP); IF(1,ONEM); FOR(6,DUPP,TOR,CAT,BASE,AT,DIGTQ); WHILE(7,SWAP,BASE,AT,STAR,PLUS,RFROM,ONEP); NEXT(2,DROP,RAT); IF(1,NEGAT); THEN(1,SWAP); ELSE(6,RFROM,RFROM,DDROP,DDROP,DOLIT,0); THEN(1,DUPP); THEN(6,RFROM,DDROP,RFROM,BASE,STORE,EXITT);

\ Text Output

SPACE ( -- ) HEADER(5,"SPACE"); int SPACE=COLON(3,BLANK,EMIT,EXITT);
CHARS ( +n c -- ) HEADER(5,"CHARS"); int CHARS=COLON(4,SWAP,DOLIT,0,MAX); FOR(0); AFT(2,DUPP,EMIT); THEN(0); NEXT(2,DROP,EXITT);
SPACES ( +n -- ) HEADER(6,"SPACES"); int SPACS=COLON(3,BLANK,CHARS,EXITT);
TYPE ( b u -- ) HEADER(4,"TYPE"); int TYPES=COLON(0); FOR(0); AFT(5,DUPP,CAT,TCHAR,EMIT,ONEP); THEN(0); NEXT(2,DROP,EXITT);
CR ( -- ) HEADER(2,"CR"); int CR=COLON(7,DOLIT,10,DOLIT,13,EMIT,EMIT,EXITT);
do$ ( -- $adr ) HEADER(3,"do$"); int DOSTR=COLON(10,RFROM,RAT,RFROM,COUNT,PLUS,ALIGN,TOR,SWAP,TOR,EXITT);
$”| ( -- a ) HEADER(3,"$\"|"); int STRQP=COLON(2,DOSTR,EXITT);
”| ( -- ) HEADER(3,".\"|"); int DOTQP=COLON(4,DOSTR,COUNT,TYPES,EXITT);
.R ( u +n -- ) HEADER(2,".R"); int DOTR=COLON(8,TOR,STRR,RFROM,OVER,SUBBB,SPACS,TYPES,EXITT);
U.R ( u +n -- ) HEADER(3,"U.R"); int UDOTR=COLON(10,TOR,BDIGS,DIGS,EDIGS,RFROM,OVER,SUBBB,SPACS,TYPES,EXITT);
U. ( u -- ) HEADER(2,"U."); int UDOT=COLON(6,BDIGS,DIGS,EDIGS,SPACE,TYPES,EXITT);
. (dot) ( n -- ) HEADER(1,"."); int DOT=COLON(5,BASE,AT,DOLIT,10,XORR); IF(3,UDOT,EXITT); THEN(4,STRR,SPACE,TYPES,EXITT);
? ( a -- ) HEADER(1,"?"); int QUEST=COLON(3,AT,DOT,EXITT);

\ Dictionary Search

(parse) ( b1 u1 c --b2 u2 n ) HEADER(7,"(parse)"); int PARS=COLON(5,TEMP,CSTOR,OVER,TOR,DUPP); IF(5,ONEM,TEMP,CAT,BLANK,EQUAL); IF(0); FOR(6,BLANK,OVER,CAT,SUBBB,ZLESS,INVER); WHILE(1,ONEP); NEXT(6,RFROM,DROP,DOLIT,0,DUPP,EXITT); THEN(1,RFROM); THEN(2,OVER,SWAP); FOR(9,TEMP,CAT,OVER,CAT,SUBBB,TEMP,CAT,BLANK,EQUAL); IF(1,ZLESS); THEN(0); WHILE(1,ONEP); NEXT(2,DUPP,TOR); ELSE(5,RFROM,DROP,DUPP,ONEP,TOR); THEN(6,OVER,SUBBB,RFROM,RFROM,SUBBB,EXITT); THEN(4,OVER,RFROM,SUBBB,EXITT);
PACK$ ( b u a -- a ) HEADER(5,"PACK$"); int PACKS=COLON(18,DUPP,TOR,DDUP,PLUS,DOLIT,0xFFFFFFFC,ANDD,DOLIT,0,SWAP,STORE,D DUP,CSTOR,ONEP,SWAP,CMOVEE,RFROM,EXITT);
PARSE ( c -- b u ; <string> ) HEADER(5,"PARSE"); int PARSE=COLON(15,TOR,TIB,INN,AT,PLUS,NTIB,AT,INN,AT,SUBBB,RFROM,PARS,INN,PSTOR ,EXITT);
TOKEN ( -- a ;; <string> ) HEADER(5,"TOKEN"); int TOKEN=COLON(9,BLANK,PARSE,DOLIT,0x1F,MIN,HERE,CELLP,PACKS,EXITT); PACK$ ;;
WORD ( c -- a ; <string> ) HEADER(4,"WORD"); int WORDD=COLON(5,PARSE,HERE,CELLP,PACKS,EXITT);
NAME> ( nfa – cfa) HEADER(5,"NAME>"); int NAMET=COLON(7,COUNT,DOLIT,0x1F,ANDD,PLUS,ALIGN,EXITT);
SAME? ( a1 a2 n – a1 a2 f) HEADER(5,"SAME?"); int SAMEQ=COLON(4,DOLIT,0x1F,ANDD,CELLD); FOR(0); AFT(18,OVER,RAT,DOLIT,4,STAR,PLUS,AT,UPPER,OVER,RAT,DOLIT,4,STAR,PLUS,AT,U PPER,SUBBB,QDUP); IF(3,RFROM,DROP,EXITT); THEN(0); THEN(0); NEXT(3,DOLIT,0,EXITT);
find ( a va --cfa nfa, a F) HEADER(4,"find"); int FIND=COLON(10,SWAP,DUPP,AT,TEMP,STORE,DUPP,AT,TOR,CELLP,SWAP); BEGIN(2,AT,DUPP); IF(9,DUPP,AT,DOLIT,0xFFFFFF3F,ANDD,UPPER,RAT,UPPER,XORR); IF(3,CELLP,DOLIT,0XFFFFFFFF); ELSE(4,CELLP,TEMP,AT,SAMEQ); THEN(0); ELSE(6,RFROM,DROP,SWAP,CELLM,SWAP,EXITT); THEN(0); WHILE(2,CELLM,CELLM); REPEAT(9,RFROM,DROP,SWAP,DROP,CELLM,DUPP,NAMET,SWAP,EXITT); 

\Interpreter

NAME? ( a -- cfa na | a 0 ) HEADER(5,"NAME?"); int NAMEQ=COLON(3,CNTXT,FIND,EXITT);
EXPECT ( b u1 -- ) HEADER(6,"EXPECT"); int EXPEC=COLON(5,ACCEP,SPAN,STORE,DROP,EXITT);
QUERY ( -- ) HEADER(5,"QUERY"); int QUERY=COLON(12,TIB,DOLIT,0X100,ACCEP,NTIB,STORE,DROP,DOLIT,0,INN,STORE,EX
ITT);
ABORT ( -- ) HEADER(5,"ABORT"); int ABORT=COLON(4,NOP,TABRT,ATEXE,EXITT);
abort”| ( f -- ) HEADER(6,"abort\""); ABORQP=COLON(0); IF(4,DOSTR,COUNT,TYPES,ABORT); THEN(3,DOSTR,DROP,EXITT);
ERROR ( a -- ) HEADER(5,"ERROR"); int ERRORR=COLON(8,SPACE,COUNT,TYPES,DOLIT,0x3F,EMIT,CR,ABORT);
$INTERPRET ( a -- ) HEADER(10,"$INTERPRET"); int INTER=COLON(2,NAMEQ,QDUP); IF(4,CAT,DOLIT,COMPO,ANDD); ABORQ(" compile only");
int INTER0=LABEL(2,EXECU,EXITT); THEN(1,NUMBQ); IF(1,EXITT); THEN(1,ERRORR);
[ (left-paren) ( -- ) HEADER(IMEDD+1,"["); int LBRAC=COLON(5,DOLIT,INTER,TEVAL,STORE,EXITT);
.OK ( -- ) HEADER(3,".OK"); int DOTOK=COLON(6,CR,DOLIT,INTER,TEVAL,AT,EQUAL); IF(14,TOR,TOR,TOR,DUPP,DOT,RFROM,DUPP,DOT,RFROM,DUPP,DOT,RFROM,DUPP,DOT); DOTQ(" ok>"); THEN(1,EXITT);
EVAL ( -- ) HEADER(4,"EVAL"); int EVAL=COLON(1,LBRAC); BEGIN(3,TOKEN,DUPP,AT); WHILE(2,TEVAL,ATEXE); REPEAT(4,DROP,DOTOK,NOP,EXITT);
QUIT ( -- ) HEADER(4,"QUIT"); int QUITT=COLON(1,LBRAC); BEGIN(2,QUERY,EVAL); AGAIN(0);
LOAD ( a n-- ) HEADER(4,"LOAD"); int LOAD=COLON(10,NTIB,STORE,TTIB,STORE,DOLIT,0,INN,STORE,EVAL,EXITT);

\ Compiler

, (comma) ( w -- ) HEADER(1,","); int COMMA=COLON(7,HERE,DUPP,CELLP,CP,STORE,STORE,EXITT);
LITERAL ( n -- ) HEADER(IMEDD+7,"LITERAL"); int LITER=COLON(5,DOLIT,DOLIT,COMMA,COMMA,EXITT);
ALLOT ( n -- ) HEADER(5,"ALLOT"); int ALLOT=COLON(4,ALIGN,CP,PSTOR,EXITT);
$,” ( -- ) HEADER(3,"$,\""); int STRCQ=COLON(9,DOLIT,0X22,WORDD,COUNT,PLUS,ALIGN,CP,STORE,EXITT);
?UNIQUE ( a -- a ) HEADER(7,"?UNIQUE"); int UNIQU=COLON(3,DUPP,NAMEQ,QDUP); IF(6,COUNT,DOLIT,0x1F,ANDD,SPACE,TYPES); DOTQ(" reDef"); THEN(2,DROP,EXITT);
$,n ( a -- ) HEADER(3,"$,n"); int SNAME=COLON(2,DUPP,AT); IF(14,UNIQU,DUPP,NAMET,CP,STORE,DUPP,LAST,STORE,CELLM,CNTXT,AT,SWAP,STORE, EXITT); THEN(1,ERRORR);
' (tick) ( -- cfa ) HEADER(1,"'"); int TICK=COLON(2,TOKEN,NAMEQ); IF(1,EXITT); THEN(1,ERRORR);
[COMPILE] ( -- ; <string> ) HEADER(IMEDD+9,"[COMPILE]"); int BCOMP=COLON(3,TICK,COMMA,EXITT);
COMPILE ( -- ) HEADER(7,"COMPILE"); int COMPI=COLON(7,RFROM,DUPP,AT,COMMA,CELLP,TOR,EXITT);
$COMPILE ( a -- ) HEADER(8,"$COMPILE"); int SCOMP=COLON(2,NAMEQ,QDUP); IF(4,AT,DOLIT,IMEDD,ANDD); IF(1,EXECU); ELSE(1,COMMA); THEN(1,EXITT); THEN(1,NUMBQ); IF(2,LITER,EXITT); THEN(1,ERRORR);
OVERT ( -- ) HEADER(5,"OVERT"); int OVERT=COLON(5,LAST,AT,CNTXT,STORE,EXITT);
] (right paren) ( -- ) HEADER(1,"]"); int RBRAC=COLON(5,DOLIT,SCOMP,TEVAL,STORE,EXITT);
: (colon) ( -- ; <string> ) HEADER(1,":"); int COLN=COLON(7,TOKEN,SNAME,RBRAC,DOLIT,0x6,COMMA,EXITT);
; (semi-colon) ( -- ) HEADER(IMEDD+1,";"); int SEMIS=COLON(6,DOLIT,EXITT,COMMA,LBRAC,OVERT,EXITT);

\ Debugging Tools

dm+ ( b u – b+u ) HEADER(3,"dm+"); int DMP=COLON(4,OVER,DOLIT,6,UDOTR); FOR(0); AFT(6,DUPP,AT,DOLIT,9,UDOTR,CELLP); THEN(0); NEXT(1,EXITT);
DUMP ( b u -- ) HEADER(4,"DUMP"); int DUMP=COLON(10,BASE,AT,TOR,HEXX,DOLIT,0x1F,PLUS,DOLIT,0x20,SLASH); FOR(0); AFT(10,CR,DOLIT,8,DDUP,DMP,TOR,SPACE,CELLS,TYPES,RFROM); THEN(0); NEXT(5,DROP,RFROM,BASE,STORE,EXITT);
>NAME ( cfa -- nfa | F ) HEADER(5,">NAME"); int TNAME=COLON(1,CNTXT); BEGIN(2,AT,DUPP); WHILE(3,DDUP,NAMET,XORR); IF(1,ONEM); ELSE(3,SWAP,DROP,EXITT); THEN(0); REPEAT(3,SWAP,DROP,EXITT);
.ID ( a -- ) HEADER(3,".ID"); int DOTID=COLON(7,COUNT,DOLIT,0x1F,ANDD,TYPES,SPACE,EXITT);
WORDS ( -- ) HEADER(5,"WORDS"); int WORDS=COLON(6,CR,CNTXT,DOLIT,0,TEMP,STORE); BEGIN(2,AT,QDUP); WHILE(9,DUPP,SPACE,DOTID,CELLM,TEMP,AT,DOLIT,0x10,LESS); IF(4,DOLIT,1,TEMP,PSTOR); ELSE(5,CR,DOLIT,0,TEMP,STORE); THEN(0); REPEAT(1,EXITT);
FORGET ( -- , <name>) HEADER(6,"FORGET"); int FORGT=COLON(3,TOKEN,NAMEQ,QDUP); IF(12,CELLM,DUPP,CP,STORE,AT,DUPP,CNTXT,STORE,LAST,STORE,DROP,EXITT); THEN(1,ERRORR);
COLD ( -- ) HEADER(4,"COLD"); int COLD=COLON(1,CR); DOTQ("esp32forth V5.4, 2019 "); int DOTQ1=LABEL(2,CR,EXITT);

\ Control Structures

THEN ( A -- ) HEADER(IMEDD+4,"THEN"); int THENN=COLON(4,HERE,SWAP,STORE,EXITT);
FOR ( -- a ) HEADER(IMEDD+3,"FOR"); int FORR=COLON(4,COMPI,TOR,HERE,EXITT);
BEGIN ( -- a ) HEADER(IMEDD+5,"BEGIN"); int BEGIN=COLON(2,HERE,EXITT);
NEXT ( a -- ) HEADER(IMEDD+4,"NEXT"); int NEXT=COLON(4,COMPI,DONXT,COMMA,EXITT);
UNTIL ( a -- ) HEADER(IMEDD+5,"UNTIL"); int UNTIL=COLON(4,COMPI,QBRAN,COMMA,EXITT);
AGAIN ( a -- ) HEADER(IMEDD+5,"AGAIN"); int AGAIN=COLON(4,COMPI,BRAN,COMMA,EXITT);
IF ( -- A ) HEADER(IMEDD+2,"IF"); int IFF=COLON(7,COMPI,QBRAN,HERE,DOLIT,0,COMMA,EXITT);
AHEAD ( -- A ) HEADER(IMEDD+5,"AHEAD"); int AHEAD=COLON(7,COMPI,BRAN,HERE,DOLIT,0,COMMA,EXITT);
REPEAT ( A a -- ) HEADER(IMEDD+6,"REPEAT"); int REPEA=COLON(3,AGAIN,THENN,EXITT);
AFT ( a -- a A ) HEADER(IMEDD+3,"AFT"); int AFT=COLON(5,DROP,AHEAD,HERE,SWAP,EXITT);
ELSE ( A -- A ) HEADER(IMEDD+4,"ELSE"); int ELSEE=COLON(4,AHEAD,SWAP,THENN,EXITT);
WHILE ( a -- A a ) HEADER(IMEDD+5,"WHILE"); int WHILEE=COLON(3,IFF,SWAP,EXITT);

\ String Literals

ABORT" ( -- ; <string> ) HEADER(IMEDD+6,"ABORT\""); int ABRTQ=COLON(6,DOLIT,ABORQP,HERE,STORE,STRCQ,EXITT);
$" ( -- ; <string> ) HEADER(IMEDD+2,"$\""); int STRQ=COLON(6,DOLIT,STRQP,HERE,STORE,STRCQ,EXITT);
." (dot-quot) ( -- ; <string> ) HEADER(IMEDD+2,".\""); int DOTQQ=COLON(6,DOLIT,DOTQP,HERE,STORE,STRCQ,EXITT);

\ Defining words

CODE ( -- ; <string> ) HEADER(4,"CODE"); int CODE=COLON(5,TOKEN,SNAME,OVERT,ALIGN,EXITT);
CREATE ( -- ; <string> ) HEADER(6,"CREATE"); int CREAT=COLON(5,CODE,DOLIT,0x203D,COMMA,EXITT);
VARIABLE ( -- ; <string> ) HEADER(8,"VARIABLE"); int VARIA=COLON(5,CREAT,DOLIT,0,COMMA,EXITT);
CONSTANT ( n -- ; <string> ) HEADER(8,"CONSTANT"); int CONST=COLON(6,CODE,DOLIT,0x2004,COMMA,COMMA,EXITT);

\ Comments

.( (dot-paren) ( -- ; <string> ) HEADER(IMEDD+2,".("); int DOTPR=COLON(5,DOLIT,0X29,PARSE,TYPES,EXITT);
\ (back-slash) ( -- ; <string> ) HEADER(IMEDD+1,"\\"); int BKSLA=COLON(5,DOLIT,0xA,WORDD,DROP,EXITT);
( (paren) ( -- ; <string> ) HEADER(IMEDD+1,"("); int PAREN=COLON(5,DOLIT,0X29,PARSE,DDROP,EXITT);

\ Lexicon Bits

COMPILE-ONLY ( -- ) HEADER(12,"COMPILE-ONLY"); int ONLY=COLON(6,DOLIT,0x40,LAST,AT,PSTOR,EXITT);
IMMEDIATE ( -- ) HEADER(9,"IMMEDIATE"); int IMMED=COLON(6,DOLIT,0x80,LAST,AT,PSTOR,EXITT);


