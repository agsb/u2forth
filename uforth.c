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

#define CELL_SIZE    2 // bytes
#define RAM_SIZE  1024 // bytes
#define RAM_OFFSET  64 // bytes
#define FLASH_SIZE  8192 // bytes
#define STACK_SIZE    32 // bytes

//typedef uint16_t    uint16_t;
//typedef uint8_t     uint8_t;

uint16_t rom[FLASH_SIZE/CELL_SIZE];

uint16_t  *sp, *rp, ip, up;

uint16_t  t, n, w;

uint8_t c, *cp, ram[RAM_SIZE];

void forth (void) {

enum opmodes  {     NOOP, MODE, CODE, THIS, POOL, LOOP };

enum opcodes  {     NOP, NEXT, NEST, UNNEST, CALL, RETURN, EXIT, 
                    RTP, R2P, P2R, 
                    DUPNZ, DUP, DROP, SWAP, OVER, 
                    LOAD,  
                    PUSH, PULL, };

int forth(void) {

    ip = 0;

    up = RAM_OFFSET;

    rp = (uint16_t *) (ram[RAM_SIZE - 2]);

    sp = (uint16_t *) (ram[RAM_SIZE - STACK_SIZE - 2]);

TWIG:

    switch (rom[ip++]) {
        case NOOP : goto TWIG;
        case CODE : goto POOL;
        case THIS : goto THIS;
        default : goto TWIG;
    }

POOL:

    cp = (uint8_t *) (rom + ip);

LEAF:    

    switch (*cp++) {
        case NOOP : goto LEAF;
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
        default : goto LEAF;
    }


    /* sequence of thread codes, must be in this order */

LOOP:

THIS: // doLIT
    sp--; sp[0] = rom[ip];
    ip++;
    goto TWIG;

NEXT: // w = *ip , ip = *w , goto ???;
    w = rom[ip]; // ??? ITC
    ip = rom[w];
    goto TWIG;

NEST: // docol or :s , push(ip), ip = w, goto NEXT;
    rp--; rp[0] = ip;
    ip = w;  // ???? ITC
    goto NEXT;

UNEST: // dosem or ;s , pull(ip), goto NEXT;
    ip = rp[0]; rp++;
    goto NEXT;

JUMPNZ: // ?branch

JUMP: // branch
    ip = rom[ip];
    goto TWIG;    

/*
 * code primitives
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


