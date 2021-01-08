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
 *  from avr-gcc, arduino files 
 *  always 9600,8,N,1 
 *  specs for ATmega8
 * 
 * http://ww1.microchip.com/downloads/en/AppNotes/TB3216-Getting-Started-with-USART-90003216A.pdf
 * std: #define USART_BAUD  (((F_CPU/BAUD)/16UL)-1) 
 *  official 51 gives about 2% error for 9600
 */

#define F_CPU 8000000
#define BAUD  9600
#define USART_BAUD  (((F_CPU/BAUD)/16UL))   /* overwise 52 gives about 0% error for 9600 */

int main (void ) {

	int w; 

/*
Special Note for ATmega8:

The C register (UCRSC) on the ATmega8 contains URSEL (USART Select) bit.  
In order to write data to the UBRRH register 
the URSEL bit needs to be LOW(0), and
in order to write data to to register C (UCRSC) 
you need to set this bit (URSEL) to HIGH(1).  

https://sites.google.com/site/qeewiki/books/avr-guide/usart
*/

    /* set baud rate */
    UBRRH = ( USART_BAUD ) >> 8;
    UBRRL = ( USART_BAUD );     
	/* enable Rx & Tx */
    UCSRB |= (1<<RXEN)|(1<<TXEN);  
    /* config USART frame 8N1 */
    UCSRC = (1<<URSEL)|(1<<USBS)|(1<<UCSZ1)|(1<<UCSZ0);  
	/* config USART mode asynchonous */
    UCSRC |= (1<<UMSEL); 

while (1) {

    /* wait and receive */
    while((UCSRA & (1<<RXC) ) == 0);
    w = UDR;

    /* wait and transmit */
    while((UCSRA & (1<<UDRE) ) == 0);
    UDR = (unsigned char) w;

	}

	return (w);

  }
