;	;----------------------------------------------------------------------
;	;
;	;	Memory Model
;	;----------------------------------------------------------------------
;	;----------------------------------------------------------------------
;	; SRAMTOP = 0x000 
;	REGISTERS
;	IO PORTS
;	EXTENDED

;	;----------------------------------------------------------------------
;	; SRAM_START = 0x060
;	; FORTH VARIABLES
;	;----------------------------------------------------------------------
;	TBASE
;	TTIB0
;	TPAD0
;	TIB
;	TIN
;	HLD
;	CSP
;	CONTEXT
;	CURRENT
;	HANDLER
;	SPAN
;	SP0
;	RP0
;	UP
;	CP
;	LAST
;	;----------------------------------------------------------------------
;	;
;	;	USER_RAM_START
;	;	vide STS, LDS, instructions on AVR RISCs, direct address 0x40 to 0xBF
	;	
	USER_RAM_START = 0x0C0	;	192 offset, reserves 96 words for internal
;	;
;	;----------------------------------------------------------------------
;	; grows upwards PT = PT + 1
;	; TERMS_SIZE 0x50	(80 bytes)
;	TIB_TOP = PSP_TOP - STACK_SIZE - TERMS_SIZE
;
;	;----------------------------------------------------------------------
;	; grows downwards SP = SP - 1
;	; STACK_SIZE 0x20
;	PSP_TOP = RSP_TOP - STACK_SIZE
;	RSP_TOP = SPP_TOP - STACK_SIZE
;	SPP_TOP = SRAM_END
;	;----------------------------------------------------------------------
;	;----------------------------------------------------------------------
