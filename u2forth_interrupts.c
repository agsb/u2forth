/*

vide https://github.com/arduino/ArduinoCore-avr/blob/master/cores/arduino/wiring.c

#include <avr/interrupt.h>
#include <util/atomic.h>

// Calculate the value needed for 
// the CTC match value in OCR1A.

#define CTC_MATCH_OVERFLOW ((F_CPU / 1000) / 8) 

volatile unsigned long timer1_millis;
 
ISR (TIMER1_COMPA_vect)
{
    timer1_millis++;
	reti();
}

unsigned long millis ()
{
    unsigned long mil;

	uint8_t oldSREG = SREG;

	cli();

	millis_return = timer1_millis;
	
	SEG = oldSREG;

	sei();
 
    return (mil);
}

void interrupt_timer1_init (void) {
    // CTC mode, Clock/8
    TCCR1B |= (1 << WGM12) | (1 << CS11);
 
    // Load the high byte, then the low byte
    // into the output compare
    OCR1AH = (CTC_MATCH_OVERFLOW >> 8);
    OCR1AL = CTC_MATCH_OVERFLOW;
 
    // Enable the compare match interrupt
    TIMSK1 |= (1 << OCIE1A);
    
    // Now enable global interrupts
    sei();
}

*/
