b32b6114-2abc-11eb-8261-1be5f55f2874 Thu, 19 Nov 2020 20:12:31 -0300
# https://github.com/agsb/u2forth.git

## u2forth

  A forth virtual machine, still in C language, more one.
  
  But this one is for use into avr microcontroler ATmega8, 
  with RISC 32 8bit registers [1], Harvard model, 8 MHz internal clock, 
  4k 16bit words of FLASH, 1k 8bit bytes of SRAM and 512 8bit bytes for EEPROM.
  
  This is a experience in progress, using avr-gcc -mmcu=atmega8 and to make a startup code for avr-as
  
  Just only core primitives are composed in C, its just a proof of concept, not a full forth coded in C

  WARNING: This C code makes abusive use of goto LABEL:

  The code is simply a enum, a switch, and many gotos.
  
  this is a tribute to G. H. Ting, and his books, papers and perseverance.
  
  SURE, this readme needs updates !
  
  __Not operational yet 11/2020__
  
  # Goals
 
  ALL focus in be simple, be smaller and be smart for ATmega8 (ATtiny85 too)
  
  To self learn about (AVR) RISC assembler, using avr-gcc with "trampolines" and diferent levels of optimzations, to learn howto.
  
  "Programmers can use trampolined functions to implement tail-recursive function calls in stack-oriented programming languages.[1]"
  
  u2forth is based in eForth from Dr. Ting, except for
 
         1. using Indirect Thread Code, to minimize size of all 
         2. using interrupts, to have a live system (**)
         3. have a timer in miliseconds, vide 2 (**)
         4. do not use real PC and SP, vide 2
         5. forth core words and constants in flash, as imutable
         6. forth user words and constants in sram, as wipes to nothing
         7. all variables in sram, vide 6
         8. use of poolling USART, vide 2
         9. use of poolling I2C, vide 2 (**)
        10. NO checks for ANY words
 
 (**) not yet;
 
 The forth virtual cpu does bytecodes. the dictionary words can be leafs or twigs, only.
         
          the leafs only contain bytecodes,
         
          the twigs only contains address to words.
 
  WARNING: This C code makes abusive use of goto LABEL:
  
  WARNING: Goal is create a small object code for make a handcraft assembled forth for atmega8
  
  WARNING: Much code was borrowed from internet, with GPL licence, please help me to get all references. 

# Dictionary

  Still now, as opcodes (and goto labels) : 
    
    NOOP=0, THIS, ( doLit )
    
    CODE, ( leaf interpreter, the uC )
    
    NEXT, NEST, UNNEST, ( twig interpreter )
    
    JUMP, JUMPNZ, ( branch, ?branch, )
    
    RTP, R2P, P2R, ( R@, R>, >R, )
    
    DUPNZ, DUP, DROP, SWAP, OVER, ROT, ( as is )
    
    EQZ, LTZ, GTZ, ( =0, <0, >0, )
    
    AND, OR, XOR, INV, CPL, SHL, SHR, ( and, or, xor, inverse, negate, 2*, 2/, )
    
    UMP, ( // UM+ )
    
    RXQU, RXCU, TXCU, IOSU, ( ?rx, rx@, tx@, io_, // pooled USART ) 
    
    DROP2, DUP2, ( 2DROP, 2DUP, as is )
    
    CSTORE, CFETCH, STORE, FETCH, ( C!, C@, !, @, )
    
    CMOVE, CCOMP, MOVE, COMP, ( CMOVE, CCOMPARE, MOVE, COMPARE, moves and compares )
    
    PAD0, PAD1, TIB0, PSP0, RSP0, ( forth address constants )
    
    CELL, FALSE, TRUE, PAD, TIB, BL, (forth values constants )
    
    LAST, DP, LASTR, DPR, ( forth address variables in sram )
    
    ZERO, ONE, SOT, EOT, BS, LF, FF, CR, DLE, CAN, ESC, ( ascii usefull constants ) 
    // 0, 1, 2, 3, 8, 10, 12, 13, 16, 24, 27, (decimal)

# Words

The dictionary of words follow the classic structure, but lives part in FLASH, core imutable, and in SRAM, user temporary. 

  link, adress of previous word, as linked list;
  
  size, size of this word, limited to 31 chars (0x1F), and flags for __IMMEDIATE (0x80), EXCLUSIVE (0x40), HIDDEN (0x20)__;
  
  word, size characters with pad (maybe);
  
  opcode, a single byte with opcode for virtual uC, 0 Nop, 1 Leaf, 2 Twig, 3 - 7 reserved, 8 - 254 words coded in assembler
  
  parameters, a set of opcodes (if leaf) or a set of address of words (if twig)
  
As ATmega8 have only 8k bytes of FLASH then no support for compile new words into FLASH, 
  sure all goes to SRAM, all goes to void.

# Constants and Variables

Those could be defined in assembler as .EQU for constants and as .DW for variables, 
but must be pushed at top of parameter stack

The forth internal constants are

  address: PSP0, RSP0, TIB0, PAD0
  
  values: CELL, FALSE, TRUE, PAD, TIB, BL, ZERO, ONE, TWO
  
  ascii:  \0, \a, \b, \t, \n, \v, \f, \r, \e
 
The forth internal variables are static in sram

  NP, UP, CP, LAST, BASE, SPAN, HLD, CONTEXT. CURRENT, HANDLE, TIN,  

# Details

  Most of Forths are created in old 80 days, for CPUs with few registers and diferent cycles per instructions, and uses a classic virtual model as (under) but uses internal CPU registers extras to scratch and speed.
  
  __IP__    index pointer
  
  __RSP__   return stack pointer
  
  __PSP__   parameter stack pointer
  
  __TOS__   top (first cell) of parameter stack
  
  __W__     work cell scratch
  
  Nowadays, most RISC cpus have at least 32 registers plus Program Counter, Stack Pointer and Status Register, and same cycles per instructions, almost, then to optimize the overhead of memory access, we adopt a virtual model with upto 255 opcodes and registers defined as (under) with ATmega8 registers
 
  __C__    opcode instruction byte, r00   
  
  __NIL__  reserved always 0, r01, ( also modern RISC V uses X00 hardwired as ZERO )
  
  __IP__   instruction index pointer, r30r31 
  
  __W__    work cell for exchange values, r24r25 
  
  __N__    second cell of parameter stack, r22r23 
  
  __TOS__  first cell of parameter stack, r20r21 
  
  __PSP__  return stack pointer index (psp), r26r27 X
  
  __RSP__  parameter stack pointer index (rsp), r28r29 Y
  
  SP          Not used, reserved for real cpu and interrupts
  
  PC          Not used, reserved for real cpu work :)
  
  ( r2 to r15 are free and can direct accessed with @ and !, it works for Port IOs too. )
  
  (r0, r1, r2, r3, are used in internal mul* and fmul* instructions)
  
  and obey avr-gcc header stats:
   
   __SREG__      Status register at address0x3F
   
   __SP_H__      Stack pointer high byte ataddress 0x3E
   
   __SP_L__      Stack pointer low byte ataddress  0x3D
   
   __tmp_reg__   Register r0, used for temporary storage
   
   __zero_reg__  Register r1, always zero
   
   __PC__        Program counter
   
   __SP__        Stack pointer

  
##  DISCLAIMER:
/*
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

##  References

        All C. H. Ting books.
        
        https://www.forth.com/starting-forth/
        
        http://thinking-forth.sourceforge.net/
        
        http://www2.ene.unb.br/gaborges/disciplinas/psem/desenvolvimentoATmega8.pdf

        https://muforth.nimblemachines.com/threaded-code/

