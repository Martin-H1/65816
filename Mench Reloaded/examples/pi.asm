; Calculate pi using the Nilakantha infinite series. While more complicated
; than the Leibniz formula, it is fairly easy to understand, and converges
; on pi much more quickly.

; The formula takes three and alternately adds and subtracts fractions with
; a numerator of 4 and denominator that is the product of three consecutive
; integers. So each subsequent fraction begins its set of integers with the
; highest value used in the previous fraction.

; Described in C syntax n starts at 2 and iterates to the desired precision.
; pi = 3 + 4/((n)*(++n)*(++n)) - 4/((n)*(++n)*(++n)) + ...

; Here's a three iteration example with an error slightly more than 0.0007.
; pi = 3 + 4/(2*3*4) - 4/(4*5*6)
;        + 4/(6*7*8) - 4/(8*9*10)
;        + 4/(10*11*12) - 4/(12*13*14)
;    = 3.14088134088

.include "ascii.inc"
.include "common.inc"
.include "math16.inc"
.include "print.inc"

; Normally this requires floating point arithmetic, but we're using fixed point
; unsigned arithmetic with 3 integer bits, and 13 fractional bits. 

;
; Aliases
;
THREE	= %0110000000000000
FOUR	= %1000000000000000
RESCALE	= %0010000000000000

.proc pi
	ON16MEM
	ON16X
	printcr			; start output on a newline

	lda #2			; Computes pi as a ratio of integers
	sta N
	lda #THREE
	sta SUM
@while:	jsr calc_term
	cmp #0
	beq @done
	clc
	adc SUM
	sta SUM
	bra @while
@done:	lda SUM
	print msg1
	printcudec
	print msg2
	lda #RESCALE
	printcudec
	printcr
	rtl
.endproc
msg1:	.asciiz "Pi = "
msg2:	.asciiz " / "
N:	.word 0
SUM:	.word 0

; calc_term: calculates Qn - Qn+1
; Inputs:
;   memory N
; Outputs:
;   C - the difference of two terms.
;   X - clobbered
.proc calc_term
	jsr quotient
	pha
	jsr quotient
	tax
	pla
	phx
	sec
	sbc 1,s
	plx
	rts
.endproc

; quotient: calculates a single scaled quotient term
; Inputs:
;   memory N
; Outputs:
;   C - the quotient
.proc quotient
	jsr denominator
	ldx #FOUR
	jsr udiv16
	rts
.endproc

; denominator: calculates (n)*(++n)*(++n)
; Inputs:
;   memory N
; Outputs:
;   C - the product
.proc denominator
	ldx N
	inc N
	lda N
	jsr umult16		; ++n * n
	tax			; save first product
	inc N
	lda N
	jsr umult16		; ++n * first product
	rts
.endproc
