
/* 
 *  from avr-gcc, arduino files 
 *  always 9600,8,N,1 
 *  specs for ATmega8
 */

   #define F_CPU 8000000
   #define BAUD  9600

/* setup 9600,8,N,1 */ 
static void usart_init ( void )
   {
    /* set baud rate */
      UBRRH = (((F_CPU/BAUD)/16)-1)>>8;
      UBRRL = (((F_CPU/BAUD)/16)-1);     
    /* enable Rx & Tx */
      UCSRB = (1<<RXEN)|(1<<TXEN);  
    /* config USART 8N1 */
      UCSRC = (1<<URSEL)|(1<<UCSZ1)|(1<<UCSZ0);  
   }

/* Wait and transmit */ 
static void usart_send ( uint8_t uc ){
	while((UCSRA & (1<<UDRE) ) == 0);
	UDR = uc;
    }

/* Wait and receive */ 
static uint8_t usart_recv ( void ) {
	while((UCSRA & (1<<RXC) ) == 0);
	return UDR;
	}

