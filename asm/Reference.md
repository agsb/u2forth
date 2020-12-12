
## 	excerps from internet

# 	https://www.forth.com/starting-forth/5-fixed-point-arithmetic/

#	http://wilsonminesco.com/16bitMathTables/RationalApprox.html

Number	Approximation	Error

π = 	3.141 …	355 / 113	8.5 x 10-8

√2 = 1.414 …	19601 / 13860	1.5 x 10-9

√3 = 1.732 …	18817 / 10864	1.1 x 10-9

e = 2.718 …		28667 / 10546	5.5 x 10-9

√10 = 3.162 …	22936 / 7253	5.7 x 10-9

12√2  = 1.059463   26797/25293     -1.7E-9

ln(2)  = 0.6931472	7050/10171     +3.8E-9

ln(10) = 2.302585 12381/5377      -3.6E-9

log(2) = .301029995 4004/13301     +6.9E-9

log(e) = 1.0/ln(10)

lp(e) = 1.0/ln(2)

lp(10) = 1.0/log(2)

## converts

CMIN	cm/in		127/50

INCM	in/cm		50/127

MBYFT	m/ft		1250/381

FTBYM	ft/m		381/1250

MSBYKS	m/s//km/h	18/5

GRAV	gm/s2		37087/3792

PHI		goldem		28657/17711

FINER	alpha		100/137036

CEINS	c uni.		24559/8192

# Systems Guide to figForth, C. H. Ting, 2013

Table 1. Language Definition of Forth

<character> ::= <ASCII code>

<delimiting character> ::= NUL | CR | SP | <designated character>

<delimiter> ::= <delimiting character> |

<delimiting character><delimiter>

<word> ::= <instruction> | <number> | <string>

<string> ::= <character> | <character><string>

<number> ::= <integer> | -<integer>

<integer> ::= <digit> | <digit><integer>

<digit> ::= 0 | 1 | 2 | ... | 9 | A | B | ... | <base-1>

<instruction> ::= <standard instruction> | <user instruction>

<standard instruction> ::= <nucleus instruction> |

<interpreter instruction> |

<compiler instruction> | <device instruction>

<user instruction> ::= <colon instruction> | <code instruction> |

<constant> | <variable> | <vocabulary>

Table 2. Standard Instructions

The list of standard instructions is basically that in Forth-79 Standard.

Minor changes are made to conform to the instruction set used in the fig-Forth Model.

<nucleus instruction> ::= ! | * | */ | */MOD | + | +! | - | -DUP | / | /MOD | 0< | 0= | 0> | 1+ |
1- | 2+ | 2- | < | = | > | >R | @ |ABS | AND | C! | C@ | CMOVE | D+ | D< | DMINUS | DROP | DUP |
EXECUTE | EXIT | FILL | MAX | MIN | MOD | MOVE | NOT | OR | OVER | R> | R | ROT | SWAP | U* | U/
| U< | XOR

<interpreter instruction> ::= # | #> | #S | ' | ( | -TRAILING | . | <# | IN | ? | ABORT | BASE |
BLK | CONTEXT | COUNT | CURRENT | DECIMAL | EXPECT | FIND | FORTH | HERE | HOLD | NUMBER | PAD |
QUERY | QUIT | SIGN | SPACE | SPACES | TYPE | U. | WORD

<compiler instruction> ::= +LOOP | , | ." | : | ; | ALLOT | BEGIN| COMPILE | CONSTANT | CREATE |
DEFINITIONS | DO | DOES> | ELSE | ENDIF | FORGET | I | IF | IMMEDIATE | J | LEAVE | LITERAL |
LOOP | REPEAT | STATE | UNTIL | VARIABLE | VOCABULARY | WHILE | [ | [COMPILE] | ]

<device instruction> ::= BLOCK | BUFFER | CR | EMIT | EMPTY-BUFFERS | FLUSH | KEY | LIST | LOAD |
SCR | UPDATE


