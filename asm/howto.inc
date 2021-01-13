/*

  forth for ATMEGA8, 8k flash, 1k SRAM,
  internal clock 8 MHz, USART 9600,8,N,1
 
  using GCC avr-as -mmcu=atmega8
 
  vide https://www.ic.unicamp.br/~celio/mc404-2014/docs/gnu-arm-directives.pdf
 
  on a 8 MHz clock frequency, one instruction cycle requires 1/8 us or 125 ns
 
  "The job isn't over until the paperwork is done."
 
  "The first register is always the target register !"
 
  .equ assign a constant value to a label
 
  .set assign a variable value to a label
 
  .rept number \n codes \n .endr ; repeats "codes" number times
 
		
		1.   System dictionary space used in bytes 

      	2.   Application dictionary space available in bytes 

      	3.   Data space in bytes 

      	4.   Return stack space in bytes 
 

 A dictionary with leaves and twigs, without any assembler inside, only references and static values

 FORTH event loop is COLD-->QUIT-->BEGIN-QUERY-EVAL-AGAIN
 
 stacks are last in first out, LIFO
 
 POP == .SP + 1;
 PSH == .SP - 1;
 
 convention for translate forth names to assembler names
 
 use LE for <=
 use GT for >=
 use NE for <>
 use LT for <
 use GT for >
 use EQ for =
 use TK for '
 
 use MUL for *
 use DIV for /
 use PLUS for +
 use MINUS for -
 
 use BY for /
 use QM for ?
 use AT for @
 use TO for !
 use ZERO for 0
 use ONE for 1
 use TWO for 2
 
 use name between parentesis (name) for internal use of forth
 
;----------------------------------------------------------------------
; dictionary structure
;
 .word  link     link to previous
 .byte  size     sizeof name OR mask 0x1F
 .ascii "name"   name, plus a byte 0 if size is odd
 .byte  opcode   opcode
 .word  param,   many

*/
