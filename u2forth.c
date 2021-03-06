/*
 *  DISCLAIMER:
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

#include <stdio.h>
#include <stdlib.h>

#include <avr/io.h>
#include <avr/pgmspace.h>

/*
 * u2forth
 *
 * Alvaro Gomes Sobral Barcellos
 *
 * AVR microcontrolers
 *
 * using avr-gcc -mmcu=atmega8
 *
 * just to using avr-gcc to make a good startup for asm
 *
 * model ATMEGA8
 *
 * virtual 8 bit cpu with 16 bit address
 *
 * most risc cpus have at least 32 registers, 
 *
 * as avr-gcc stats:
 *     __SREG__      Status register at address0x3F
 *  __SP_H__      Stack pointer high byte ataddress 0x3E
 *  __SP_L__      Stack pointer low byte ataddress  0x3D
 *  __tmp_reg__   Register r0, used for temporary storage
 *  __zero_reg__  Register r1, always zero
 *  _PC_          Program counter
 *
 * focus in smaller and smart
 *
 * WARNNING: This C code makes abusive use of goto LABEL:
 *
 * usefull vi expressions
 *
 *     .s/\([^,]\+\),/    case \1: goto \1 ;^M/g
 *
 *     .s/\([^,]\+\),/\1:^M    w = ;^M    goto CTES;^M^M/g
 *
 *
 *  TODO! sort enum over more used opcodes
 */


#define RAM_SIZE    1024  
#define RAM_OFFSET    96  
#define ROM_OFFSET  1024   
#define FLASH_SIZE  8192  
#define STACK_SIZE    32  
#define TIB_SIZE      80
#define PAD_SIZE     128

/*     leave STACK_SIZE ram for real SP, 
    all stack grows downwards 
    reserve 32 bytes plus one cell for real STACK 
*/

#define RAM_BOT (RAM_SIZE - STACK_SIZE - V_TWOBYTE)
#define RSP_TOP (RAM_BOT)
#define PSP_TOP (RSP_TOP - STACK_SIZE)

#define TIB_TOP (RAM_OFFSET)
#define PAD0_TOP (TIB_TOP - TIB_SIZE)
#define PAD1_TOP (PAD0_TOP - PAD_SIZE)

#define HEAP    (PAD1_TOP - PAD_SIZE)        

/*
 * typedef unsigned int uint16_t;
 * typedef unsigned char uint8_t;
 */

#include "u2forth.h"

/* from avr-gcc arquives */

#define NO_INIT __attribute__ ((section (".noinit")))

/* index offsets, for parameter stack and return stack, in sram */

uint16_t  psp NO_INIT ;
uint16_t  rsp NO_INIT ;

/*  parameter stack t, n, w */
uint16_t  t NO_INIT ;
uint16_t  n NO_INIT ;
uint16_t  w NO_INIT ;;

/* index pointer, work */
uint16_t  ip NO_INIT ;

/* sram */
uint8_t c NO_INIT;

uint8_t ram[RAM_SIZE] NO_INIT;

/* maybe must choose better names */

#define ROMB(X)   pgm_read_byte_near(&(rom[X]))

#define ROMW(X)   pgm_read_word_near(&(rom[X]))

#define RAMW(X)   *((uint16_t *)(ram + (X)))

#define ppush()   psp--; RAMW(psp) = n; n = t;    

#define ppull()   t = n; n = RAMW(psp); psp++;    

#define F_IMMEDIATE (0x80)

#define F_HIDDEN (0x40) 

#define F_RESERVED (0x20)

#define M_SIZEWORD (0x1F)

#define V_FALSE (0x00)

#define V_TRUE (0xFF)

#define V_TWOBYTE sizeof(uint16_t) /* 2 */

#define V_ONEBYTE sizeof(uint8_t)  /* 1 */

/* 
 *  from avr-gcc, arduino files 
 *  always 9600,8,N,1 
 *  specs for ATmega8
 * 
 * http://ww1.microchip.com/downloads/en/AppNotes/TB3216-Getting-Started-with-USART-90003216A.pdf
 * std: #define USART_BAUD  (((F_CPU/BAUD)/16UL)-1) 
 *  official 51 gives about 2% error for 9600
 */

#ifndef F_CPU
#define F_CPU 8000000
#endif

#define BAUD  9600
#define USART_BAUD  (((F_CPU/BAUD)/16UL))   /* overwise 52 gives about 0% error for 9600 */

/* virtual cpu opcodes */

enum opcodes  {     

    NOOP=0, CODE,

    /* NEXT, NEST, UNNEST, */
    
    EXEC, EXIT,

    JUMP, JUMPNZ, 
    
    THIS, COMMA,

    RTP, R2P, P2R, 

    RPG, RPP, SPG, SPP,
    
    DUPNZ, DUP, DROP, SWAP, OVER, ROT, 

	DROP2, DUP2, 

    CSTORE, CFETCH, STORE, FETCH, 

    CMOVE, CCOMP, MOVE, COMP,

    EQZ, LTZ, GTZ, 

    AND, OR, XOR, INV, CPL, SHL, SHR, 

	RND, HSH,  
   
    RXQU, RXCU, TXCU, IOSU,

    CELL, FALSE, TRUE, 

    BL, BS, LF, CR, ESC, 

    PAD0, PAD1, TIB0, PSP0, RSP0,

    PSPP, RSPP, BASE, SPAM, HOLD, 

    STATE, CONTEXT, CURRENT, CURSOR, 

    LAST, DP, UP, LASTF, DPF,

    ZERO, ONE, SOT, EOT, 

    COLD, ABORT, QUIT, BYE

    };


void main ( void ) __attribute__((noreturn)); 


void main (void ) {

BYE:
    /* just do a cold boot */

COLD:
    
    ip = 0;

ABORT:
    psp = PSP_TOP;

QUIT:
    rsp = RSP_TOP;

/* 
    must:
     set state to 0 to interpret 
     set tibN offset to 0 start of terminal buffer 
     set rdyN offset to 0 start of search words at TIB
     
*/
    
    goto CODE;

TWIG:  /* opcodes */
    goto TWIG;

EXIT: /*  as a return */
    ip = RAMW(rsp); rsp++;

EXEC: /* as a call  */
    w = ROMW(ip);  
    ip += V_TWOBYTE;
    rsp--; RAMW(rsp) = ip;
    ip = w;         /* real magic done here */ 

CODE:

/* bytecodes */

    c = ROMB(ip);

     ip += V_ONEBYTE;

uCV: /* virtual processor */

     switch (c) {

        case NOOP : goto CODE;
        case CODE : goto CODE;

        case EXIT:    goto EXIT ;
        case EXEC: goto EXEC ;
        case JUMP : goto JUMP ;
        case JUMPNZ : goto JUMPNZ ;

        case THIS : goto THIS ;
        case COMMA : goto COMMA ;

/* using both stacks */
        case RTP : goto RTP ; 
        case R2P : goto R2P ; 
        case P2R : goto P2R ;

/* using parameter stack */
        case DUPNZ : goto DUPNZ ; 
        case DUP : goto DUP ; 
        case DROP : goto DROP ; 
        case SWAP : goto SWAP ; 
        case OVER : goto OVER ;
        case ROT : goto ROT ;
        case DROP2 : goto DROP2 ;
        case DUP2 : goto DUP2 ;

/* moving */
        case STORE: goto STORE ;
        case FETCH: goto FETCH ;
        case CSTORE: goto CSTORE ;
        case CFETCH: goto CFETCH ;
        case CMOVE: goto CMOVE ; 
        case CCOMP: goto CCOMP ; 
        case MOVE: goto MOVE ; 
        case COMP: goto COMP ; 

/* logical */
        case EQZ: goto EQZ ;
        case LTZ: goto LTZ ;
        case GTZ: goto GTZ ;
        case AND: goto AND ;
        case OR: goto OR ; 
        case XOR: goto XOR ; 
        case INV: goto INV ;
        case CPL: goto CPL ; 
        case SHL: goto SHL ;
        case SHR: goto SHR ; 

        case RND: goto RND ;
        case HSH: goto HSH ;

/* const address */
        case PAD0: goto PAD0 ; 
        case PAD1: goto PAD1 ; 
        case TIB0: goto TIB0 ;
        case PSP0: goto PSP0 ;
        case RSP0: goto RSP0 ;

    case RPG: goto     RPG ;
    case RPP: goto  RPP ;
    case SPG: goto  SPG ;
    case SPP: goto  SPP ;

/* variable address */
        case PSPP: goto PSPP ;
        case RSPP: goto RSPP ;
        case BASE: goto BASE ;
        case SPAM: goto SPAM ;
        case HOLD: goto HOLD ;
        case STATE: goto STATE ;
        case CONTEXT: goto CONTEXT ;
        case CURRENT: goto CURRENT ;
        case CURSOR: goto CURSOR ;
        case LAST: goto LAST ;
        case DP: goto DP ;
        case UP: goto UP ;

/* usart stuff */
        case RXQU: goto RXQU ;
        case RXCU: goto RXCU ;
        case TXCU: goto TXCU ;
        case IOSU: goto IOSU ;

/* standart constants */
        case CELL: goto CELL ;
        case FALSE: goto FALSE ;
        case TRUE: goto TRUE ;

/* ascii constants */ 
        case BL: goto BL ;
        case BS: goto BS;
        case LF: goto LF;
        case ESC: goto ESC;
        case CR: goto CR;

/* constants */
        case ZERO: goto ZERO;
        case ONE: goto ONE;
        case SOT: goto SOT;
        case EOT: goto EOT;

/* just init */
        case COLD: goto COLD ;
        case ABORT: goto ABORT ;
        case QUIT: goto QUIT ;
        case BYE: goto BYE ;

/* just panic */
        default : goto CODE;
   }

IOSU:
    /* set baud rate */
    UBRRH = ( USART_BAUD ) >> 8;
    UBRRL = ( USART_BAUD );     
    /* enable Rx & Tx */
    UCSRB = (1<<RXEN)|(1<<TXEN);  
    /* config USART frame 8N1 */
    UCSRC = (1<<URSEL)|(1<<USBS)|(1<<UCSZ1)|(1<<UCSZ0);  
    /* config USART mode asynchonous */
    UCSRC |= (1<<UMSEL); 
    goto CODE;

TXCU:
    /* wait and transmit */
    while((UCSRA & (1<<UDRE) ) == 0);
    UDR = t & 0x00FF;
    goto DROP;

RXCU:
    /* wait and receive */
    ppush();
    while((UCSRA & (1<<RXC) ) == 0);
    t = UDR;
    goto CODE;
    
RXQU:
    /* test if available */
    ppush();
    t = ( UCSRA & (1<<RXC) ) ;
    goto CODE;

/*
 *
 * opcode primitives,
 *
 */

JUMPNZ:  /*  ?branch */
    if (t != 0) goto CODE;

JUMP:  /*  branch */
    ip = ROMW(ip);
    goto CODE;    

THIS: /* push next literal word on dictionary into psp */
    ppush();
    t = ROMW(ip);  /*  push in psp */
    ip += V_TWOBYTE;
    goto CODE;

COMMA: /* ERROR! dictionary is in ram! */
    w = RAMW(w);
    RAMW(w) = t ;
    ppull();
    goto CODE;

VARS:
    w = RAMW(ip);
    ip += V_TWOBYTE;
    goto CTES;

P2R:  /*  >R */
    rsp--; RAMW(rsp) = t;
    goto DROP;

R2P:  /*  R> */
    ppush();
    t = RAMW(rsp); rsp++;
    goto CODE;

RTP:  /*  R@ */
    ppush(); 
    t = RAMW(rsp);
    goto CODE;

RPG:
    w = 0;
    goto CODE;

RPP:
    w = 0;
    goto CODE;

SPG:
    w = 0;
    goto CODE;

SPP:
    w = 0;
    goto CODE;

DUPNZ:  /*  ( w1 -- 0 | w1 w1 ) */
    if (t == 0) goto CODE;

DUP:  /*  ( w1 -- w1 w1 ) */
    ppush();
    goto CODE;

DROP:  /*  ( W1 -- ) */
    ppull()
    goto CODE;

OVER:  /*  ( w1 w2 -- w1 w2 w1 ) */
    w = n; 

CTES:
    ppush();
    t = w;
    goto CODE;

SWAP:  /*  ( w1 w2 -- w2 w1 ) */
    w = n;
    goto CTES;

ROT:    /*    ( w1 w2 w3 -- w2 w3 w1 ) */
    w = RAMW(psp);
    RAMW(psp) = n;
    n = t;
    t = w;
    goto CODE;

DROP2:
    t = RAMW(psp); psp++;
    n = RAMW(psp); psp++;
    goto CODE;

DUP2:
    psp--; RAMW(psp) = n;
    psp--; RAMW(psp) = t;
    goto CODE;

CFETCH: /* C@ */
    t = (uint16_t) ram[t];
    goto CODE;

FETCH: /* @ */
    t = RAMW(t);
    goto CODE;

CSTORE: /* C! */
    ram[t] = (uint8_t) n;
    goto DROP2;

STORE: /* ! */
    RAMW(t)= n;
    goto DROP2;
    
CMOVE: /* ( w1 w2 n -- ) move bytes */
    w = RAMW(psp); 
    psp++;
    while (t) {
        ram[n] = ram[w];
        n += 1;
        w += 1;
        t -= 1;
        }
    goto DROP2;

CCOMP: /* ( w1 w2 n -- 0 | t ) compare bytes, zero if all equal, t where differ  */
    w = RAMW(psp);
    psp++;
    while (t) {
        if (ram[n] != ram[w]) break;
        n += 1;
        w += 1;
        t -= 1;
        }
    w = t;
    ppull();
    goto CTES;

MOVE: /* ( w2 w1 n -- ) move sequencial words */
    t = t << 1;
    goto CMOVE;

COMP: /* ( w2 w1 n -- ) compare sequencial words */
    t = t << 1;
    goto CCOMP;

AND:  /*  logical and */
    n = t & n;
    goto DROP;

OR:  /*  logical or  */
    n = t | n;
    goto DROP;

XOR:  /*  logical xor */
    n = t ^ n;
    goto DROP;

SHL:  /*  shift left, multiply by 2 */
    n = t << n;
    goto DROP;

SHR:  /*  shift right, divide by 2 */
    n = t >> n;
    goto DROP;

INV:  /*  invert bits */
    t = ~ t;
    goto CODE;

CPL:  /*  two complement */
    t = ~ t + 1;
    goto CODE;

LTZ:  /*  less than zero */
    t = ( t < 0 ) ? -1 : 0;
    goto CODE;

GTZ:  /*  greater than zero */
    t = ( t > 0 ) ? -1 : 0;
    goto CODE;

EQZ:  /*  equal zero */
    t = ( t == 0 ) ? -1 : 0;
    goto CODE;

RND: /* shiftxor pseudo random */
    w = t;
    w ^= w >> 13;
    w ^= w << 7;
    w ^= w >> 11;
    w ^= w << 5;
    t = w;
    goto CODE;

HSH: /* 1 byte hash ????  */
    w = 1;
    while (w) {
        w--;
        }
    goto CODE;   

/* constants */

CELL:
    w = V_TWOBYTE;
    goto CTES;

FALSE:
    w = 0 ; 
    goto CTES;

TRUE:
    w = -1 ;
    goto CTES;
    
BL:    /* 32 ASCII space */
    w = 0x20 ;
    goto CTES;

BS:   /* 8 ASCII backspace */
    w = 0x08;
    goto CTES;

LF:   /* 10 ASCII line feed */
    w = 0x0A;
    goto CTES;

CR:   /* 13 ASCII cariage return */
    w = 0x0D;
    goto CTES;

ESC:  /* 27 ASCII escape */
    w = 0x1B;
    goto CTES;

/*
 *
 * ppush a fixed address to parameter stack 
 *
 */

PAD0:
    w = PAD0_TOP; 
    goto CTES;

PAD1:
    w = PAD1_TOP;
    goto CTES;

TIB0: 
    w = TIB_TOP;
    goto CTES;

RSP0:
    w = RSP_TOP;
    goto CTES;

PSP0:
    w = PSP_TOP;
    goto CTES;

/*
*    extras
*/
    
PSPP:
    w = 2;
    goto VARS;

RSPP:
    w = 4;
    goto VARS;

BASE:
    w = 6;
    goto VARS;

SPAM:
    w = 8;
    goto VARS;

HOLD:
    w = 10;
    goto VARS;

STATE:
    w = 12;
    goto VARS;

CONTEXT:
    w = 14;
    goto VARS;

CURRENT:
    w = 16;
    goto VARS;

CURSOR:
    w = 18;
    goto VARS;

LAST:
    w = 20;
    goto VARS;

DP:
    w = 22;
    goto VARS;

UP:
    w = 24;
    goto VARS;

/*
 *
 * ppush a constant to parameter stack 
 *
 */

ZERO: /* 0  ASCII null */
    w = 0x00;
    goto CTES;

ONE:  /* 1 ASCII start of heading */
    w = 0x01;
    goto CTES;

SOT:  /* 2 ASCII Start of text */
    w = 0x02;
    goto CTES;

EOT:  /* 3 ASCII end of text */
    w = 0x03;
    goto CTES;

/* NEVER HERE LAND */

    goto BYE;

/*

  is void

  return (0);

*/

    }



