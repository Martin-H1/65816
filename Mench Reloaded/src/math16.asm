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
