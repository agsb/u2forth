
/*
vide https://github.com/arduino/ArduinoCore-avr/blob/master/cores/arduino/wiring.c
*/

#include <avr/interrupt.h>
#include <avr/wdt.h>
#include <util/atomic.h>

// Calculate the value needed for 
// the CTC match value in OCR1A.

#define CTC_MATCH_OVERFLOW ((F_CPU / 1000) / 8) 

volatile unsigned long timer1_millis;
 
/* Timer1 clock Interrupt Service Routine */
ISR (TIMER1_COMPA_vect)
{
    timer1_millis++;
	reti();
}

/* Watchdog Timer Interrupt Service Routine */
ISR (WDT_vect)
{
	sample = TCNT1L; // Ignore higher bits
	sample_waiting = true;
	reti();
}

void interrupts_init (void) {

/* disable enable global interrupts */

	uint8_t oldSREG = SREG;

	cli();

{
/*
 * forced initialization
 * of unnecessary interrupts
 */
    MCUCR = 0x00;
    EICRA = 0x00;
    EIMSK = 0x00;
    TIMSK0 = 0x00;
    TIMSK1 = 0x00;
    TIMSK2 = 0x00;
    PCMSK0 = 0x00;
    PCMSK1 = 0x00;
    PCMSK2 = 0x00;
    PCICR = 0x00;
    PRR = 0x00;
}

/* clocks */
{
  /* CTC mode, Clock/8 */
  TCCR1B |= (1 << WGM12) | (1 << CS11);
 
  /* load bytes into the output compare */
  OCR1AH = (CTC_MATCH_OVERFLOW >> 8);
  OCR1AL = CTC_MATCH_OVERFLOW;
 
  /* Enable the compare match interrupt */
  TIMSK1 |= (1 << OCIE1A);
}

/* watchdog */
{
  MCUSR = 0;
  
  /* Start timed sequence */
  WDTCSR |= _BV(WDCE) | _BV(WDE);

  /* Put WDT into interrupt mode */
  /* Set shortest prescaler(time-out) value = 2048 cycles (~16 ms) */
  WDTCSR = _BV(WDIE);

/* enable enable global interrupts */

  SEG = oldSREG;

  sei();
  

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

