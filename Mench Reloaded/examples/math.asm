; -----------------------------------------------------------------------------
; Match example for the Mench Reloaded SBC.
; The 65816 lacks opcodes for multiplication and division. The integer math
; library provides them and other useful mathematical functions.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "common.inc"
.include "math16.inc"
.include "print.inc"
.include "w65c265Monitor.inc"

; Main entry point for the program.
PUBLIC main
	jsl SEND_CR		; start output on a newline
	println enter
	ON16MEM
	ON16X

	print div1
	lda #19
	ldx #367
	jsr div16
	printcudec
	printcr

	print div2
	lda #17
	ldx #48317
	jsr div16
	printcudec
	printcr

	print mul1
	lda #36
	ldx #19
	jsr mult16
	printcudec
	printcr

	print mul2
	lda #337
	ldx #171
	jsr mult16
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
div1:	.asciiz "367 / 19 = "
div2:	.asciiz "48317 / 17 = "
mul1:	.asciiz "36 * 19 = "
mul2:	.asciiz "337 * 171 = "
sub1:	.asciiz "537 - 1919 = "
exit:	.asciiz "Math test exit."
