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
.include "math32.inc"
.include "print.inc"

; Normally this requires floating point arithmetic, but we're using fixed point
; unsigned arithmetic with 3 integer bits, and 13 fractional bits. 

;
; Aliases
;
THREE	= %0110000000000000
FOUR	= %1000000000000000
RESCALE	= %0010000000000000
CELL = 4
DS_SIZE = CELL * 10

.proc pi
	ON16MEM
	ON16X
	printcr			; start output on a newline

	phd			; save direct page register

	tsc			; get current stack pointer.
	sec
	sbc #DS_SIZE		; reserve data stack workspace
	tcs
	tcd			; direct page now points to stack
	ldx #DS_SIZE		; point X to data stack top

	lda #THREE		; initialize the sum on the data stack
	ldy #0000
	jsr _pushay

@while:	jsr calc_term
	lda #00
	ldy #00
	jsr _pushay
	jsr _stest32
	beq @done
	jsr _popay		; pop unused zero
	jsr _add32		; add term to the sum
	bra @while

@done:	jsr _popay		; remove the two unneeded zeros
	jsr _popay

	print msg1
	jsr _popay		; pop the results

	printc
	tya
	printc

	print msg2
	lda #RESCALE
	printc
	lda #0000
	printc
	printcr

	print msg3
	lda N+2
	printc
	lda N
	printc
	printcr

@cleanup:
	tsc			; clean up stack locals
	clc
	adc #DS_SIZE
	tcs
	pld			; restore direct page pointer
	rtl

.endproc
msg1:	.asciiz "Pi = 0x"
msg2:	.asciiz " / 0x"
msg3:	.asciiz "N = 0x"
N:	.word 2, 0

; calc_term: calculates Qn - Qn+1
; Inputs:
;   X - data stack index
; Outputs:
;   C - clobbered
;   X - data stack index updated with Qn - Qn+1 on data stack
;   Y - clobbered
.proc calc_term
	jsr quotient
	jsr quotient
	jsr _sub32
	rts
.endproc

; quotient: calculates a single scaled quotient term
; Inputs:
;   X - data stack index
; Outputs:
;   C - clobbered
;   X - data stack index updated with quotient on data stack
;   Y - clobbered
.proc quotient
	ldy #00			; numerator of fixed point four
	lda #FOUR
	jsr _pushay
	ldy #00			; scratch space for routine.
	lda #00			; ditto
	jsr _pushay
	jsr denominator		; calculate N*++N*++N
	jsr _udivmod32
	jsr _swap
	jsr _popay		; discard remainder
	rts
.endproc

; denominator: calculates (n)*(++n)*(++n)
; Inputs:
;   memory N
;   X - data stack index
; Outputs:
;   C - clobbered
;   X - data stack index updated with product on data stack
;   Y - clobbered
.proc denominator
	ldy N
	lda N+2
	jsr _pushay		; push N
	inclong N
	ldy N
	lda N+2
	jsr _pushay		; push ++N
	jsr _umult32		; ++n * n
	jsr _popay		; discard unused 32 bits of 64 bit result
	inclong N
	ldy N
	lda N+2			; push ++N
	jsr _pushay
	jsr _umult32		; ++n * first product
	jsr _popay		; discard unused 32 bits of 64 bit result
	rts
.endproc
