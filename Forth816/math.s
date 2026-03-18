;==============================================================================
; math.s - 65816 Forth Kernel Mathematics Primitives
;
; All words are in ROM. Dictionary entries are linked in order.
; The HEADER macro creates the link field, flags, and name.
; The CODEPTR macro emits the code field (ITC code pointer).
;
; Pattern for each primitive word:
;
;   HEADER  "NAME", NAME_CFA, flags, PREV_CFA
;   CODEPTR NAME_CODE
;   PUBLIC   NAME_CODE
;           ... machine code ...
;           NEXT
;   ENDPUBLIC
;
; All code assumes:
;   Native mode, A=16-bit, X=16-bit, Y=16-bit
;   unless explicitly switched with SEP/REP + .a8/.a16 hints
;==============================================================================

.include "forth.inc"
.include "macros.inc"
.include "dictionary.inc"
.include "print.inc"

.segment "CODE"

;==============================================================================
; SECTION 3: ARITHMETIC PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; + ( a b -- a+b )
;------------------------------------------------------------------------------
	HEADER "+", PLUS_CFA, 0, RFETCH_CFA
	CODEPTR PLUS_CODE
PUBLIC PLUS_CODE
	lda 0,X			; b
	clc
	adc 2,X			; a + b
	inx
	inx			; drop b
	sta 0,X			; Replace a with result
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; - ( a b -- a-b )
;------------------------------------------------------------------------------
	HEADER "-", MINUS_CFA, 0, PLUS_CFA
	CODEPTR MINUS_CODE
PUBLIC MINUS_CODE
	lda 2,X			; a
	sec
	sbc  0,X		; a - b
	inx
	inx			; drop b
	sta 0,X			; replace a with result
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; * ( a b -- a*b ) 16x16 -> 16 (low word)
;------------------------------------------------------------------------------
	HEADER "*", STAR_CFA, 0, MINUS_CFA
	CODEPTR STAR_CODE
PUBLIC STAR_CODE
	lda 0,X			; b (multiplier)
	sta TMPA
	lda 2,X			; a (multiplicand)
	inx
	inx			; Drop b slot
	stz 0,X			; Clear result
	phy			; save IP
	ldy #16			; 16 bit iterations
@loop:
	lsr TMPA		; Shift multiplier right
	bcc @skip
	clc
	adc 0,X			; Accumulate shifted multiplicand
	sta 0,X
@skip:
	asl			; Shift multiplicand left
	dey
	bne @loop
	;; TOS now contains the final result
	ply			; restore IP for NEXT call
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; UM* ( u1 u2 -- ud ) unsigned 16x16 -> 32-bit result
; Result: TOS = high cell, NOS = low cell
;------------------------------------------------------------------------------
	HEADER "UM*", UMSTAR_CFA, 0, STAR_CFA
	CODEPTR UMSTAR_CODE
PUBLIC UMSTAR_CODE
	lda 0,X			; u2 (multiplier)
	sta TMPA
	lda 2,X			; u1 (multiplicand)
	sta TMPB
	stz 2,X			; Clear high result
	stz 0,X			; Clear low result
	phy			; Save IP
	ldy #16
@loop:
	lsr TMPA
	bcc @skip
	; Add TMPB to 32-bit result
	clc
	lda 0,X			; Low result
	adc TMPB
	sta 0,X
	lda 2,X			; High result
	adc #0			; add carry bit
	sta 2,X
@skip:
	asl TMPB		; Shift multiplicand left
	dey
	bne @loop
	; Stack now has: NOS=high, TOS=low
	; ANS wants: NOS=low, TOS=high → swap
	lda 0,X
	sta SCRATCH0
	lda 2,X
	sta 0,X
	lda SCRATCH0
	sta 2,X
	ply			; restore IP
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; UM/MOD ( ud u -- ur uq ) unsigned 32/16 -> 16 remainder, 16 quotient
;------------------------------------------------------------------------------
	HEADER "UM/MOD", UMSLASHMOD_CFA, 0, UMSTAR_CFA
	CODEPTR UMSLASHMOD_CODE
PUBLIC   UMSLASHMOD_CODE
	; Stack: NOS_HI=ud_high NOS=ud_low TOS=u (divisor)
	; This is a standard 32/16 non-restoring division
	lda 0,X			; divisor
	sta TMPA
	lda 2,X			; ud_low
	sta TMPB
	lda 4,X			; ud_high → remainder register
	inx
	inx			; Drop divisor slot
	; Now: NOS=ud_high (remainder), TOS=ud_low (will become quotient)
	phy
	ldy #16
@loop:
	; Shift remainder:quotient left 1
	asl 0,X			; Shift quotient (ud_low) left
	rol 2,X			; Shift remainder left, carry in
	lda 2,X			; Subtract divisor from remainder
	sec
	sbc TMPA
	bcc @no_sub		; If borrow, don't subtract
	sta 2,X			; Update remainder
	inc 0,X			; Set quotient bit
@no_sub:
	dey
	bne @loop
	; NOS=remainder, TOS=quotient (already in place)
	ply
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; /MOD ( n1 n2 -- rem quot ) signed division
;------------------------------------------------------------------------------
	HEADER "/MOD", SLASHMOD_CFA, 0, UMSLASHMOD_CFA
	CODEPTR SLASHMOD_CODE
PUBLIC SLASHMOD_CODE
	jsr SLASHMOD_IMPL
	NEXT
ENDPUBLIC
.proc SLASHMOD_IMPL
	; Sign extend n1 (NOS) to 32 bits for UM/MOD
	; Use: sign of n2 and n1 for result sign adjustment
	lda 2,X			; n1
	sta TMPA		; Save n1
	lda 0,X			; n2
	sta TMPB		; Save n2

	; Take absolute values
	lda TMPA
	bpl @n1_pos
	eor #$FFFF
	inc
	sta 2,X
@n1_pos:
	lda TMPB
	bpl @n2_pos
	eor #$FFFF
	inc
	sta 0,X
@n2_pos:
	; Sign-extend n1 into 32-bit for UM/MOD
	; Push zero as high word
	dex
	dex
	lda 2,X			; |n1|
	sta 0,X			; low word
	stz 2,X			; high word = 0
	; Stack is now: NOS=0(ud_high) TOS2=|n1|(ud_low) TOS=|n2|
	; But we need NOS_HI, NOS, TOS ordering - fix stack
	; Swap to get: high, low, divisor
	lda 0,X			; |n2|
	pha
	lda 2,X			; |n1|
	sta 0,X
	stz 2,X
	pla
	dex
	dex
	sta 0,X
	; Now: 4,X=0(high) 2,X=|n1|(low) 0,X=|n2|(divisor)
	; This is correct for UM/MOD
	; ... call UM/MOD inline
	lda 0,X			; divisor
	sta SCRATCH0
	lda 2,X
	sta TMPB
	lda 4,X
	inx
	inx
	phy
	ldy #16
@divloop:
	asl 0,X
	rol 2,X
	lda 2,X
	sec
	sbc SCRATCH0
	bcc @nodiv
	sta 2,X
	inc 0,X
@nodiv:
	dey
	bne @divloop
	; Apply signs:
	; Remainder sign = sign of dividend (TMPA)
	; Quotient sign  = XOR of signs
	lda TMPA
	bpl @rem_pos
	lda 2,X
	eor #$FFFF
	inc
	sta 2,X
@rem_pos:
	lda TMPA
	eor TMPB
	bpl @quot_pos
	lda 0,X
	eor #$FFFF
	inc
	sta 0,X
@quot_pos:
	ply
	rts
.endproc

;------------------------------------------------------------------------------
; / ( n1 n2 -- quot ) signed division
;------------------------------------------------------------------------------
	HEADER "/", SLASH_CFA, 0, SLASHMOD_CFA
	CODEPTR SLASH_CODE
PUBLIC SLASH_CODE
	jsr SLASHMOD_IMPL	; Call /MOD then drop remainder
	lda 0,X			; Stack: NOS=rem TOS=quot → NIP
	inx			; Inline: NIP
	inx
	sta 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; MOD ( n1 n2 -- rem )
;------------------------------------------------------------------------------
	HEADER "MOD", MOD_CFA, 0, SLASH_CFA
	CODEPTR MOD_CODE
PUBLIC MOD_CODE
	jsr SLASHMOD_IMPL
	inx			; Stack: NOS=rem TOS=quot → DROP
	inx
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; NEGATE ( n -- -n )
;------------------------------------------------------------------------------
	HEADER "NEGATE", NEGATE_CFA, 0, MOD_CFA
	CODEPTR NEGATE_CODE
PUBLIC NEGATE_CODE
	lda 0,X
	eor #$FFFF
	inc
	sta 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; ABS ( n -- |n| )
;------------------------------------------------------------------------------
	HEADER "ABS", ABS_CFA, 0, NEGATE_CFA
	CODEPTR ABS_CODE
PUBLIC ABS_CODE
	lda 0,X
	bpl @done
	eor #$FFFF
	inc
	sta 0,X
@done:	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; MAX ( a b -- max )
;------------------------------------------------------------------------------
	HEADER "MAX", MAX_CFA, 0, ABS_CFA
	CODEPTR MAX_CODE
PUBLIC MAX_CODE
	lda 2,X			; a
	cmp 0,X			; a - b (signed)
	bpl @endif		; a >= b
	lda 0,X			; overwrite a, as b is max
	sta 2,X
@endif:	inx			; Drop TOS as NOS is max
	inx
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; MIN ( a b -- min )
;------------------------------------------------------------------------------
	HEADER "MIN", MIN_CFA, 0, MAX_CFA
	CODEPTR MIN_CODE
PUBLIC MIN_CODE
	lda 2,X			; a
	cmp 0,X			; a - b (signed)
	bmi @endif		; a < b
	lda 0,X			; overwrite a, as b is min
	sta 2,X
@endif:	inx			; drop TOS
	inx
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 1+ ( n -- n+1 )
;------------------------------------------------------------------------------
	HEADER "1+", ONEPLUS_CFA, 0, MIN_CFA
	CODEPTR ONEPLUS_CODE
PUBLIC ONEPLUS_CODE
	inc 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 1- ( n -- n-1 )
;------------------------------------------------------------------------------
	HEADER "1-", ONEMINUS_CFA, 0, ONEPLUS_CFA
	CODEPTR ONEMINUS_CODE
PUBLIC ONEMINUS_CODE
	dec 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 2* ( n -- n*2 )
;------------------------------------------------------------------------------
	HEADER "2*", TWOSTAR_CFA, 0, ONEMINUS_CFA
	CODEPTR TWOSTAR_CODE
PUBLIC TWOSTAR_CODE
	asl 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 2/ ( n -- n/2 ) arithmetic shift right
;------------------------------------------------------------------------------
	HEADER "2/", TWOSLASH_CFA, 0, TWOSTAR_CFA
	CODEPTR TWOSLASH_CODE
PUBLIC TWOSLASH_CODE
	lda 0,X			; Arithmetic shift right: preserve sign bit
	cmp #$8000		; Set carry if negative
	ror			; Shift right, sign bit from carry
	sta 0,X
	NEXT
ENDPUBLIC
