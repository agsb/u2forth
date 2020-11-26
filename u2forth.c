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
 * model ATMEGA8
 * virtual 8 bit cpu with 16 bit address
 *
 * u2forth is based in eForth from Dr. Ting
 *
 * focus in smaller and smart
 *
 * WARNNING: This C code makes abusive use of goto LABEL:
 * 
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


uint16_t  *psp, *rsp;

uint16_t  ip, t, n, w;

uint8_t c, ram[RAM_SIZE];

const uint8_t rom[1024] PROGMEM = { 0, 1, 2, 3, 4 };

enum opcodes  {     NOOP, THIS, CODE, 
					NEXT, NEST, UNNEST, 
					JUMP, JUMPNZ,
                    RTP, R2P, P2R, 
                    DUPNZ, DUP, DROP, SWAP, OVER, 
                    AND, OR, XOR, INV, CPL, SHL, SHR, 
                    LTZ, GTZ, EQZ, 
                    };

int forth(void) {

    ip = 0;

    rsp = (uint16_t *) (ram[RAM_SIZE - 2]);

    psp = (uint16_t *) (ram[RAM_SIZE - STACK_SIZE - 2]);


CODE:
    c = pgm_read_byte_near( rom[ip] );
    ip += 1;

    switch (c) {
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
        default : goto CODE;
    }


TWIG:  /* opcodes */
	goto TWIG;

NEXT:  /*  w = *ip , ip = *w , goto ???; */
    w = pgm_read_word_near(rom[ip]);  
    ip = pgm_read_word_near(rom[w]);
    goto CODE;

NEST: /*  docol or :s , push(ip), ip = w, goto NEXT; */
    rsp--; rsp[0] = ip;
    ip = w;   /*  ???? ITC */
    goto NEXT;

UNNEST: /*  dosem or ;s , pull(ip), goto NEXT; */
    ip = rsp[0]; rsp++;
    goto NEXT;

THIS:  /*  */
    psp--; psp[0] = t;
    t = pgm_read_word_near(rom[ip]);  /*  push the address in ram */
    ip += 2;
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
    t = psp[0]; psp++;
    goto CODE;

R2P:  /*  R> */
    psp--; psp[0] = t;
    t = rsp[0]; rsp++;
    goto CODE;

RTP:  /*  R@ */
    psp--; psp[0] = t; 
    t = rsp[0];
    goto CODE;

/*PULL: */
DROP:  /*  ( W1 -- ) */
    t = psp[0]; psp++;
    goto CODE;

DUPNZ:  /*  ( w1 -- 0 | w1 w1 ) */
    if (n != 0) psp--; psp[0] = t;
    goto CODE;

/* PUSH: */
DUP:  /*  ( w1 -- w1 w1 ) */
    psp--; psp[0] = t;
    goto CODE;

OVER:  /*  ( w1 w2 -- w1 w2 w1 ) */
    n = psp[0]; 
    psp--; psp[0] = t;
    t = n;
    goto CODE;

SWAP:  /*  ( w1 w2 -- w2 w1 ) */
    n = t;
    t = psp[0];
    psp[0] = n;
    goto CODE;

AND:  /*  logical and */
    n = psp[0]; psp++;
    t = t & n;
    goto CODE;

OR:  /*  logical or  */
    n = psp[0]; psp++;
    t = t | n;
    goto CODE;

XOR:  /*  logical xor */
    n = psp[0]; psp++;
    t = t ^ n;
    goto CODE;

INV:  /*  invert bits */
    n = psp[0]; psp++;
    t = ~ t;
    goto CODE;

CPL:  /*  two complement */
    n = psp[0]; psp++;
    t = ~ t + 1;
    goto CODE;

SHL:  /*  shift left, multiply by 2 */
    n = psp[0]; psp++;
    t = t << n;
    goto CODE;

SHR:  /*  shift right, divide by 2 */
    n = psp[0]; psp++;
    t = t >> n;
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
 * push a constant to parameter stack 
 *
 */

{

uint8_t c;

enum ctes { ZERO, ONE, TWO, SOT, EOT, DEC, LF, FF, HEX, CAN, ESC, BS, CR, SPC, CELL };

switch(c) {
  case ZERO: goto ZERO;
  case ONE: goto ONE;
  case TWO: goto TWO;
  case SOT: goto SOT;
  case EOT: goto EOT;
  case DEC: goto DEC;
  case LF: goto LF;
  case FF: goto FF;
  case HEX: goto HEX;
  case CAN: goto CAN;
  case ESC: goto ESC;
  case BS: goto BS;
  case CR: goto CR;
  case SPC: goto SPC;
  case CELL: goto CELL;
  default:
    goto CTES;
  }
}

CTES:
    psp--; psp[0] = t;
    t = n;
    goto CODE;

ZERO:  /*  ASCII null */
    n = 0x00;
    goto CTES;

ONE:
    n = 0x01;
    goto CTES;

TWO:
SOT:  /*  ASCII Start of text */
    n = 0x02;
    goto CTES;

EOT:  /*  ASCII end of text */
    n = 0x03;
    goto CTES;

DEC:
LF:  /*  ASCII line feed */
    n = 0x0A;
    goto CTES;

FF:  /*  ASCII form feed */
    n = 0x0C;
    goto CTES;

HEX:  /*  base 16 */
    n = 0x10;
    goto CTES;

CAN:  /*  ASCII cancel */
    n = 0x18;
    goto CTES;

ESC:  /*  ASCII escape */
    n = 0x1B;
    goto CTES;

BS:  /*  ASCII backspace */
    n = 0x08;
    goto CTES;

CR:  /*  ASCII cariage return */
    n = 0x0D;
    goto CTES;

SPC:  /*  ASCII space vi  */
    n = 0x20;
    goto CTES;

CELL:  /*  size of CELL, 2 bytes */
    n = 0x02;
    goto CTES;

/* NEVER HERE LAND */

EXIT:
    goto EXIT;

    return (1);

    }

int main ( int argc, char * argv[] ) {

    return (forth());

}


