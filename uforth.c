#include <stdio.h>
#include <stdlib.h>

#include <avr/io.h>


/*
 * Alvaro Gomes Sobral Barcellos
 *
 * AVR microcontrolers
 *
 * using avr-gcc
 *
 * virtual 8 bit cpu with 16 bit address
 *
 * uforth is based in eForth from Dr. Ting
 *
 * model ATMEGA8
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
#define ROM_OFFSET  1024 // ?????  
#define FLASH_SIZE  8192  
#define STACK_SIZE    32  

//typedef uint16_t    uint16_t;
//typedef uint8_t     uint8_t;

uint16_t rom[FLASH_SIZE/CELL_SIZE];

uint16_t  *sp, *rp, *up;

uint16_t  t, n, w;

uint8_t c, *cp, ram[RAM_SIZE];

void forth (void) {

enum opmodes  {     NOOP, THIS, THAT, CODE, LIST };

enum opcodes  {     NOP, NEXT, NEST, UNNEST, CALL, RETURN, EXIT, 
                    RTP, R2P, P2R, 
                    DUPNZ, DUP, DROP, SWAP, OVER, 
                    LOAD,  
                    PUSH, PULL, };

int forth(void) {

    ip = 0;

    dp = (uint16_t *) (rom[ROM_OFFSET]);
    
    up = (uint16_t *) (ram[RAM_OFFSET]);

    rp = (uint16_t *) (ram[RAM_SIZE - 2]);

    sp = (uint16_t *) (ram[RAM_SIZE - STACK_SIZE - 2]);

_TWIG: // run opcodes


    w = rom[ip++];
    
    switch (w) {
        case NOOP : goto _TWIG; // does nop
        case THIS : goto _THIS; // push a value from ram to parameter stack, constant
        case THAT : goto _THAT; // push a address of a value in ram to parameter stack, variable 
        case CODE : goto _CODE; // runs bytecodes
        case LIST : goto _LIST; // runs 
        default : goto _TWIG;
    }

_CODE:

    cp = (uint8_t *) (rom + ip);

_LEAF: // runs bytecodes   

    switch (*cp++) {
        case NOOP : goto _LEAF;
        case NEXT : ;
        case NEST : ;
        case UNNEST : ;
        case CALL : ;
        case EXIT : ;
        case DUPNZ : ;
        case DUP : ;
        case DROP : ;
        case SWAP : ;
        case OVER : ;
        case RTP : ;
        case R2P : ;
        case P2R : ;
        default : goto _LEAF;
    }


/* sequence of optimizes thread codes, must be in this order */

/*
 * code primitives, most using only íp and sp 
 *
 */

LOOP:

_THAT: //
_THIS: //
    sp--; sp[0] = t;
    t = rom[ip] << 1; // push the address in ram
    if ( w == THAT) t = (uint16_t *) ram[t]; // push the value of the address in ram
    ip++;
    goto _TWIG;

_JUMPNZ: // ?branch
    if (t != 0) goto _TWIG;

_JUMP: // branch
    ip = rom[ip];
    goto _TWIG;    

/*
 * code primitives, most using only íp and rp 
 *
 */

_LIST:

_NEXT: // w = *ip , ip = *w , goto ???;
    w = rom[ip]; // ??? ITC
    ip = rom[w];
    goto _TWIG;

_NEST: // docol or :s , push(ip), ip = w, goto NEXT;
    rp--; rp[0] = ip;
    ip = w;  // ???? ITC
    goto _NEXT;

_UNNEST: // dosem or ;s , pull(ip), goto NEXT;
    ip = rp[0]; rp++;
    goto _NEXT;

NXT: // ???????
    t = (t == 0) ?
    goto NEXT;

/*
 * code primitives, most using only sp and rp 
 *
 */

P2R: // >R
    rp--; rp[0] = t;
    t = sp[0]; sp++;
    goto LOOP;

R2P: // R>
    sp--; sp[0] = t;
    t = rp[0]; rp++;
    goto LOOP;

RTP: // R@
    sp--; sp[0] = t; 
    t = rp[0];
    goto LOOP;

PULL:
DROP: // ( W1 -- )
    t = sp[0]; sp++;
    goto LOOP;

DUPNZ: // ( w1 -- 0 | w1 w1 )
    if (n == 0) goto LOOP;

PUSH:
DUP: // ( w1 -- w1 w1 )
    sp--; sp[0] = t;
    goto LOOP;

OVER: // ( w1 w2 -- w1 w2 w1 )
    n = sp[0]; 
    sp--; sp[0] = t;
    t = n;
    goto LOOP;

SWAP: // ( w1 w2 -- w2 w1 )
    n = t;
    t = sp[0];
    sp[0] = n;
    goto LOOP;

AND: // logical and
    n = sp[0]; sp++;
    t = t & n;
    goto LOOP;

OR: // logical or 
    n = sp[0]; sp++;
    t = t | n;
    goto LOOP;

XOR: // logical xor
    n = sp[0]; sp++;
    t = t ^ n;
    goto LOOP;

INV: // invert bits
    n = sp[0]; sp++;
    t = ~ t;
    goto LOOP;

CPL: // two complement
    n = sp[0]; sp++;
    t = ~ t + 1;
    goto LOOP;

SHL: // shift left, multiply by 2
    n = sp[0]; sp++;
    t = t << n;
    goto LOOP;

SHR: // shift right, divide by 2
    n = sp[0]; sp++;
    t = t >> n;
    goto LOOP;

LTZ: // less than zero
    t = ( t < 0 ) ? -1 : 0;
    goto LOOP;

GTZ: // greater than zero
    t = ( t > 0 ) ? -1 : 0;
    goto LOOP;

EQZ: // equal zero
    t = ( t == 0 ) ? -1 : 0;
    goto LOOP;

EXIT:
    goto LOOP;

/*
 *
 * push a constant to parameter stack 
 *
 */

ZERO: // ASCII null
    n = 0x00;

CTES:
    sp--; sp[0] = t;
    t = n;
    goto LOOP;

ONE:
    n = 0x01;
    goto LOOP;

TWO:
SOT: // ASCII Start of text
    n = 0x02;
    goto CTES;

EOT: // ASCII end of text
    n = 0x03;
    goto CTES;

DEC:
LF: // ASCII line feed
    n = 0x0A;
    goto CTES;

FF: // ASCII form feed
    n = 0x0C;
    goto CTES;

HEX: // ASCII form feed
    n = 0x10;
    goto CTES;

CAN: // ASCII cancel
    n = 0x18;
    goto CTES;

ESC: // ASCII escape
    n = 0x1B;
    goto CTES;

BS: // ASCII backspace
    n = 0x08;
    goto CTES;

CR: // ASCII cariage return
    n = 0x0D;
    goto CTES;

SPC: // ASCII space vi 
    n = 0x20;
    goto CTES;

CELL: // size of CELL, 2 bytes
    n = 0x02;
    goto CTES;

/* NEVER HERE LAND */

    return (1);

    }

int main ( int argc, char * argv[] ) {
    return (forth());
}


