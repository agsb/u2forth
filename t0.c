#include <stdio.h>
#include <stdlib.h>

#include <avr/io.h>
#include <avr/pgmspace.h>


/*
 *
 * Alvaro Gomes Sobral Barcellos
 *
 * AVR microcontrolers
 *
 * using avr-gcc -mmcu=atmega8
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

const uint8_t rom[1024] PROGMEM = { 0, 1, 2, 3, 255, 256, 257, 258 };

static uint16_t psp, rsp, tos, w, n, ip;

int main ( void ) {

	n = pgm_read_byte_near(rom[2]);

	w = n;

	n = pgm_read_word_near(rom[1]);

	w = w + n;

    return ( w );

}


