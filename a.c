#include <stdio.h>
#include <stdlib.h>

#include <avr/io.h>


/* 
 * AVR microcontrolers
 *
 * using avr-gcc
 *
 * virtual 8 bit cpu with 16 bit address
 *
 * uforth is based in eForth from Dr. Ting
 *
 * but no pointers just offsets for stacks
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
                    DUPNZ, DUP, DROP, SWAP, OVER, 
                    RTP, R2P, P2R, 
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
        case THIS : goto LOOP;
        default : goto TWIG;
        }

POOL:

    cp = (uint8_t *) &(rom + ip);

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

NXT:

_EXIT:

THIS: // doLIT
    sp--; sp[0] = rom[ip];
    ip++;
    goto POOL;

NEXT: // w = *ip , ip = *w , goto ???;
    w = rom[ip];
    ip = rom[w];
    goto POOL;

NEST: // docol or :s , push(ip), ip = w, goto NEXT;
    rp--; rp[0] = ip;
    ip = w;  // ????
    goto NEXT;
    
UNEST: // dosem or ;s , pull(ip), goto NEXT;
    ip = rp[0]; rp++;
    goto NEXT;

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
    if (t == 0) goto LOOP;

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

goto:
    goto LOOP;

EXIT:
    goto LOOP;

/* NEVER HERE LAND */

    }

int main ( int argc, char * argv[] ) {
    return (forth());
}


