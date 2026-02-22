; -----------------------------------------------------------------------------
; Math example for the Mench Reloaded SBC.
; The 65816 lacks opcodes for multiplication and division. The integer math
; library provides them and other useful mathematical functions.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "math16.inc"
.include "print.inc"

; Main entry point for the program.
PUBLIC main
	ON16MEM
	ON16X
	printcr			; start output on a newline
	println enter

	print abs1
	lda #$fa97		; -1,385 in hex
	jsr abs16
	printcdec
	printcr

	print div1
	lda #19
	ldx #367
	jsr udiv16
	printcudec
	print divr
	txa
	printcudec
	printcr

	print div2
	lda #17
	ldx #48317
	jsr udiv16
	printcudec
	print divr
	txa
	printcudec
	printcr

	print div3
	lda #0
	ldx #48317
	jsr udiv16
	printcudec
	print divr
	txa
	printcudec
	printcr

	print max1
	lda #337
	ldx #171
	jsr umax16
	printcudec
	printcr

	print min1
	lda #337
	ldx #171
	jsr umin16
	printcudec
	printcr

	print mul1
	lda #36
	ldx #19
	jsr umult16
	printcudec
	printcr

	print mul2
	lda #337
	ldx #171
	jsr umult16
	printcudec
	printcr

	print sqrt1
	lda #537
	jsr usqrt16
	printcudec
	printcr

	print sqrt2
	lda #1919
	jsr usqrt16
	printcudec
	printcr

	print sqrt3
	lda #16
	jsr usqrt16
	printcudec
	printcr

	print sub1
	sec
	lda #537
	sbc #1919
	printcdec
	printcr

	println exit
	rtl
ENDPUBLIC

enter:	.asciiz "Math test enter."
abs1:	.asciiz "abs(-1385) = "
div1:	.asciiz "367 / 19 = "
div2:	.asciiz "48317 / 17 = "
div3:	.asciiz "48317 / 0 = "
divr:	.asciiz ", remainder = "
max1:	.asciiz "max(337, 171) = "
min1:	.asciiz "min(337, 171) = "
mul1:	.asciiz "36 * 19 = "
mul2:	.asciiz "337 * 171 = "
sqrt1:	.asciiz "sqrt(537) = "
sqrt2:	.asciiz "sqrt(1919) = "
sqrt3:	.asciiz "sqrt(16) = "
sub1:	.asciiz "537 - 1919 = "
exit:	.asciiz "Math test exit."
