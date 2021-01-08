	.file	"usart.c"
__SP_H__ = 0x3e
__SP_L__ = 0x3d
__SREG__ = 0x3f
__tmp_reg__ = 0
__zero_reg__ = 1
	.section	.text.startup,"ax",@progbits
.global	main
	.type	main, @function
main:
/* prologue: function */
/* frame size = 0 */
/* stack size = 0 */
.L__stack_usage = 0
	out 0x20,__zero_reg__
	ldi r24,lo8(52)
	out 0x9,r24
	in r24,0xa
	ori r24,lo8(24)
	out 0xa,r24
	ldi r24,lo8(-114)
	out 0x20,r24
	in r24,0x20
	ori r24,lo8(64)
	out 0x20,r24
.L2:
	sbis 0xb,7
	rjmp .L2
	in r24,0xc
.L3:
	sbis 0xb,5
	rjmp .L3
	out 0xc,r24
	rjmp .L2
	.size	main, .-main
	.ident	"GCC: (GNU) 5.4.0"
