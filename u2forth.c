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
 * u2forth is based in eForth from Dr. Ting
 * 		using ITC
 *		using interrupts
 *		have a timer in miliseconds 
 *		not use real PC and SP
 *		forth constants in flash
 *		forth variables in sram
 * 		user  constants and variables in sram
 *
 * focus in smaller and smart
 *
 * WARNNING: This C code makes abusive use of goto LABEL:
 * 
 *	virtual cpu does bytecodes, words can be leafs or twigs, only.
 *		leafs only contain bytecodes
 *		twigs only contains address to word 
 *
 *  
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

#define CELL_SIZE      2  
#define RAM_SIZE    1024  
#define RAM_OFFSET    64  
#define ROM_OFFSET  1024   
#define FLASH_SIZE  8192  
#define STACK_SIZE    32  
#define ALLOC FLASH_SIZE/CELL_SIZE

/*
 * typedef unsigned int uint16_t;
 * typedef unsigned char uint8_t;
 */


#include "u2forth.h"

/* timer */

uint32_t  tm ;

/* stacks pointers, parameter and return, in sram */
uint16_t  *psp, *rsp;

/*  parameter stack t, n, m */
uint16_t  t, n, m;

/* index pointer, work */
uint16_t  ip, w;

#define ppush()	psp--; psp[0] = n; n = t;	

#define ppull()	t = n; n = psp[0]; psp++;	

#define CELL sizeof(uint16_t) /* 2 */

#define BYTE sizeof(uint8_t)  /* 1 */

/* sram */
uint8_t c, ram[RAM_SIZE];

/* virtual cpu opcodes */

enum opcodes  {     NOOP=0, THIS, CODE, 
					NEXT, NEST, UNNEST, 
					JUMP, JUMPNZ,
                    RTP, R2P, P2R, 
                    DUPNZ, DUP, DROP, SWAP, OVER, 
                    AND, OR, XOR, INV, CPL, SHL, SHR, 
                    LTZ, GTZ, EQZ, 

					ZERO, ONE, SOT, EOT, LF, FF, CAN, ESC, BS, CR, SPC, CELL
                    };

int main ( void ) {

    ip = 0;

/* leave STACK_SIZE ram for real SP, all stack grows downwards */

    rsp = (uint16_t *) (ram[RAM_SIZE - STACK_SIZE - CELL]);

    psp = (uint16_t *) (ram[RAM_SIZE - STACK_SIZE - STACK_SIZE - CELL]);

CODE:

    c = pgm_read_byte_near( rom[ip] );

    ip += BYTE;

    switch (c) {
/*	bytecodes	*/
        case NOOP : goto CODE;
        case THIS : goto THIS ;
        case NEXT : goto NEXT ;
        case NEST : goto NEST ; 
        case UNNEST : goto UNNEST ; 
		case JUMP : goto JUMP ;
		case JUMPNZ : goto JUMPNZ ;
        case RTP : goto RTP ; 
        case R2P : goto R2P ; 
        case P2R : goto P2R ;
        case DUPNZ : goto DUPNZ ; 
        case DUP : goto DUP ; 
        case DROP : goto DROP ; 
        case SWAP : goto SWAP ; 
        case OVER : goto OVER ;
        case AND: ; goto AND ;
        case OR: goto OR ; 
        case XOR: goto XOR ; 
        case INV: goto INV ;
        case CPL: goto CPL ; 
        case SHL: goto SHL ;
        case SHR: goto SHR ; 
        case LTZ: goto LTZ ;
        case GTZ: goto GTZ ;
        case EQZ: goto EQZ ; 
/*	constants	*/
  		case ZERO: goto ZERO;
  		case ONE: goto ONE;
  		case SOT: goto SOT;
  		case EOT: goto EOT;
  		case LF: goto LF;
  		case FF: goto FF;
  		case CAN: goto CAN;
  		case ESC: goto ESC;
  		case BS: goto BS;
  		case CR: goto CR;
  		case SPC: goto SPC;
  		case CELL: goto CELL;
        default : goto CODE;
    }


TWIG:  /* opcodes */
	goto TWIG;

NEXT:  /*  w = *ip , ip = *w , goto ???; */
    w = pgm_read_word_near(rom[ip]);  
    ip = pgm_read_word_near(rom[w]);
    goto CODE;

NEST: /*  docol or :s , ppush(ip), ip = w, goto NEXT; */
    rsp--; rsp[0] = ip;
    ip = w; 		/* real magic done here */ 
    goto NEXT;

UNNEST: /*  dosem or ;s , ppull(ip), goto NEXT; */
    ip = rsp[0]; rsp++;
    goto NEXT;

THIS:  /*  */
    ppush();
    t = pgm_read_word_near(rom[ip]);  /*  push in psp */
    ip += CELL;
    goto NEXT;

JUMPNZ:  /*  ?branch */
    if (t != 0) goto NEXT;

JUMP:  /*  branch */
    ip = pgm_read_word_near(rom[ip]);
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
    ppull();
    goto CODE;

R2P:  /*  R> */
    ppush();
    t = rsp[0]; rsp++;
    goto CODE;

RTP:  /*  R@ */
    ppush(); 
    t = rsp[0];
    goto CODE;

DROP:  /*  ( W1 -- ) */
    ppull()
    goto CODE;

DUPNZ:  /*  ( w1 -- 0 | w1 w1 ) */
    if (t == 0) goto CODE;

DUP:  /*  ( w1 -- w1 w1 ) */
	ppush();
    goto CODE;

OVER:  /*  ( w1 w2 -- w1 w2 w1 ) */
    m = n; 
CTES:
    ppush();
    t = m;
    goto CODE;

SWAP:  /*  ( w1 w2 -- w2 w1 ) */
	m = n;
    n = t;
	t = m;
    goto CODE;

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

/*
 *
 * ppush a constant to parameter stack 
 *
 */

ZERO:  /*  ASCII null */
    m = 0x00;
    goto CTES;

ONE:
    m = 0x01;
    goto CTES;

SOT:  /*  ASCII Start of text */
    m = 0x02;
    goto CTES;

EOT:  /*  ASCII end of text */
    m = 0x03;
    goto CTES;

LF:  /*  ASCII line feed */
    m = 0x0A;
    goto CTES;

FF:  /*  ASCII form feed */
    m = 0x0C;
    goto CTES;

CAN:  /*  ASCII cancel */
    m = 0x18;
    goto CTES;

ESC:  /*  ASCII escape */
    m = 0x1B;
    goto CTES;

BS:  /*  ASCII backspace */
    m = 0x08;
    goto CTES;

CR:  /*  ASCII cariage return */
    m = 0x0D;
    goto CTES;

SPC:  /*  ASCII space vi  */
    m = 0x20;
    goto CTES;

CELL:  /*  size of CELL, 2 bytes */
    m = 0x02;
    goto CTES;

/* NEVER HERE LAND */

EXIT:
    goto EXIT;

    return (0);

    }



