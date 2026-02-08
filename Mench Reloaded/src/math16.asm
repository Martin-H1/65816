; -----------------------------------------------------------------------------
; Sixteen bit math routines for operations beyond addition and subtraction.
; From "Programming the 65816" by David Eyes and Ron Lichty
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------
__math16_asm__ = 1

.include "common.inc"
.include "math16.inc"

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
	pea $0000		; initialize quotient to 0
	pea $0000		; reserve space for divisor
	ldy #1			; initialize shift count to 1

@times2:
	asl			; 2 * divisor until we get 1 in the carry bit.
	bcs @maxdivisor
	iny			; increment the shift count and stop when
	cpy #17			; all bits are processed. If max count is
				; reached there are all zeroes in divisor
	bne @times2

	lda #$ffff		; divide by zero error.
	sta QUOTIENT,s
	bra @return

@maxdivisor:
	ror			; restore shifted-out bit to divisor

@subtract:			; now divide by subtraction
	sta DIVISOR,s		; save current divisor
	txa			; get dividend into the accumulator
	sec
	sbc DIVISOR,s		; subtract divisor from dividend
	bcc @skip		; branch if can't subtract; dividend still in X
	tax 			; store new dividend; carry=1 for quotient

@skip:	lda QUOTIENT,s		; shift carry quotient (1 for divide, 0 for not)
	rol
	sta QUOTIENT,s
	lda DIVISOR,s		; restore divisor
	lsr			; shift divisor right for next subtract
	dey			; decrement shift count
	bne @subtract		; branch to repeat unless count is 0
@return:
	pla			; drop divisor
	pla			; get quotient into C
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

	; Throughout the function we'll juggle these numbers:
	; n (input), pbit (computed), and result (output, starts at 0).
	N = 5
	PBIT = 3
	RESULT = 1
	pha
	pea MAX_BIT
	pea $0000

@while:				; while power bit is not zero
	clc
	lda RESULT		; RESULT + PBIT
	adc PBIT
	tax			; save (RESULT + PBIT) for later
	cmp N			; N >= (RESULT + PBIT)
	bmi @endif		; check this operation
	lda RESULT		; compute n = n - (result + one)
	inc
	eor $ffff		; Add the two's complement to N
	clc
	inc			; add one
	clc
	adc N
	sta N
	lda PBIT			; compute result += 2 * bit;
	asl
	clc
	adc RESULT
	sta RESULT
@endif:
	lsr RESULT		; divide result by 2
	lsr PBIT			; divide bit by 4.
	lsr PBIT
	lda PBIT
	bne @while

	;;; Do arithmetic rounding to nearest integer.
	;; round up n2 by one if n1 is greater
	;; : round_up ( n1 n2 - n1 n2 )
	;;    2dup > if
	;;        1+
	;;    then ;

@return:
	pla			; return result.
	plx			; bit and n have outlived their usefulness
	plx
	rts
ENDPUBLIC
