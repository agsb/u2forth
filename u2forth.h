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

const uint8_t roulete[] PROGMEM = { 
		 0, 
		32, 15, 19,  4, 21,  2, 25, 17, 34,  6, 27, 13, 36, 11, 30,  8, 23, 10,
		 5, 24, 16, 33,  1, 20, 14, 31,  9, 22, 18, 29,  7, 28, 12, 35,  3, 26
		 };

