/*
 *
 *  u2forth flash forth image
 *
 */

/*
const uint16_t interrupt_table[20] PROGMEM = { 
	 0,  1,  2,  3,  4,  5,  6,  7,  8,  9, 
	10, 11, 12, 13, 14, 15, 16, 17, 18, 19 
	};
*/

const uint8_t rom[4096] PROGMEM = { 0 };

/* why a roullete ? : fun for tests ;

Single-zero wheel european roulette
0,32,15,19,4,21,2,25,17,34,6,27,13,36,11,30,8,23,10,5,24,16,33,1,20,14,31,9,22,18,29,7,28,12,35,3,26
With the numbers  1-10 and 19-28, even numbers are black, and odd numbers are red. 
with the numbers 11-18 and 29-36, even numbers are red, and odd numbers are black.
in order 32 is black, 15 is red, and repeats.

*/

const uint8_t roulette[] PROGMEM = { 
		 0, 
		32, 15, 19,  4, 21,  2, 25, 17, 34,  6, 27, 13, 36, 11, 30,  8, 23, 10,
		 5, 24, 16, 33,  1, 20, 14, 31,  9, 22, 18, 29,  7, 28, 12, 35,  3, 26
		 };

