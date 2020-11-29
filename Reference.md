
## excerps from internet

# https://www.forth.com/starting-forth/5-fixed-point-arithmetic/

Number	Approximation	Error

π = 	3.141 …	355 / 113	8.5 x 10-8

√2 = 1.414 …	19601 / 13860	1.5 x 10-9

√3 = 1.732 …	18817 / 10864	1.1 x 10-9

e = 2.718 …	28667 / 10546	5.5 x 10-9

√10 = 3.162 …	22936 / 7253	5.7 x 10-9

log(2) / 1.6384 = 0.183 …	2040 / 11103	1.1 x 10-8

ln(2) / 16.384 = 0.042 …	485 / 11464	1.0 x 10-7

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


