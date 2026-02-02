; -----------------------------------------------------------------------------
; Sixteen bit math routines for operations beyond addition and subtraction.
; From "Programming the 65816" by David Eyes and Ron Lichty
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

; div16 - 16 bit divison but returns $ffff if you divide by zero
; Inputs:
;   C - divisor
;   X - dividend
; Outputs:
;   C - quotient
;   X - remainder
;   Y - clobbered
.proc div16
	QUOTIENT = 3
	DIVISOR = 1
	pea $0000		; initialize quotient to 0
	pea $0000		; initialize divisor to 0
	ldy #1			; initialize shift count to 1

@div1:	asl			; shift divisor: test leftmost bit
	bcs @div2		; branch when get leftmost bit
	iny			; otherwise increment shift count
	cpy #17			; max count (all zeroes in divisor)
	bne @div1		; loop until all bits processed

@div2:	ror			; restore shifted-out bit

				; now divide by subtraction
@div4:	sta DIVISOR,s		; save divisor
	txa			; get dividend into the accumulator
	sec
	sbc DIVISOR,s		; SBC 1,S subtract divisor from dividend
	bcc @div3		; branch if can't subtract; dividend still in X
	tax 			; store new dividend; carry=1 for quotient

@div3:	lda QUOTIENT,s
	rol			; shift carry quotient (1 for divide, 0 for not)
	sta QUOTIENT,s
	lda DIVISOR,s		; restore divisor
	lsr			; shift divisor right for next subtract
	dey			; decrement count
	bne @div4		; branch to repeat unless count is 0
	ply			; clean up stack
	ply			; clean up stack
	rts
.endproc
