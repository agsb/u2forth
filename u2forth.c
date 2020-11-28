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
 * r00    c
 * r01    reserved always 0, 
 * r16r17 w,
 * r18r19 ip,
 * r20r21 m, 
 * r22r23 n, 
 * r24r25 tos, 
 * r26r27 X index, psp
 * r28r29 Y index, rsp
 * r30r31 Z index  reserved for flash read/write
 * SP     reserved for real cpu and interrups
 *
 * as avr-gcc stats:
 *     __SREG__      Status register at address0x3F
 *  __SP_H__      Stack pointer high byte ataddress 0x3E
 *  __SP_L__      Stack pointer low byte ataddress  0x3D
 *  __tmp_reg__   Register r0, used for temporary storage
 *  __zero_reg__  Register r1, always zero
 *  _PC_          Program counter
 *
 * u2forth is based in eForth from Dr. Ting, except for
 *
 *        1. using ITC, 
 *        2. using interrupts, 
 *        3. have a timer in miliseconds, vide 2 
 *        4. not use real PC and SP, vide 2
 *        5. forth constants in flash
 *        6. forth variables in sram
 *        7. user constants and variables in sram
 *        8. USART
 *        9. I2C
 *       10. NO memory check for ANY function
 *
 * virtual cpu does bytecodes, words can be leafs or twigs, only.
 *        leafs only contain bytecodes
 *        twigs only contains address to word 
 *
 * focus in smaller and smart
 *
 * WARNNING: This C code makes abusive use of goto LABEL:
 *
 * usefull vi expressions
 *
 * 	.s/\([^,]\+\),/    case \1: goto \1 ;^M/g
 *
 * 	.s/\([^,]\+\),/\1:^M    m = ;^M    goto CTES;^M^M/g
 *
 *
 *  TIPS: sort enum over more used opcodes
 */

/*
 * 
 * If clock is internal 8,000,000 MHz and USART at a speed of 9600bps, classic 8 N 1. 
 *
 * The value of UBBR0 should be UBBR0 = ((8,000,000 / 16*9600) -1) = 51 ( Rounded )
 *
 * #define BAUD_PRESCALER 51 
 * 
 */ 

#define RAM_SIZE    1024  
#define RAM_OFFSET    96  
#define ROM_OFFSET  1024   
#define FLASH_SIZE  8192  
#define STACK_SIZE    32  
#define TIB_SIZE	  80
#define PAD_SIZE	 128

/* reserve 32 bytes plus one cell for real STACK */
#define RAM_BOT (RAM_SIZE - STACK_SIZE - TWOBYTE)
#define RSP_TOP	(RAM_BOT)
#define PSP_TOP	(RSP_TOP - STACK_SIZE)

#define TIB_TOP (RAM_OFFSET)
#define PAD0_TOP (TIB_TOP - TIB_SIZE)
#define PAD1_TOP (PAD0_TOP - PAD_SIZE)

#define HEAP	(PAD1_TOP - PAD_SIZE)   	 

/*
 * typedef unsigned int uint16_t;
 * typedef unsigned char uint8_t;
 */

#include "u2forth.h"

#define NO_INIT __attribute__ ((section (".noinit")))

/* timer */

uint32_t  tm ;

/* stacks pointers, parameter and return, in sram */
uint16_t  *psp NO_INIT ;
uint16_t  *rsp NO_INIT ;

/*  parameter stack t, n, m */
uint16_t  t NO_INIT ;
uint16_t  n NO_INIT ;
uint16_t  m NO_INIT ;

/* index pointer, work */
uint16_t  ip NO_INIT ;
uint16_t  w  NO_INIT ;;

/* sram */
uint8_t c NO_INIT;
uint8_t ram[RAM_SIZE] NO_INIT;

#define ppush()    psp--; psp[0] = n; n = t;    

#define ppull()    t = n; n = psp[0]; psp++;    

#define TWOBYTE sizeof(uint16_t) /* 2 */

#define ONEBYTE sizeof(uint8_t)  /* 1 */

#define F_IMMEDIATE (0x80)

#define F_HIDDEN (0x40) 

#define F_RESERVED (0x20)

#define M_SIZEWORD (0x1F)

/* 
 *  from avr-gcc, arduino files 
 *  always 9600,8,N,1 
 *  specs for ATmega8
 * 
 * http://ww1.microchip.com/downloads/en/AppNotes/TB3216-Getting-Started-with-USART-90003216A.pdf
 */

#define F_CPU 8000000
#define BAUD  9600

#define USART_BAUD  (((F_CPU/BAUD)/16UL)-1) /* official 51 gives about 2% error for 9600*/
#define USART_BAUD  (((F_CPU/BAUD)/16UL))   /* overwise 52 gives about 0% error for 9600 */

/* virtual cpu opcodes */

enum opcodes  {     
    NOOP=0, THIS, CODE, 
    NEXT, NEST, UNNEST, 
    JUMP, JUMPNZ,
    RTP, R2P, P2R, 
    DUPNZ, DUP, DROP, SWAP, OVER, ROT, DROP2, DUP2, 
    CSTORE, CFETCH, STORE, FETCH, 
    CMOVE, CCOMP, MOVE, COMP,
    EQZ, LTZ, GTZ, 
    AND, OR, XOR, INV, CPL, SHL, SHR, 
    RXQU, RXCU, TXCU, IOSU,

	CELL, FALSE, TRUE, PAD, TIB, BL,

	PAD0, PAD1, TIB0, PSP0, RSP0,

	PSPP, RSPP, BASE, SPAM, CSP, HOLD, CONTEXT, CURRENT, TOIN, LAST, NP, CP,

    ZERO, ONE, SOT, EOT, LF, FF, DLE, CAN, ESC, BS, CR

    };


void main ( void ) __attribute__((noreturn)); 

void main (void ) {


/* leave STACK_SIZE ram for real SP, for sake, all stack grows downwards */

    rsp = (uint16_t *) &(ram[RSP_TOP]);

    psp = (uint16_t *) &(ram[PSP_TOP]);

    ip = 0;

CODE:

/* bytecodes */

 c = pgm_read_byte_near( &(rom[ip]) );

 ip += ONEBYTE;

 switch (c) {

 case NOOP : goto CODE;

/* interpreter */
 case THIS : goto THIS ;
 case NEXT : goto NEXT ;
 case NEST : goto NEST ; 
 case UNNEST : goto UNNEST ; 
 case JUMP : goto JUMP ;
 case JUMPNZ : goto JUMPNZ ;

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

/* const address */
 case PAD0: goto PAD0 ; 
 case PAD1: goto PAD1 ; 
 case TIB0: goto TIB0 ;
 case PSP0: goto PSP0 ;
 case RSP0: goto RSP0 ;

/* variable address */
 case PSPP: goto PSPP ;
 case RSPP: goto RSPP ;
 case BASE: goto BASE ;
 case SPAM: goto SPAM ;
 case CSP: goto CSP ;
 case HOLD: goto HOLD ;
 case CONTEXT: goto CONTEXT ;
 case CURRENT: goto CURRENT ;
 case TOIN: goto TOIN ;
 case LAST: goto LAST ;
 case NP: goto NP ;
 case CP: goto CP ;

/* usart stuff */
 case RXQU: goto RXQU ;
 case RXCU: goto RXCU ;
 case TXCU: goto TXCU ;
 case IOSU: goto IOSU ;

/* standart constants */
 case CELL: goto CELL ;
 case FALSE: goto FALSE ;
 case TRUE: goto TRUE ;
 case PAD: goto PAD ;
 case TIB: goto TIB ;
 case BL: goto BL ;

/* constants */
 case ZERO: goto ZERO;
 case ONE: goto ONE;
 case SOT: goto SOT;
 case EOT: goto EOT;
 case LF: goto LF;
 case FF: goto FF;
 case CAN: goto CAN;
 case DLE: goto DLE;
 case ESC: goto ESC;
 case BS: goto BS;
 case CR: goto CR;

/* just init or panic */
  default : goto CODE;
  }

IOSU:
    /* set baud rate */
    UBRRH = ( USART_BAUD ) >> 8;
    UBRRL = ( USART_BAUD );     
    /* enable Rx & Tx */
    UCSRB = (1<<RXEN)|(1<<TXEN);  
    /* config USART frame 8N1 */
    UCSRC = (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0);  
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

TWIG:  /* opcodes */
    goto TWIG;

NEXT:  /*  w = *ip , ip = *w , goto ???; */
    w = pgm_read_word_near(&(rom[ip]));  
    ip = pgm_read_word_near(&(rom[w]));
    goto CODE;

NEST: /*  docol or :s , ppush(ip), ip = w, goto NEXT; */
    rsp--; rsp[0] = ip;
    ip = w;         /* real magic done here */ 
    goto NEXT;

UNNEST: /*  dosem or ;s , ppull(ip), goto NEXT; */
    ip = rsp[0]; rsp++;
    goto NEXT;

THIS:  /* push next literal word on dictionary into psp */
    ppush();
    t = pgm_read_word_near(&(rom[ip]));  /*  push in psp */
    ip += CELL;
    goto NEXT;

JUMPNZ:  /*  ?branch */
    if (t != 0) goto NEXT;

JUMP:  /*  branch */
    ip = pgm_read_word_near(&(rom[ip]));
    goto NEXT;    

/*
 *
 * opcode primitives,
 *
 */

LEAF:  /*  bytecodes    */
    goto LEAF;

P2R:  /*  >R */
    rsp--; rsp[0] = t;
    goto DROP;

R2P:  /*  R> */
    ppush();
    t = rsp[0]; rsp++;
    goto CODE;

RTP:  /*  R@ */
    ppush(); 
    t = rsp[0];
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
    m = n; 

CTES:
    ppush();
    t = m;
    goto CODE;

VARS:
	m = (uint16_t *)(&ram[m]);
	goto CTES;

SWAP:  /*  ( w1 w2 -- w2 w1 ) */
    m = n;
    n = t;
    goto CTES;

ROT:	/*	( w1 w2 w3 -- w2 w3 w1 ) */
    m = psp[0];
	psp[0] = n;
	n = t;
	t = m;
	goto CODE;

DROP2:
    t = psp[0]; psp++;
    n = psp[0]; psp++;
    goto CODE;

DUP2:
    psp--; psp[0] = n;
    psp--; psp[0] = t;
    goto CODE;

SWAP2:
	goto CODE;

CFETCH: /* C@ */
    t = (uint16_t) ram[t];
    goto CODE;

FETCH: /* @ */
    t = ((uint16_t *) (&ram[t]))[0];
    goto CODE;

CSTORE: /* C! */
    ram[t] = (uint8_t) n;
    goto DROP2;

STORE: /* ! */
    ((uint16_t *) (&ram[t]))[0] = n;
    goto DROP2;
	
CMOVE: /* ( w2 w1 n -- ) move bytes */
    m = psp[0]; 
    psp++;
    while (t) {
        ram[n] = ram[m];
        n += 1;
        m += 1;
        t -= 1;
        }
    goto DROP2;

CCOMP: /* ( w2 w1 n -- 0 | t ) compare bytes, zero if all equal, t where differ  */
    m = psp[0];
    psp++;
    while (t) {
        if (ram[n] != ram[m]) break;
        n += 1;
        m += 1;
        t -= 1;
        }
    m = t;
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

/* constants */

CELL:
	m = TWOBYTE;
	goto CTES;

FALSE:
	m = 0 ; 
	goto CTES;

TRUE:
	m = -1 ;
	goto CTES;
	
PAD:
	goto CTES;

TIB:
	goto CTES;

BL:
	m = 32 ;
	goto CTES;

/*
 *
 * ppush a fixed address to parameter stack 
 *
 */

PAD0:
	m = PAD0_TOP; 
	goto CTES;

PAD1:
	m = PAD1_TOP;
	goto CTES;

TIB0: 
	m = TIB_TOP;
	goto CTES;

RSP0:
	m = RSP_TOP;
	goto CTES;

PSP0:
	m = PSP_TOP;
	goto CTES;

/*
*
* push address of forth variables in sram, 
* offsets of ram, or indexes, 
* need work to emule .DW in asm
*
*/
	
PSPP:
    m = 2;
    goto VARS;

RSPP:
    m = 4;
    goto VARS;

BASE:
    m = 6;
    goto VARS;

SPAM:
    m = 8;
    goto VARS;

HOLD:
    m = 10;
    goto VARS;

CONTEXT:
    m = 12;
    goto VARS;

CURRENT:
    m = 14;
    goto VARS;

TOIN:
    m = 16;
    goto VARS;

LAST:
    m = 18;
    goto VARS;

NP:
    m = 20;
    goto VARS;

CP:
    m = 22;
    goto VARS;

CSP:
    m = 24;
    goto VARS;

/*
 *
 * ppush a constant to parameter stack 
 *
 */

ZERO: /* 0  ASCII null */
    m = 0x00;
    goto CTES;

ONE:  /* 1 ASCII start of heading */
    m = 0x01;
    goto CTES;

SOT:  /* 2 ASCII Start of text */
    m = 0x02;
    goto CTES;

EOT:  /* 3 ASCII end of text */
    m = 0x03;
    goto CTES;

BS:   /* 8 ASCII backspace */
    m = 0x08;
    goto CTES;

LF:   /* 10 ASCII line feed */
    m = 0x0A;
    goto CTES;

FF:   /* 12  ASCII form feed */
    m = 0x0C;
    goto CTES;

CR:   /* 13 ASCII cariage return */
    m = 0x0D;
    goto CTES;

DLE:  /* 16 ASCII data link escape */
    m = 0x10;
    goto CTES;

CAN:  /* 24 ASCII cancel */
    m = 0x18;
    goto CTES;

ESC:  /* 27 ASCII escape */
    m = 0x1B;
    goto CTES;

/* NEVER HERE LAND */

EXIT:
    goto EXIT;

/*

  is void

  return (0);

*/

    }



