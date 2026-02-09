; -----------------------------------------------------------------------------
; Sixteen bit math routines for operations beyond addition and subtraction.
; div16, mult16 are from "Programming the 65816" by David Eyes and Ron Lichty
; The remainder are original works.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------
__math16_asm__ = 1

.include "common.inc"
.include "math16.inc"

; abs16 - takes the absolute value of the input.
; Inputs:
;   C - number of take absolute value.
; Outputs
;   C - result
PUBLIC abs16
	and #$ffff
	bpl @return
	dec			; undo two's complement
	eor #$ffff
@return:
	rts
ENDPUBLIC

; div16 - 16 bit integer divison. It works by multipyling divisor by two
; to get its highest 16 bit multiple. It then conditinally subtracts from
; the dividend iteratively until the shift count reaches zero.
; Inputs:
;   C - divisor
;   X - dividend
; Outputs:
;   C - quotient ($ffff if you divide by zero)
;   X - remainder (dividend if you divide by zero)
;   Y - clobbered
PUBLIC div16
	QUOTIENT = 3
	DIVISOR = 1
	phd			; save direct page register
	pea $0000		; initialize quotient to 0
	pea $0000		; reserve space for divisor

	tay
	tsc			; transfer stack pointer to direct page reg
	tcd			; function local space is now direct page.
	tya
	ldy #1			; initialize shift count to 1
@times2:
	asl			; 2 * divisor until we get 1 in the carry bit.
	bcs @maxdivisor
	iny			; increment the shift count and stop when
	cpy #17			; all bits are processed. If max count is
				; reached there are all zeroes in divisor
	bne @times2

	lda #$ffff		; divide by zero error.
	sta QUOTIENT
	bra @return

@maxdivisor:
	ror			; restore shifted-out bit to divisor

@subtract:			; now divide by subtraction
	sta DIVISOR		; save current divisor
	txa			; get dividend into the accumulator
	sec
	sbc DIVISOR		; subtract divisor from dividend
	bcc @skip		; branch if can't subtract; dividend still in X
	tax 			; store new dividend; carry=1 for quotient

@skip:	rol QUOTIENT		; shift carry quotient (1 for divide, 0 for not)
	lda DIVISOR		; restore divisor
	lsr			; shift divisor right for next subtract
	dey			; decrement shift count
	bne @subtract		; branch to repeat unless count is 0
@return:
	pla			; drop divisor
	pla			; get quotient into C
	pld
	rts
ENDPUBLIC

; mult16 - 16 bit integer multiplication via bit shifting and addition.
; Inputs:
;   C - multiplier
;   X - multiplicand
; Outputs:
;   C - product
;   X - clobbered
PUBLIC mult16
	MULTIPLICAND = 3
	MULTIPLIER = 1
	phd			; save direct page register
	phx			; Initialize stack locals.
	pha
	tsc			; transfer stack pointer to direct page reg
	tcd			; function local space is now direct page.
	lda #0			; initialize product
@while:	ldx MULTIPLIER		; while multiplier is not zero.
	beq @return
	lsr MULTIPLIER		; get right bit, operand 1
	bcc @else		; if clean no addition to previous products
	clc			; else add oprd 2 to partial result
	adc MULTIPLICAND
@else:	asl MULTIPLICAND	; now shift oprd 2 left for poss add next time
	bra @while
@return:
	plx			; clean up stack and restore direct page
	plx
	pld
	rts
ENDPUBLIC

; sqrt16 - 16 bit fast integer square root algorithm, with rounding the
; result to the next greater integer if the fractional part is 0.5 or
; greater. For example 2->1, 3->2, 4->2, 6->2, 7->3, 9->3
; Inputs:
;   C - unsigned number whose square root to compute.
; Outputs:
;   C - unsigned square root.
;   X - clobbered
PUBLIC sqrt16
	MAX_BIT = $4000		; Number with the highest non sign bit set.
	N = 5			; input number n to find square root.
	PBIT = 3		; the highest power of 4 <= N
	RESULT = 1
	phd
	pha			; push N
	pea MAX_BIT		; initialize to highest positive power of two.
	pea $0000		; result (output, starts at 0).

	tsc			; transfer stack pointer to direct page reg
	tcd			; function local space is now direct page.

@starting_bit:
	lda PBIT		; compute highest power of four <= n
	cmp N
	bcc @while		; PBIT < N
	beq @while		; PBIT = N
	lsr PBIT
	lsr PBIT
	bra @starting_bit

@while:	clc
	lda RESULT		; RESULT + PBIT
	adc PBIT
	cmp N			; if N >= (RESULT + PBIT)
	bcc @endif
	lda RESULT		; compute n = n - (result + one)
	inc
	eor #$ffff		; Add the two's complement to N
	inc			; add one
	clc
	adc N
	sta N
	lda PBIT		; compute result += 2 * bit;
	asl
	clc
	adc RESULT
	sta RESULT
@endif:
	lsr RESULT		; divide result by 2
	lsr PBIT		; divide bit by 4.
	lsr PBIT
	bne @while		; while power bit is not zero

	lda N			; if RESULT > N then
	cmp RESULT
	bcs @return
	lda RESULT		; Round result to nearest integer.
	inc
	sta RESULT
@return:
	pla			; return result.
	plx			; bit and n have outlived their usefulness
	plx
	pld
	rts
ENDPUBLIC
