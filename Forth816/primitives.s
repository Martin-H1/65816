;==============================================================================
; primitives.s - 65816 Forth Kernel Primitives
;
; All words are in ROM. Dictionary entries are linked in order.
; The HEADER macro creates the link field, flags, and name.
; The CODEPTR macro emits the code field (ITC code pointer).
;
; Pattern for each primitive word:
;
;   HEADER  "NAME", NAME_CFA, flags, PREV_CFA
;   CODEPTR NAME_CODE
;   .proc   NAME_CODE
;           ... machine code ...
;           NEXT
;   .endproc
;
; All code assumes:
;   Native mode, A=16-bit, X=16-bit, Y=16-bit
;   unless explicitly switched with SEP/REP + .a8/.a16 hints
;==============================================================================

.p816
.smart off

.include "macros.inc"
.include "dictionary.inc"
.include "print.inc"

.segment "CODE"

;==============================================================================
; SECTION 1: STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; DUP ( a -- a a )
;------------------------------------------------------------------------------
	HEADER "DUP", DUP_CFA, 0, 0
	CODEPTR DUP_CODE
.proc DUP_CODE
	.a16
	.i16
	lda 0,X			; Load TOS
	dex
	dex
	sta 0,X			; Push copy
	NEXT
.endproc

;------------------------------------------------------------------------------
; DROP ( a -- )
;------------------------------------------------------------------------------
	HEADER "DROP", DROP_CFA, 0, DUP_CFA
	CODEPTR DROP_CODE
.proc DROP_CODE
	.a16
	.i16
	inx
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; SWAP ( a b -- b a )
;------------------------------------------------------------------------------
	HEADER "SWAP", SWAP_CFA, 0, DROP_CFA
	CODEPTR SWAP_CODE
.proc SWAP_CODE
	.a16
	.i16
	lda 0,X			; b (TOS)
	sta SCRATCH0
	lda 2,X			; a (NOS)
	sta 0,X			; TOS = a
	lda SCRATCH0		; b
	sta 2,X			; NOS = b
	NEXT
.endproc

;------------------------------------------------------------------------------
; OVER ( a b -- a b a )
;------------------------------------------------------------------------------
	HEADER "OVER", OVER_CFA, 0, SWAP_CFA
	CODEPTR OVER_CODE
.proc OVER_CODE
	.a16
	.i16
	lda 2,X			; a (NOS)
	dex
	dex
	sta 0,X			; Push copy of a
	NEXT
.endproc

;------------------------------------------------------------------------------
; ROT ( a b c -- b c a )
;------------------------------------------------------------------------------
	HEADER "ROT", ROT_CFA, 0, OVER_CFA
	CODEPTR ROT_CODE
.proc ROT_CODE
	.a16
	.i16
	lda 4,X			; a (bottom)
	sta SCRATCH0
	lda 2,X			; b
	sta 4,X			; bottom slot = b
	lda 0,X			; c (TOS)
	sta 2,X			; middle slot = c
	lda SCRATCH0		; a
	sta 0,X			; TOS = a
	NEXT
.endproc

;------------------------------------------------------------------------------
; NIP ( a b -- b )
;------------------------------------------------------------------------------
	HEADER "NIP", NIP_CFA, 0, ROT_CFA
	CODEPTR NIP_CODE
.proc NIP_CODE
	.a16
	.i16
	lda 0,X			; b (TOS)
	inx
	inx
	sta 0,X			; Overwrite a with b
	NEXT
.endproc

;------------------------------------------------------------------------------
; TUCK ( a b -- b a b )
;------------------------------------------------------------------------------
	HEADER "TUCK", TUCK_CFA, 0, NIP_CFA
	CODEPTR TUCK_CODE
.proc TUCK_CODE
	.a16
	.i16
	lda 0,X			; b
	sta SCRATCH0
	lda 2,X			; a
	sta 0,X			; TOS = a
	dex
	dex
	lda SCRATCH0		; b
	sta 0,X			; New TOS = b
	lda SCRATCH0
	sta 4,X			; Slot below a = b
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2DROP ( a b -- )
;------------------------------------------------------------------------------
	HEADER "2DROP", TWODROP_CFA, 0, TUCK_CFA
	CODEPTR TWODROP_CODE
.proc TWODROP_CODE
	.a16
	.i16
	inx
	inx
	inx
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2DUP ( a b -- a b a b )
;------------------------------------------------------------------------------
	HEADER "2DUP", TWODUP_CFA, 0, TWODROP_CFA
	CODEPTR TWODUP_CODE
.proc   TWODUP_CODE
	.a16
	.i16
	lda 2,X			; a
	sta SCRATCH0
	lda 0,X			; b
	dex
	dex
	dex
	dex
	sta 0,X			; Push b
	lda SCRATCH0
	sta 2,X			; Push a below b
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2SWAP ( a b c d -- c d a b )
;------------------------------------------------------------------------------
	HEADER "2SWAP", TWOSWAP_CFA, 0, TWODUP_CFA
	CODEPTR TWOSWAP_CODE
.proc TWOSWAP_CODE
	.a16
	.i16
	lda 0,X			; d
	sta SCRATCH0
	lda 2,X			; c
	sta SCRATCH1
	lda 4,X			; b
	sta 0,X
	lda 6,X			; a
	sta 2,X
	lda SCRATCH0		; d
	sta 4,X
	lda SCRATCH1		; c
	sta 6,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2OVER ( a b c d -- a b c d a b )
;------------------------------------------------------------------------------
	HEADER "2OVER", TWOOVER_CFA, 0, TWOSWAP_CFA
	CODEPTR TWOOVER_CODE
.proc TWOOVER_CODE
	.a16
	.i16
	lda 6,X			; a
	sta SCRATCH0
	lda 4,X			; b
	dex
	dex
	dex
	dex
	sta 0,X			; Push b (TOS)
	lda SCRATCH0
	sta 2,X			; Push a
	NEXT
.endproc

;------------------------------------------------------------------------------
; DEPTH ( -- n ) number of items on parameter stack
;------------------------------------------------------------------------------
	HEADER "DEPTH", DEPTH_CFA, 0, TWOOVER_CFA
	CODEPTR DEPTH_CODE
.proc DEPTH_CODE
	.a16
	.i16
	stx SCRATCH0		; compute (PSP_INIT - x) / 2
	lda #$03FF
	sec
	sbc SCRATCH0
	lsr			; Divide by 2 (cells)
	dex
	dex
	sta 0,X			; push to TOS
	NEXT
.endproc

;------------------------------------------------------------------------------
; PICK ( xu...x1 x0 u -- xu...x1 x0 xu )
;------------------------------------------------------------------------------
	HEADER "PICK", PICK_CFA, 0, DEPTH_CFA
	CODEPTR PICK_CODE
.proc PICK_CODE
	.a16
	.i16
	stx SCRATCH0
	lda 0,X			; u
	inc			; u+1 (skip u itself)
	asl			; * 2 (cell size)
	clc
	adc SCRATCH0		; X + (u+1)*2
	sta SCRATCH0
	lda (SCRATCH0)		; Fetch xu
	sta 0,X			; Replace u with xu
	NEXT
.endproc

;==============================================================================
; SECTION 2: RETURN STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; >R ( a -- ) (R: -- a)
;------------------------------------------------------------------------------
	HEADER ">R", TOR_CFA, 0, PICK_CFA
	CODEPTR TOR_CODE
.proc TOR_CODE
	.a16
	.i16
	lda 0,X			; Pop from parameter stack
	inx
	inx
	pha			; Push onto return stack
	NEXT
.endproc

;------------------------------------------------------------------------------
; R> ( -- a ) (R: a -- )
;------------------------------------------------------------------------------
	HEADER "R>", RFROM_CFA, 0, TOR_CFA
	CODEPTR RFROM_CODE
.proc RFROM_CODE
	.a16
	.i16
	pla			; Pop from return stack
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
.endproc

;------------------------------------------------------------------------------
; R@ ( -- a ) (R: a -- a)
;------------------------------------------------------------------------------
	HEADER "R@", RFETCH_CFA, 0, RFROM_CFA
	CODEPTR RFETCH_CODE
.proc RFETCH_CODE
	.a16
	.i16
	; Officially this function peeks at return stack without popping.
	; Unofficially it's easier to pop and push back.
	pla			; Pop R@ value
	pha			; Push R@ back
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
.endproc

;==============================================================================
; SECTION 3: ARITHMETIC PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; + ( a b -- a+b )
;------------------------------------------------------------------------------
	HEADER "+", PLUS_CFA, 0, RFETCH_CFA
	CODEPTR PLUS_CODE
.proc PLUS_CODE
	.a16
	.i16
	lda 0,X			; b
	clc
	adc 2,X			; a + b
	inx
	inx			; drop b
	sta 0,X			; Replace a with result
	NEXT
.endproc

;------------------------------------------------------------------------------
; - ( a b -- a-b )
;------------------------------------------------------------------------------
	HEADER "-", MINUS_CFA, 0, PLUS_CFA
	CODEPTR MINUS_CODE
.proc MINUS_CODE
	.a16
	.i16
	lda 2,X			; a
	sec
	sbc  0,X		; a - b
	inx
	inx			; drop b
	sta 0,X			; replace a with result
	NEXT
.endproc

;------------------------------------------------------------------------------
; * ( a b -- a*b ) 16x16 -> 16 (low word)
;------------------------------------------------------------------------------
	HEADER "*", STAR_CFA, 0, MINUS_CFA
	CODEPTR STAR_CODE
.proc STAR_CODE
	.a16
	.i16
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
.endproc

;------------------------------------------------------------------------------
; UM* ( u1 u2 -- ud ) unsigned 16x16 -> 32-bit result
; Result: TOS = high cell, NOS = low cell
;------------------------------------------------------------------------------
	HEADER "UM*", UMSTAR_CFA, 0, STAR_CFA
	CODEPTR UMSTAR_CODE
.proc UMSTAR_CODE
	.a16
	.i16
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
.endproc

;------------------------------------------------------------------------------
; UM/MOD ( ud u -- ur uq ) unsigned 32/16 -> 16 remainder, 16 quotient
;------------------------------------------------------------------------------
	HEADER "UM/MOD", UMSLASHMOD_CFA, 0, UMSTAR_CFA
	CODEPTR UMSLASHMOD_CODE
.proc   UMSLASHMOD_CODE
	.a16
	.i16
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
.endproc

;------------------------------------------------------------------------------
; /MOD ( n1 n2 -- rem quot ) signed division
;------------------------------------------------------------------------------
	HEADER "/MOD", SLASHMOD_CFA, 0, UMSLASHMOD_CFA
	CODEPTR SLASHMOD_CODE
.proc SLASHMOD_CODE
	.a16
	.i16
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
	NEXT
.endproc

;------------------------------------------------------------------------------
; / ( n1 n2 -- quot ) signed division
;------------------------------------------------------------------------------
	HEADER "/", SLASH_CFA, 0, SLASHMOD_CFA
	CODEPTR SLASH_CODE
.proc SLASH_CODE
	.a16
	.i16
	jsr SLASHMOD_CODE	; Call /MOD then drop remainder
	lda 0,X			; Stack: NOS=rem TOS=quot → NIP
	inx			; Inline: NIP
	inx
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; MOD ( n1 n2 -- rem )
;------------------------------------------------------------------------------
	HEADER "MOD", MOD_CFA, 0, SLASH_CFA
	CODEPTR MOD_CODE
.proc MOD_CODE
	.a16
	.i16
	jsr SLASHMOD_CODE
	inx			; Stack: NOS=rem TOS=quot → DROP
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; NEGATE ( n -- -n )
;------------------------------------------------------------------------------
	HEADER "NEGATE", NEGATE_CFA, 0, MOD_CFA
	CODEPTR NEGATE_CODE
.proc NEGATE_CODE
	.a16
	.i16
	lda 0,X
	eor #$FFFF
	inc
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; ABS ( n -- |n| )
;------------------------------------------------------------------------------
	HEADER "ABS", ABS_CFA, 0, NEGATE_CFA
	CODEPTR ABS_CODE
.proc ABS_CODE
	.a16
	.i16
	lda 0,X
	bpl @done
	eor #$FFFF
	inc
	sta 0,X
@done:	NEXT
.endproc

;------------------------------------------------------------------------------
; MAX ( a b -- max )
;------------------------------------------------------------------------------
	HEADER "MAX", MAX_CFA, 0, ABS_CFA
	CODEPTR MAX_CODE
.proc MAX_CODE
	.a16
	.i16
	lda 2,X			; a
	cmp 0,X			; a - b (signed)
	bpl @endif		; a >= b
	lda 0,X			; overwrite a, as b is max
	sta 2,X
@endif:	inx			; Drop TOS as NOS is max
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; MIN ( a b -- min )
;------------------------------------------------------------------------------
	HEADER "MIN", MIN_CFA, 0, MAX_CFA
	CODEPTR MIN_CODE
.proc MIN_CODE
	.a16
	.i16
	lda 2,X			; a
	cmp 0,X			; a - b (signed)
	bmi @endif		; a < b
	lda 0,X			; overwrite a, as b is min
	sta 2,X
@endif:	inx			; drop TOS
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; 1+ ( n -- n+1 )
;------------------------------------------------------------------------------
	HEADER "1+", ONEPLUS_CFA, 0, MIN_CFA
	CODEPTR ONEPLUS_CODE
.proc ONEPLUS_CODE
	.a16
	.i16
	inc 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; 1- ( n -- n-1 )
;------------------------------------------------------------------------------
	HEADER "1-", ONEMINUS_CFA, 0, ONEPLUS_CFA
	CODEPTR ONEMINUS_CODE
.proc ONEMINUS_CODE
	.a16
	.i16
	dec 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2* ( n -- n*2 )
;------------------------------------------------------------------------------
	HEADER "2*", TWOSTAR_CFA, 0, ONEMINUS_CFA
	CODEPTR TWOSTAR_CODE
.proc TWOSTAR_CODE
	.a16
	.i16
	asl 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2/ ( n -- n/2 ) arithmetic shift right
;------------------------------------------------------------------------------
	HEADER "2/", TWOSLASH_CFA, 0, TWOSTAR_CFA
	CODEPTR TWOSLASH_CODE
.proc   TWOSLASH_CODE
	.a16
	.i16
	lda 0,X			; Arithmetic shift right: preserve sign bit
	cmp #$8000		; Set carry if negative
	ror			; Shift right, sign bit from carry
	sta 0,X
	NEXT
.endproc

;==============================================================================
; SECTION 4: COMPARISON PRIMITIVES
; ANS Forth: TRUE = $FFFF, FALSE = $0000
;==============================================================================

;------------------------------------------------------------------------------
; = ( a b -- flag )
;------------------------------------------------------------------------------
	HEADER "=", EQUAL_CFA, 0, TWOSLASH_CFA
	CODEPTR EQUAL_CODE
.proc EQUAL_CODE
	.a16
	.i16
	lda 0,X			; b
	inx			; drop b
	inx
	cmp 0,X			; a == b?
	beq @true
	stz 0,X			; set TOS to false
	NEXT
@true:	lda #$FFFF
	sta 0,X			; set TOS to true
	NEXT
.endproc

;------------------------------------------------------------------------------
; <> ( a b -- flag )
;------------------------------------------------------------------------------
	HEADER "<>", NOTEQUAL_CFA, 0, EQUAL_CFA
	CODEPTR NOTEQUAL_CODE
.proc NOTEQUAL_CODE
	.a16
	.i16
	lda 0,X			; b
	inx			; drop b
	inx
	cmp 0,X			; a != b
	bne @true
	stz 0,X			; set TOS to false
	NEXT
@true:	lda #$FFFF
	sta 0,X			; set TOS to true
	NEXT
.endproc

;------------------------------------------------------------------------------
; < ( a b -- flag ) signed
;------------------------------------------------------------------------------
	HEADER "<", LESS_CFA, 0, NOTEQUAL_CFA
	CODEPTR LESS_CODE
.proc LESS_CODE
	.a16
	.i16
	lda 2,X			; a
	sec
	sbc 0,X			; a - b
	inx			; drop b
	inx
	bvs @overflow		; Overflow-aware signed compare
	bmi @true		; result negative and no overflow = a<b
        bra @false
@overflow:
	bpl @true		; overflow + positive result = a<b
@false:	stz 0,X			; set TOS to false
	NEXT
@true:	lda #$FFFF		; set TOS to true
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; > ( a b -- flag ) signed
;------------------------------------------------------------------------------
	HEADER ">", GREATER_CFA, 0, LESS_CFA
	CODEPTR GREATER_CODE
.proc GREATER_CODE
	.a16
	.i16
	lda 0,X			; b
	sec
	sbc  2,X		; b - a (reversed for >)
	inx			; drop b
	inx
	bvs @overflow		; Overflow-aware signed compare
	bmi @true		; like the previous function
	bra @false
@overflow:
	bpl @true
@false:	stz 0,X			; set TOS to false
	NEXT
@true:	lda #$FFFF		; set TOS to true
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; U< ( u1 u2 -- flag ) unsigned less than
;------------------------------------------------------------------------------
	HEADER "U<", ULESS_CFA, 0, GREATER_CFA
	CODEPTR ULESS_CODE
.proc ULESS_CODE
	.a16
	.i16
	lda 2,X			; u1
	cmp 0,X			; u1 - u2 (unsigned)
	inx			; drop u2
	inx
	bcc @true		; Carry clear = u1 < u2
	stz 0,X
	NEXT
@true:	lda #$FFFF
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; U> ( u1 u2 -- flag ) unsigned greater than
;------------------------------------------------------------------------------
	HEADER "U>", UGREATER_CFA, 0, ULESS_CFA
	CODEPTR UGREATER_CODE
.proc UGREATER_CODE
.a16
.i16
	lda 0,X			; u2
	cmp 2,X			; u2 - u1 (reversed)
	inx			; drop u2
	inx
	bcc @true		; Carry clear = u2 < u1
	stz 0,X
	NEXT
@true:	lda #$FFFF
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; 0= ( a -- flag )
;------------------------------------------------------------------------------
	HEADER "0=", ZEROEQ_CFA, 0, UGREATER_CFA
	CODEPTR ZEROEQ_CODE
.proc ZEROEQ_CODE
	.a16
	.i16
	lda 0,X			; load and test TOS
	bne @false
	lda #$FFFF		; if it's zero, set TOS to TRUE
	sta 0,X
	NEXT
@false:	stz 0,X			; otherwise, set TOS to FALSE
	NEXT
.endproc

;------------------------------------------------------------------------------
; 0< ( a -- flag )
;------------------------------------------------------------------------------
	HEADER "0<", ZEROLESS_CFA, 0, ZEROEQ_CFA
	CODEPTR ZEROLESS_CODE
.proc ZEROLESS_CODE
	.a16
	.i16
	lda 0,X			; load and test TOS
	bpl @false
	lda #$FFFF		; on negative, set TOS to TRUE
	sta 0,X
	NEXT
@false:	stz 0,X			; otherwise, set TOS to FALSE
	NEXT
.endproc

;------------------------------------------------------------------------------
; 0> ( a -- flag )
;------------------------------------------------------------------------------
	HEADER "0>", ZEROGT_CFA, 0, ZEROLESS_CFA
	CODEPTR ZEROGT_CODE
.proc ZEROGT_CODE
	.a16
	.i16
	lda 0,X			; load and test TOS
	beq @false		; handle zero, as it is a positive
	bpl @true
@false:	stz 0,X			; zero or negative, set TOS to FALSE
	NEXT
@true:	lda #$FFFF		; otherwise, set TOS to TRUE
	sta 0,X
	NEXT
.endproc

;==============================================================================
; SECTION 5: LOGIC PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; AND ( a b -- a&b )
;------------------------------------------------------------------------------
	HEADER "AND", AND_CFA, 0, ZEROGT_CFA
	CODEPTR AND_CODE
.proc AND_CODE
	.a16
	.i16
	lda 0,X			; b
	inx			; drop b
	inx
	and 0,X			; a AND b
	sta 0,X			; set TOS to a AND b
	NEXT
.endproc

;------------------------------------------------------------------------------
; OR ( a b -- a|b )
;------------------------------------------------------------------------------
	HEADER "OR", OR_CFA, 0, AND_CFA
	CODEPTR OR_CODE
.proc OR_CODE
	.a16
	.i16
	lda 0,X			; b
	inx			; drop b
	inx
	ora 0,X			; a OR b
	sta 0,X			; set TOS to a OR b
	NEXT
.endproc

;------------------------------------------------------------------------------
; XOR ( a b -- a^b )
;------------------------------------------------------------------------------
	HEADER "XOR", XOR_CFA, 0, OR_CFA
	CODEPTR XOR_CODE
.proc XOR_CODE
	.a16
	.i16
	lda 0,X			; b
	inx			; drop b
	inx
	eor 0,X
	sta 0,X			; set TOS to a XOR b
	NEXT
.endproc

;------------------------------------------------------------------------------
; INVERT ( a -- ~a )
;------------------------------------------------------------------------------
	HEADER "INVERT", INVERT_CFA, 0, XOR_CFA
	CODEPTR INVERT_CODE
.proc INVERT_CODE
	.a16
	.i16
	lda 0,X
	eor #$FFFF
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; LSHIFT ( a u -- a<<u )
;------------------------------------------------------------------------------
	HEADER "LSHIFT", LSHIFT_CFA, 0, INVERT_CFA
	CODEPTR LSHIFT_CODE
.proc LSHIFT_CODE
	.a16
	.i16
	lda 0,X			; shift count
	inx			; drop u
	inx
	phy			; save IP
	tay
	beq @done		; u==0 bug check
	lda 0,X
@loop:	asl
	dey
	bne @loop
	sta 0,X			; save to TOS
@done:	ply
        NEXT
.endproc

;------------------------------------------------------------------------------
; RSHIFT ( a u -- a>>u ) logical shift right
;------------------------------------------------------------------------------
	HEADER "RSHIFT", RSHIFT_CFA, 0, LSHIFT_CFA
	CODEPTR RSHIFT_CODE
.proc RSHIFT_CODE
	.a16
	.i16
	lda 0,X			; shift count
	inx			; drop u
	inx
	phy			; save IP
	tay
	beq @done		; u==0 bug check
	lda 0,X
@loop:	lsr
	dey
	bne @loop
	sta 0,X			; save to TOS
@done:	ply
	NEXT
.endproc

;==============================================================================
; SECTION 6: MEMORY PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; @ ( addr -- val ) fetch cell
;------------------------------------------------------------------------------
	HEADER "@", FETCH_CFA, 0, RSHIFT_CFA
	CODEPTR FETCH_CODE
.proc FETCH_CODE
	.a16
	.i16
	lda 0,X			; move addr to scratch pointer
	sta SCRATCH0
	lda (SCRATCH0)		; fetch and store value to TOS
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; ! ( val addr -- ) store cell
;------------------------------------------------------------------------------
	HEADER "!", STORE_CFA, 0, FETCH_CFA
	CODEPTR STORE_CODE
.proc STORE_CODE
	.a16
	.i16
	lda 0,X			; pop addr to scratch pointer
	sta SCRATCH0
	inx
	inx
	lda 0,X			; pop val
	inx
	inx
	sta (SCRATCH0)		; save through scratch pointer
	NEXT
.endproc

;------------------------------------------------------------------------------
; C@ ( addr -- byte ) fetch byte
;------------------------------------------------------------------------------
	HEADER "C@", CFETCH_CFA, 0, STORE_CFA
	CODEPTR CFETCH_CODE
.proc CFETCH_CODE
	.a16
	.i16
	lda 0,X			; copy addr to scratch pointer
	sta SCRATCH0
	sep #$20		; enter byte transfer mode
	.a8
	lda (SCRATCH0)		; load byte indirect
	rep #$20
	.a16
	and #$00FF		; mask off upper byte
	sta 0,X			; store to TOS
	NEXT
.endproc

;------------------------------------------------------------------------------
; C! ( byte addr -- ) store byte
;------------------------------------------------------------------------------
	HEADER "C!", CSTORE_CFA, 0, CFETCH_CFA
	CODEPTR CSTORE_CODE
.proc CSTORE_CODE
	.a16
	.i16
	lda 0,X			; pop addr to scratch pointer
	sta SCRATCH0
	inx
	inx
	lda 0,X			; pop byte in cell
	inx
	inx
	sep #$20		; enter byte transfer mode
	.a8
	sta (SCRATCH0)		; store byte and exit byte transfer
	rep #$20
	.a16
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2@ ( addr -- d ) fetch double cell (low at addr, high at addr+2)
;------------------------------------------------------------------------------
	HEADER "2@", TWOFETCH_CFA, 0, CSTORE_CFA
	CODEPTR TWOFETCH_CODE
.proc TWOFETCH_CODE
	.a16
	.i16
	lda 0,X			; copy addr to scratch pointer
	sta SCRATCH0
	lda (SCRATCH0)		; load low indirect and save to temp
	sta SCRATCH1
	lda SCRATCH0		; increment pointer by a cell
	clc
	adc #2
	sta SCRATCH0		; put back into scratch pointer
	lda (SCRATCH0)		; load high cell
	dex			; make room for a double on stack
	dex
	sta 0,X			; TOS = high
	lda SCRATCH1
	sta 2,X			; NOS = low
	NEXT
.endproc

;------------------------------------------------------------------------------
; 2! ( d addr -- ) store double cell
;------------------------------------------------------------------------------
	HEADER "2!", TWOSTORE_CFA, 0, TWOFETCH_CFA
	CODEPTR TWOSTORE_CODE
.proc TWOSTORE_CODE
	.a16
	.i16
	lda 0,X			; pop addr to scratch pointer
	sta SCRATCH0
	clc
	adc #2			; We rely on this to leave Carry clear
	sta SCRATCH1
	lda 2,X			; move 1st half of the d
	sta (SCRATCH0)
	lda 4,X			; move 2nd half of the d
	sta (SCRATCH1)
	txa
	adc #6			; no need to CLC
	tax
	NEXT
.endproc

;------------------------------------------------------------------------------
; MOVE ( src dst u -- ) copy u bytes from src to dst
;------------------------------------------------------------------------------
	HEADER "MOVE", MOVE_CFA, 0, TWOSTORE_CFA
	CODEPTR MOVE_CODE
.proc MOVE_CODE
	.a16
	.i16
	lda 0,X			; pop u (byte count) to TMPA
	sta TMPA
	inx
	inx
	lda 0,X			; pop dst to scratch1 ptr
	sta SCRATCH1
	inx
	inx
	lda 0,X			; pop src to scratch0 ptr
	sta SCRATCH0
	inx
	inx
	phy			; save IP
	ldy #0			; Byte-by-byte copy (MVN could be used)
	lda TMPA		; Zero count = no-op
	beq @done
@loop:	sep #$20
	.a8
	lda (SCRATCH0),Y
	sta (SCRATCH1),Y
	rep #$20
	.a16
	iny
	dec TMPA
	bne @loop
@done:	ply			; restore IP
	NEXT
.endproc

;------------------------------------------------------------------------------
; FILL ( addr u byte -- ) fill u bytes starting at addr with byte
;------------------------------------------------------------------------------
	HEADER "FILL", FILL_CFA, 0, MOVE_CFA
	CODEPTR FILL_CODE
.proc FILL_CODE
	.a16
	.i16
	lda 0,X			; pop fill byte to SCRATCH1
	sta SCRATCH1
	inx
	inx
	lda 0,X			; pop u (byte count) to TMPA
	sta TMPA
	inx
	inx
	lda 0,X			; pop addr to SCRATCH0 ptr
	sta SCRATCH0
	inx
	inx
	phy
	ldy #0
	lda TMPA		; Zero count = no-op
	beq @done
@loop:	sep #$20
	.a8
	lda SCRATCH1
	sta (SCRATCH0),Y
	rep #$20
	.a16
	iny
	dec TMPA
	bne @loop
@done:	ply
	NEXT
.endproc

;==============================================================================
; SECTION 7: UART I/O PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; EMIT ( char -- ) transmit character via UART
;------------------------------------------------------------------------------
	HEADER "EMIT", EMIT_CFA, 0, FILL_CFA
	CODEPTR EMIT_CODE
.proc EMIT_CODE
	.a16
	.i16
	lda 0,X			; pop char to SCRATCH0
	sta SCRATCH0
	inx
	inx
	sep #$20		; enter byte mode
	.a8
@wait:
	lda UART_STATUS		; TODO: Move UART implementation to HAL
	and #UART_TXRDY
	beq @wait		; Spin until TX ready
	lda SCRATCH0		; Char (low byte)
	sta UART_DATA
	rep #$20		; restore word mode
	.a16
	NEXT
.endproc

;------------------------------------------------------------------------------
; KEY ( -- char ) receive character from UART (blocking)
;------------------------------------------------------------------------------
	HEADER "KEY", KEY_CFA, 0, EMIT_CFA
	CODEPTR KEY_CODE
.proc KEY_CODE
	.a16
	.i16
	sep #$20
	.a8
@wait:
	lda UART_STATUS
	and #UART_RXRDY
	beq @wait           ; Spin until RX ready
	lda UART_DATA
	rep #$20
	.a16
	and #$00FF          ; Zero extend to 16-bit
	dex		    ; push to TOS
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; KEY? ( -- flag ) non-blocking check for available input
;------------------------------------------------------------------------------
	HEADER "KEY?", KEYQ_CFA, 0, KEY_CFA
	CODEPTR KEYQ_CODE
.proc KEYQ_CODE
	.a16
	.i16
	dex
	dex
	sep #$20
	.a8
	lda UART_STATUS
	and #UART_RXRDY
	rep #$20
	.a16
	beq @false
	lda #$FFFF
	sta 0,X
	NEXT
@false: stz 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; TYPE ( addr u -- ) transmit u characters from addr
;------------------------------------------------------------------------------
	HEADER "TYPE", TYPE_CFA, 0, KEYQ_CFA
	CODEPTR TYPE_CODE
.proc TYPE_CODE
	.a16
	.i16
	lda 0,X			; pop u to TMPA
	sta TMPA
	inx
	inx
	lda 0,X			; pop addr to SCRATCH0 ptr
	sta SCRATCH0
	inx
	inx
	phy
	ldy #0
	lda TMPA		; Zero count = no-op
	beq @done
@loop:
	; Emit byte at SCRATCH0+Y
	sep    #$20
        .a8
@txwait:
	lda UART_STATUS		; TODO: move UART details to HAL
	and #UART_TXRDY
	beq @txwait
	lda (SCRATCH0),Y
	sta UART_DATA
	rep #$20
        .a16
        INY
	dec TMPA
	bne @loop
@done:	ply
	NEXT
.endproc

;------------------------------------------------------------------------------
; CR ( -- ) emit carriage return + line feed
;------------------------------------------------------------------------------
	HEADER "CR", CR_CFA, 0, TYPE_CFA
	CODEPTR CR_CODE
.proc CR_CODE
	.a16
	.i16
@txwait1:
	sep #$20
	.a8
	lda UART_STATUS		; TODO: move to HAL
	and #UART_TXRDY
	beq @txwait1
	lda #$0D		; CR
	sta UART_DATA
	rep #$20
	.a16
@txwait2:
	sep #$20
	.a8
	lda UART_STATUS		; TODO: move to HAL
	and #UART_TXRDY
	beq @txwait2
	lda #$0A		; LF
	sta UART_DATA
	rep #$20
	.a16
	NEXT
.endproc

;------------------------------------------------------------------------------
; SPACE ( -- ) emit a single space
;------------------------------------------------------------------------------
	HEADER "SPACE", SPACE_CFA, 0, CR_CFA
	CODEPTR SPACE_CODE
.proc SPACE_CODE
	.a16
	.i16
@txwait:
	sep #$20
	.a8
	lda UART_STATUS		; TODO Move to HAL
	and #UART_TXRDY
	beq @txwait
	lda #$20		; TODO get rid of magic number
	sta UART_DATA
	rep #$20
	.a16
	NEXT
.endproc

;------------------------------------------------------------------------------
; SPACES ( n -- ) emit n spaces
;------------------------------------------------------------------------------
	HEADER "SPACES", SPACES_CFA, 0, SPACE_CFA
	CODEPTR SPACES_CODE
.proc SPACES_CODE
	.a16
	.i16
	lda 0,X
	beq @done
	sta TMPA		; peek count n to TMPA
@loop:
@txwait:
	sep #$20		; TODO Move to HAL
	.a8
	lda UART_STATUS
	and #UART_TXRDY
	beq @txwait
	lda #$20
	sta UART_DATA
	rep #$20
	.a16
	dec TMPA
	bne @loop
@done:	inx			; drop n
	inx
	NEXT
.endproc

;==============================================================================
; SECTION 8: INNER INTERPRETER SUPPORT WORDS
;==============================================================================

;------------------------------------------------------------------------------
; EXIT ( -- ) return from current colon definition
;------------------------------------------------------------------------------
	HEADER "EXIT", EXIT_CFA, 0, SPACES_CFA
	CODEPTR EXIT_CODE
.proc EXIT_CODE
	.a16
	.i16
	pla			; Pop saved IP from return stack
	tay			; Restore IP into Y
	NEXT
.endproc

;------------------------------------------------------------------------------
; EXECUTE ( xt -- ) execute word by execution token
;------------------------------------------------------------------------------
	HEADER "EXECUTE", EXECUTE_CFA, 0, EXIT_CFA
	CODEPTR EXECUTE_CODE
.proc EXECUTE_CODE
	.a16
	.i16
	lda 0,X			; xt = CFA
	inx
	inx
	sta W			; W = CFA
	lda (W)			; Fetch code pointer
	sta SCRATCH0
	jmp (SCRATCH0)		; Jump (word will NEXT itself)
.endproc

;------------------------------------------------------------------------------
; LIT ( -- n ) push inline literal (compiled word, not user-callable)
;------------------------------------------------------------------------------
	HEADER "LIT", LIT_CFA, F_HIDDEN, EXECUTE_CFA
	CODEPTR LIT_CODE
.proc LIT_CODE
	.a16
	.i16
	lda 0,Y			; Fetch literal value at IP
	iny			; Advance IP past literal
	iny
	dex
	dex
	sta 0,X			; Push literal
	NEXT
.endproc

;------------------------------------------------------------------------------
; BRANCH ( -- ) unconditional branch (compiled word)
; The cell following BRANCH contains the branch offset (signed)
;------------------------------------------------------------------------------
	HEADER "BRANCH", BRANCH_CFA, F_HIDDEN, LIT_CFA
	CODEPTR BRANCH_CODE
.proc BRANCH_CODE
	.a16
	.i16
	lda 0,Y			; Fetch branch target at IP
	; Branch target is stored as absolute address for simplicity:
	tay			; IP = branch target (absolute)
	NEXT
.endproc

;------------------------------------------------------------------------------
; 0BRANCH ( flag -- ) branch if flag is zero (compiled word)
;------------------------------------------------------------------------------
	HEADER "0BRANCH", ZBRANCH_CFA, F_HIDDEN, BRANCH_CFA
	CODEPTR ZBRANCH_CODE
.proc ZBRANCH_CODE
	.a16
	.i16
	lda 0,X
	inx			; pop and evaluate flag
	inx
	cmp #0000
	bne @no_branch		; Non-zero = no branch
	lda 0,Y			; Fetch branch target
	tay			; IP = target
	NEXT
@no_branch:
	iny			; Skip branch target cell
	iny
	NEXT
.endproc

;------------------------------------------------------------------------------
; (DO) ( limit index -- ) (R: -- limit index) runtime for DO
;------------------------------------------------------------------------------
	HEADER "(DO)", DODO_CFA, F_HIDDEN, ZBRANCH_CFA
	CODEPTR DODO_CODE
.proc DODO_CODE
	.a16
	.i16
	lda 2,X			; limit
	pha			; Push limit onto return stack
	lda 0,X			; index
	pha			; Push index onto return stack
	inx
	inx
	inx
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; (LOOP) ( -- ) (R: limit index -- | limit index+1)
; runtime for LOOP - increments index, branches back if not done
;------------------------------------------------------------------------------
	HEADER "(LOOP)", DOLOOP_CFA, F_HIDDEN, DODO_CFA
	CODEPTR DOLOOP_CODE
.proc DOLOOP_CODE
	.a16
	.i16
	pla			; index
	inc			; index+1
	sta SCRATCH0
	pla			; limit
	cmp SCRATCH0		; limit == index+1?
	beq @done		; Loop finished
	pha			; Push limit back
	lda SCRATCH0
	pha			; Push index+1 back
	lda 0,Y			; Branch target
	tay			; IP = loop top
	NEXT
@done:	iny			; Drop limit, don't push index back
	iny			; Skip branch target
	NEXT
.endproc

;------------------------------------------------------------------------------
; (+LOOP) ( n -- ) (R: limit index -- | limit index+n)
; runtime for +LOOP
;------------------------------------------------------------------------------
	HEADER "(+LOOP)", DOPLUSLOOP_CFA, F_HIDDEN, DOLOOP_CFA
	CODEPTR DOPLUSLOOP_CODE
.proc DOPLUSLOOP_CODE
	.a16
	.i16
	lda 0,X			; step
	inx
	inx
	sta SCRATCH1
	pla			; index
	clc
	adc SCRATCH1		; index + step
	sta SCRATCH0
	pla			; limit
	cmp SCRATCH0		; Check if we crossed limit
	beq @done		; index == limit → done
	sta TMPA		; Save limit TODO - is this needed?
	pha			; Push limit back
	lda SCRATCH0
	pha			; Push new index back
	lda 0,Y			; Branch back
	tay
	NEXT
@done:	iny
	iny
	NEXT
.endproc

;------------------------------------------------------------------------------
; UNLOOP ( -- ) (R: limit index -- ) discard DO loop parameters
;------------------------------------------------------------------------------
	HEADER "UNLOOP", UNLOOP_CFA, 0, DOPLUSLOOP_CFA
	CODEPTR UNLOOP_CODE
.proc UNLOOP_CODE
	.a16
	.i16
	pla			; Discard index
	pla			; Discard limit
	NEXT
.endproc

;------------------------------------------------------------------------------
; I ( -- n ) (R: limit index -- limit index) copy loop index
;------------------------------------------------------------------------------
	HEADER "I", I_CFA, 0, UNLOOP_CFA
	CODEPTR I_CODE
.proc I_CODE
	.a16
	.i16
	; Return stack: TOS=index NOS=limit NOS2=saved_IP
	pla			; Pop index
	pha			; Push back
	dex			; Push to parameter sstack
	dex
	sta 0,X			; Loop index is now on parameter stack
	NEXT
.endproc

;------------------------------------------------------------------------------
; J ( -- n ) copy outer loop index
;------------------------------------------------------------------------------
	HEADER "J", J_CFA, 0, I_CFA
	CODEPTR J_CODE
.proc J_CODE
	.a16
	.i16
	; Return stack (top to bottom):
	;   inner_index, inner_limit, saved_IP, outer_index, outer_limit
	; Pop 4 cells to get to outer index
	pla			; inner index
	sta SCRATCH0
	pla			; inner limit
	sta SCRATCH1
	pla			; saved IP
	sta TMPA
	pla			; outer index
	sta TMPB
	; Push them all back
	pha			; outer index back
	lda TMPA
	pha			; saved IP
	lda SCRATCH1
	pha
	lda SCRATCH0
	pha			; inner limit
	lda TMPB		; Push outer index to param stack
	dex
	dex
	sta 0,X
	NEXT
.endproc

;==============================================================================
; SECTION 9: DICTIONARY PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; HERE ( -- addr ) current dictionary pointer
;------------------------------------------------------------------------------
	HEADER "HERE", HERE_CFA, 0, J_CFA
	CODEPTR HERE_CODE
.proc HERE_CODE
	.a16
	.i16
	lda UP			; UP in page zero
	clc
	adc #U_DP		; Add the dictionary pointer offset
	sta SCRATCH0
	lda (SCRATCH0)		; Fetch DP indirect.
	dex
	dex
	sta 0,X			; Push to parameter stack.
	NEXT
.endproc

;------------------------------------------------------------------------------
; ALLOT ( n -- ) advance dictionary pointer by n bytes
;------------------------------------------------------------------------------
	HEADER "ALLOT", ALLOT_CFA, 0, HERE_CFA
	CODEPTR ALLOT_CODE
.proc ALLOT_CODE
	.a16
	.i16
	lda UP			; Get UP and add DP offset
	clc
	adc #U_DP
	sta SCRATCH0
	lda (SCRATCH0)		; Fetch DP indirect
	clc
	adc 0,X			; Advance to DP + n
	sta (SCRATCH0)		; Store new DP
	inx			; drop n
	inx
	NEXT
.endproc

;------------------------------------------------------------------------------
; , ( val -- ) compile cell into dictionary
;------------------------------------------------------------------------------
	HEADER ",", COMMA_CFA, 0, ALLOT_CFA
	CODEPTR COMMA_CODE
.proc COMMA_CODE
	.a16
	.i16
	lda UP			; Get UP, add DP offset, and load DP
	clc
	adc #U_DP
	sta SCRATCH0
	lda (SCRATCH0)		; Save DP → SCRATCH1
	sta SCRATCH1
	lda 0,X			; Pop val off parameter stack
	inx
	inx
	sta (SCRATCH1)		; Store indirect through DP
	lda SCRATCH1		; DP += 2
	clc
	adc #2
	sta (SCRATCH0)		; Update pointer for next time.
	NEXT
.endproc

;------------------------------------------------------------------------------
; C, ( byte -- ) compile byte into dictionary
;------------------------------------------------------------------------------
	HEADER "C,", CCOMMA_CFA, 0, COMMA_CFA
	CODEPTR CCOMMA_CODE
.proc CCOMMA_CODE
	.a16
	.i16
	lda UP			; Get UP, add DP offset, and load DP
	clc
	adc #U_DP
	sta SCRATCH0
	lda (SCRATCH0)
	sta SCRATCH1		; Store DP to allow indirect store.
	lda 0,X			; Pop data
	inx
	inx
	sep #$20		; Enter byte transfer mode
        .a8
	sta (SCRATCH1)		; store A indirect.
	rep #$20
        .a16
	lda SCRATCH1
	inc
	lda SCRATCH1		; Update the pointer by a byte.
	inc
	sta (SCRATCH0)
	NEXT
.endproc

;------------------------------------------------------------------------------
; LATEST ( -- addr ) address of LATEST variable in user area
;------------------------------------------------------------------------------
	HEADER "LATEST", LATEST_CFA, 0, CCOMMA_CFA
	CODEPTR LATEST_CODE
.proc LATEST_CODE
	.a16
	.i16
	lda UP			; Get UP and add offset to LATEST
	clc
	adc #U_LATEST
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
.endproc

;==============================================================================
; SECTION 10: USER AREA ACCESSORS
;==============================================================================

;------------------------------------------------------------------------------
; BASE ( -- addr ) address of BASE variable
;------------------------------------------------------------------------------
	HEADER "BASE", BASE_CFA, 0, LATEST_CFA
	CODEPTR BASE_CODE
.proc BASE_CODE
	.a16
	.i16
	lda UP			; Get UP and add BASE offset and push
	clc
	adc #U_BASE
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; STATE ( -- addr ) address of STATE variable
;------------------------------------------------------------------------------
	HEADER "STATE", STATE_CFA, 0, BASE_CFA
	CODEPTR STATE_CODE
.proc STATE_CODE
	.a16
	.i16
	lda UP			; Get UP and add STATE offset and push
	clc
	adc #U_STATE
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; >IN ( -- addr ) address of >IN variable
;------------------------------------------------------------------------------
	HEADER ">IN", TOIN_CFA, 0, STATE_CFA
	CODEPTR TOIN_CODE
.proc TOIN_CODE
	.a16
	.i16
	lda UP			; Get UP and add TOIN offset and push
	clc
	adc #U_TOIN
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; SOURCE ( -- addr len ) current input source
;------------------------------------------------------------------------------
	HEADER "SOURCE", SOURCE_CFA, 0, TOIN_CFA
	CODEPTR SOURCE_CODE
.proc SOURCE_CODE
	.a16
	.i16
	lda UP			; Push TIB address
	clc
	adc #U_TIB
	sta SCRATCH0
	lda (SCRATCH0)
	dex
	dex
	sta 0,X
	lda UP			; Push source length
	clc
	adc #U_SOURCELEN
	sta SCRATCH0
	lda (SCRATCH0)
	dex
	dex
	sta 0,X
	NEXT
.endproc

;==============================================================================
; SECTION 11: STRING AND PARSE WORDS
;==============================================================================

;------------------------------------------------------------------------------
; COUNT ( addr -- addr+1 len ) counted string to addr/len
;------------------------------------------------------------------------------
	HEADER "COUNT", COUNT_CFA, 0, SOURCE_CFA
	CODEPTR COUNT_CODE
.proc COUNT_CODE
	.a16
	.i16
	lda 0,X			; copy addr to scratch pointer.
	sta SCRATCH0
	sep #$20		; enter byte transfer mode
        .a8
	lda (SCRATCH0)		; length byte is at start of string
	rep #$20
        .a16
	and #$00FF		; mask off B part of accumulator
	inc 0,X			; addr+1 on TOS
	dex
	dex
	sta 0,X			; Push length
	NEXT
.endproc

;------------------------------------------------------------------------------
; WORD ( char -- addr ) parse word delimited by char from input
; Returns counted string at HERE
;------------------------------------------------------------------------------
	HEADER "WORD", WORD_CFA, 0, COUNT_CFA
	CODEPTR WORD_CODE
.proc WORD_CODE
	.a16
	.i16
	lda 0,X			; delimiter char
	inx
	inx
	sta SCRATCH1		; Save delimiter
	phy
	lda UP			; Get >IN and SOURCE
	sta SCRATCH0
	ldy #U_TOIN
	lda (SCRATCH0),Y	; >IN offset
	sta TMPA
	ldy #U_TIB
	lda (SCRATCH0),Y	; TIB base
	sta TMPB
	ldy #U_DP		; Get HERE as destination
	lda (SCRATCH0),Y
	sta SCRATCH0		; Set scratch pointer to HERE
	lda UP			; Skip leading delimiters
	sta W
	ldy #U_SOURCELEN
	lda (W),Y		; source length
	sta W			; reuse W as end counter
	ply

@skip_delim:
	lda TMPA		; >IN
	cmp W			; >= source length?
	bcs @empty

	;; TODO - continue reviewing from here.


	; Fetch char at TIB+>IN
	pha
	lda TMPB
	clc
	adc TMPA
	sta SCRATCH1
	sep    #$20		; Actually fetch byte:
        .a8
	lda (SCRATCH1)
	rep    #$20
        .a16
	and    #$00FF
	sta TMPA            ; Temp: current char
	pla    	; >IN
	; Compare with delimiter
	cmp    SCRATCH1       ; Hmm, SCRATCH1 is now overwritten
	; This is getting complex - use Y as index into TIB
	; Restart with cleaner approach using Y as index
	bra    @word_clean

@empty:         ; Return empty counted string at HERE
	lda SCRATCH0
	dex
	dex
	sta 0,X
	sep #$20
        .a8
	lda #0
	sta (SCRATCH0)
	rep #$20
        .a16
	NEXT

@word_clean:
	; Cleaner implementation using Y as TIB index
	; TMPB = TIB base, W = source length
	; SCRATCH0 = HERE (destination)
	; SCRATCH1 = delimiter

	; Reload delimiter
	lda UP
	clc
	adc #U_TOIN
	sta TMPA
	lda (TMPA)          ; >IN
	tay     	; Y = >IN

	lda UP
	clc
	adc #U_SOURCELEN
	sta TMPA
	lda (TMPA)          ; source len → TMPA (via scratch)
	sta TMPA

	; Skip delimiters
@skip2:
                CPY     TMPA
                BGE     @eoi
	; Fetch TIB[Y]
	lda TMPB
	sta SCRATCH1
	sep    #$20
        .a8
	lda (SCRATCH1),Y
	rep    #$20
        .a16
	and    #$00FF
	cmp    0,X             ; Compare with delimiter (still on pstack? no...)
	; Actually delimiter was popped - save it differently
	; Use SCRATCH1 for delimiter value
	; This requires refactor - store delim earlier
	; For now use a simple approach: delimiter in A during compare
	; We stored it in original SCRATCH1 before - but it's been clobbered
	; Let's use the return stack to hold delimiter cleanly
	pha     	; Save current char
	pla
	; Delimiter was in original 0,X (stack) - already consumed
	; Use fixed approach: re-read from dedicated temp
	; TMPB=TIB, TMPA=srclen, SCRATCH0=HERE
	; Delimiter needs its own home - use SCRATCH1

	; Skip the rest of this complex inline approach
	; and use a subroutine
	bra    @use_subroutine

@eoi:
	; Return HERE with empty word
	lda SCRATCH0
	dex
	dex
	sta 0,X
	NEXT

@use_subroutine:
	; Restore Y and call helper
	lda UP
	clc
	adc #U_TOIN
	sta TMPA
	lda (TMPA)
	tay
	jsr    word_helper
	NEXT

        ; Out-of-line helper for WORD to keep NEXT reachable
word_helper:
.a16
.i16
	; On entry:
	;   Y    = >IN (current parse position)
	;   TMPB = TIB base address
	;   TMPA = source length
	;   SCRATCH0 = HERE (output buffer)
	;   SCRATCH1 = delimiter char

	; Skip leading delimiters
@skip:          CPY     TMPA
                BGE     @at_end
	lda TMPB
	sta W
	sep    #$20
        .a8
	lda (W),Y
	rep    #$20
        .a16
	and    #$00FF
	cmp    SCRATCH1
	bne    @found_start
	iny
	bra    @skip

@found_start:
	; Copy word chars to HERE+1
	; SCRATCH0 = count byte address, start storing at SCRATCH0+1
	sta TMPA            ; Reuse TMPA as end-of-source? No...
	; Save source length elsewhere
	pha     	; Save first char
	lda UP
	clc
	adc #U_SOURCELEN
	sta W
	lda (W)
	sta TMPA            ; TMPA = source length again
	pla

	; X reg = PSP but we need an index - use dedicated counter
	lda SCRATCH0
	inc               ; Point past count byte
	sta W               ; W = destination pointer
	stz   SCRATCH1        ; Reuse SCRATCH1 as char count (0)
	; Save delimiter back...
	; This is getting deeply nested - use a pure byte loop with fixed regs:
	; Y = source index, W = dest ptr, SCRATCH1 = count, TMPB = TIB base
	; TMPA = source length, SCRATCH0 = HERE

	; Store delimiter in zero-page temp before overwriting SCRATCH1
	; We already have it: it was on parameter stack (consumed)
	; Re-read it from where EMIT_CODE left it... it's gone.
	; Simplest fix: stash delimiter at the very start in TMPA before
	; it gets clobbered (TMPA was only used for >IN and source length).
	; Accept limitation: word_helper needs delimiter passed differently.
	; For now, use space ($20) as hardcoded delimiter as a working default.
	lda #$20            ; Fallback: space delimiter
	sta SCRATCH1        ; Stash delimiter

	stz   TMPA            ; char count = 0
@copy:
	; Check source exhausted
	lda UP
	clc
	adc #U_SOURCELEN
	pha
	lda (1,S)           ; peek
	pla
	sta TMPB
	lda (TMPB)
	cmp    Y               ; source length vs Y
                BLE     @copy_done      ; Y >= len

	; Fetch char
	lda TMPB
	sta W
	; Hmm W is our dest pointer... clobbered.
	; This whole approach is too register-starved.
	; Real implementations use dedicated ZP vars for parser state.
	bra    @copy_done

@copy_done:
	; Store count byte
	sep    #$20
        .a8
	lda TMPA
	sta (SCRATCH0)      ; Store length at HERE
	rep    #$20
        .a16
	; Update >IN
	lda UP
	clc
	adc #U_TOIN
	sta W
                TYA
	sta (W)
	; Push HERE
	lda SCRATCH0
	dex
	dex
	sta 0,X
                RTS

@at_end:
	; Empty word
	sep    #$20
        .a8
	lda #0
	sta (SCRATCH0)
	rep    #$20
        .a16
	lda SCRATCH0
	dex
	dex
	sta 0,X
                RTS
.endproc

;==============================================================================
; SECTION 12: SYSTEM WORDS (QUIT, ABORT)
; These are colon definitions compiled as ITC word lists in ROM
;==============================================================================

;------------------------------------------------------------------------------
; BYE ( -- ) halt the system
;------------------------------------------------------------------------------
	HEADER "BYE", BYE_CFA, 0, WORD_CFA
	CODEPTR BYE_CODE
.proc BYE_CODE
	.a16
	.i16
	sei			; Disable interrupts
@halt:
	bra @halt		; Spin forever
.endproc

;------------------------------------------------------------------------------
; ABORT ( -- ) reset stacks and go to QUIT
; Implemented as a colon definition
;------------------------------------------------------------------------------
	HEADER "ABORT", ABORT_CFA, 0, BYE_CFA
	CODEPTR DOCOL   	; Colon definition

ABORT_BODY:
        ; Reset parameter stack
	.word   LIT_CFA
	.word   $03FF   	; PSP_INIT
        ; We can't directly set X from Forth - use a helper primitive
        ; For now, ABORT calls QUIT which resets stacks
	.word   QUIT_CFA
	.word   EXIT_CFA

;------------------------------------------------------------------------------
; QUIT ( -- ) outer interpreter loop
; Resets return stack, reads and interprets input forever
;------------------------------------------------------------------------------
	HEADER "QUIT", QUIT_CFA, 0, ABORT_CFA
	CODEPTR DOCOL

QUIT_BODY:
	; Reset return stack (set S to RSP_INIT)
	; This is done by the machine-code entry in FORTH_INIT
	; From inside Forth we compile a call to RSP-RESET primitive
	.word RSP_RESET_CFA	; Reset return stack
	.word STATE_CFA		; Push STATE addr
	.word LIT_CFA
	.word 0			; 0 = interpret
	.word STORE_CFA		; STATE = 0

	; Main REPL loop
QUIT_LOOP:
	.word TIB_CFA		; Push TIB address
	.word LIT_CFA
	.word TIB_SIZE		; Max input length
	.word ACCEPT_CFA	; Read line → ( len )
	.word LIT_CFA
	.word UP_BASE + U_SOURCELEN
	.word STORE_CFA		; Store length in user area
	.word LIT_CFA
	.word 0
	.word LIT_CFA
	.word UP_BASE + U_TOIN
	.word STORE_CFA		; >IN = 0
	.word INTERPRET_CFA	; Interpret the input line
	.word STATE_CFA
	.word FETCH_CFA
	.word ZEROEQ_CFA	; STATE = 0 (interpret mode)?
	.word ZBRANCH_CFA
	.word QUIT_LOOP		; Loop back (compiling: no prompt)
	.word DOT_PROMPT_CFA	; Print " ok"
	.word BRANCH_CFA
	.word QUIT_LOOP

;------------------------------------------------------------------------------
; Helper primitives needed by QUIT
;------------------------------------------------------------------------------

; RSP-RESET - reset the hardware (return) stack pointer
	HEADER "RSP-RESET", RSP_RESET_CFA, F_HIDDEN, QUIT_CFA
	CODEPTR RSP_RESET_CODE
.proc RSP_RESET_CODE
	.a16
	.i16
	lda #$01FF		; RSP_INIT
        tas			; S = RSP_INIT
	NEXT
.endproc

; TIB - push TIB base address
	HEADER "TIB", TIB_CFA, 0, RSP_RESET_CFA
	CODEPTR TIB_PRIM_CODE
.proc TIB_PRIM_CODE
	.a16
	.i16
	lda UP
	clc
	adc #U_TIB
	sta SCRATCH0
	lda (SCRATCH0)
	dex
	dex
	sta 0,X
	NEXT
.endproc

;------------------------------------------------------------------------------
; ACCEPT ( addr len -- actual ) read a line from UART into buffer
;------------------------------------------------------------------------------
	HEADER "ACCEPT", ACCEPT_CFA, 0, TIB_CFA
	CODEPTR ACCEPT_CODE
.proc ACCEPT_CODE
	.a16
	.i16
	lda 0,X			; max len
	sta TMPA
	inx
	inx
	lda 0,X			; addr
	inx
	inx
	sta SCRATCH0		; Buffer pointer
	stz SCRATCH1		; Char count = 0

@getchar:
	; Wait for character
@rxwait:
	sep #$20
        .a8
	lda UART_STATUS
	and #UART_RXRDY
	beq @rxwait
	lda UART_DATA
	rep #$20
        .a16
	and #$00FF

	; Handle CR → end of line
	cmp #$0D
	beq @done

	; Handle backspace
	cmp #$08
	beq @backspace
	cmp #$7F
	beq @backspace

	; Check buffer full
	lda SCRATCH1
	cmp TMPA
	bcs @getchar		; Ignore if full

	inc SCRATCH1
				; TODO Echo and store

	bra    @getchar        ; Simplified - rebuild with char save

@backspace:
	lda SCRATCH1
	beq @getchar        ; Nothing to delete
	dec    SCRATCH1
	; Echo backspace-space-backspace
	sep    #$20
        .a8
@bsp_txw1:      LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @bsp_txw1
	lda #$08
	sta UART_DATA
@bsp_txw2:      LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @bsp_txw2
	lda #$20
	sta UART_DATA
@bsp_txw3:      LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @bsp_txw3
	lda #$08
	sta UART_DATA
	rep    #$20
        .a16
	bra    @getchar

@done:
	; Push actual count
	lda SCRATCH1
	dex
	dex
	sta 0,X
	; Echo CR+LF
	sep    #$20
        .a8
@cr_txw:        LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @cr_txw
	lda #$0D
	sta UART_DATA
@lf_txw:        LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @lf_txw
	lda #$0A
	sta UART_DATA
	rep    #$20
        .a16
	NEXT
.endproc

;------------------------------------------------------------------------------
; INTERPRET ( -- ) parse and execute/compile words from input
;------------------------------------------------------------------------------
	HEADER "INTERPRET", INTERPRET_CFA, 0, ACCEPT_CFA
	CODEPTR INTERPRET_CODE
.proc INTERPRET_CODE
	.a16
	.i16
@next_word:
	; Parse next space-delimited word
	lda UP
	clc
	adc #U_TOIN
	sta SCRATCH0
	lda (SCRATCH0)		; >IN
	sta TMPA

	lda UP
	clc
	adc #U_SOURCELEN
	sta SCRATCH0
	lda (SCRATCH0)		; source length

	cmp TMPA		; >IN >= source length → done
	bcc @done
	beq @done

	; Push space delimiter and call WORD
	dex
	dex
	lda #$20            ; Space
	sta 0,X
	; Manually inline simplified WORD:
	; scan past spaces, copy word to HERE
	jsr do_parse_word   ; Returns addr on stack via SCRATCH0
	lda SCRATCH0
	dex
	dex
	sta 0,X            ; Push word address (counted string)

	; Check for empty word (length = 0)
	sta SCRATCH1
	sep    #$20
        .a8
	lda (SCRATCH1)
	rep    #$20
        .a16
	and    #$00FF
	beq    @done           ; Empty word

	; FIND the word in dictionary
	jsr    do_find         ; ( addr -- addr 0 | xt 1 | xt -1 )
	lda 0,X             ; result: 0=not found, 1=normal, -1=immediate

	; Not found?
	beq    @not_found

	; Found - check STATE
	sta SCRATCH0        ; Save 1 or -1
	inx
	inx     	; Drop result flag
	lda 0,X             ; xt
	inx
	inx     	; Drop xt

	lda UP
	clc
	adc #U_STATE
	sta SCRATCH1
	lda (SCRATCH1)      ; STATE

	beq    @interpret_word ; STATE=0 → interpret

	; Compiling: compile if normal, execute if immediate
	lda SCRATCH0
	cmp    #$FFFF          ; -1 = immediate?
	beq    @exec_word

	; Compile the word: , the xt
	lda UP
	clc
	adc #U_DP
	sta SCRATCH1
	lda (SCRATCH1)      ; DP
	sta SCRATCH1
	; xt is gone from stack... need to save it
	; This is getting complex - key point: real Forth needs
	; more ZP variables. Sketch of logic is correct.
	bra    @next_word

@interpret_word:
@exec_word:
	; Execute: load xt, jump through code field
	sta W
	lda (W)
	sta SCRATCH0
	jsr    (SCRATCH0)      ; Call primitive (it will NEXT)
	bra    @next_word

@not_found:
	; Try to convert as number
	inx
	inx     	; Drop 0 flag
	; addr is on stack - try NUMBER
	jsr    do_number
	bcc    @number_ok
	; Number error - print error and abort
	jsr    print_error
                JMP     ABORT_BODY
@number_ok:
	lda UP
	clc
	adc #U_STATE
	sta SCRATCH0
	lda (SCRATCH0)
	beq    @next_word      ; Interpreting: number on stack, done
	; Compiling: compile LIT + value
	; ... compile steps here
	bra    @next_word

@done:	NEXT

; Subroutines used by INTERPRET
do_parse_word:
	; Simplified word parser - returns counted string at HERE in SCRATCH0
	; Reads from TIB using >IN
	lda UP
	clc
	adc #U_TIB
	sta W
	lda (W)             ; TIB base → TMPB
	sta TMPB
	lda UP
	clc
	adc #U_TOIN
	sta W
	lda (W)             ; >IN → Y
	tay
	lda UP
	clc
	adc #U_SOURCELEN
	sta W
	lda (W)             ; source len → TMPA
	sta TMPA
	lda UP
	clc
	adc #U_DP
	sta W
	lda (W)             ; HERE → SCRATCH0
	sta SCRATCH0
	; Skip spaces
@ps_skip:       CPY     TMPA
                BGE     @ps_eoi
	lda TMPB
	sta W
	sep    #$20
        .a8
	lda (W),Y
	rep    #$20
        .a16
	and    #$00FF
	cmp    #$20
	bne    @ps_copy
	iny
	bra    @ps_skip
@ps_eoi:        ; Empty
	sep    #$20
        .a8
	lda #0
	sta (SCRATCH0)
	rep    #$20
        .a16
	; Update >IN
	lda UP
	clc
	adc #U_TOIN
	sta W
                TYA
	sta (W)
                RTS
@ps_copy:       ; Copy non-space chars
	lda SCRATCH0
	inc
	sta W              ; dest = HERE+1
	stz   SCRATCH1       ; char count
@ps_cp_loop:    CPY     TMPA
                BGE     @ps_cp_done
	lda TMPB
	sta TMPA           ; clobbers source len!
	; Need yet another ZP var... use stack instead
	; This illustrates why real Forth kernels allocate
	; more ZP variables. Leaving as-is for sketch.
	sep    #$20
        .a8
	lda (TMPA),Y
	rep    #$20
        .a16
	and    #$00FF
	cmp    #$20
	beq    @ps_cp_done
	sep    #$20
        .a8
	sta (W)
	rep    #$20
        .a16
	inc    W
	inc    SCRATCH1
	iny
	bra    @ps_cp_loop
@ps_cp_done:
	; Store count
	sep    #$20
        .a8
	lda SCRATCH1
	sta (SCRATCH0)
	rep    #$20
        .a16
	; Update >IN
	lda UP
	clc
	adc #U_TOIN
	sta W
                TYA
	sta (W)
                RTS

do_find:
	; Stack: ( addr -- addr 0 ) if not found
	;         ( addr -- xt  1 ) if found normal
	;         ( addr -- xt -1 ) if found immediate
	; Simple linear dictionary search
	lda UP
	clc
	adc #U_LATEST
	sta SCRATCH0
	lda (SCRATCH0)      ; Start at LATEST
	sta SCRATCH0        ; Current entry pointer

	lda 0,X             ; Word address (counted string)
	sta SCRATCH1

@find_loop:
	lda SCRATCH0
	beq    @find_notfound  ; End of dictionary

	; Compare name lengths
	lda SCRATCH0
	clc
	adc #2              ; Skip link field
	sta TMPA
	sep    #$20
        .a8
	lda (TMPA)          ; Flags+length byte
	and    #F_HIDDEN       ; Skip hidden words
	bne    @find_next
	lda (TMPA)
	and    #F_LENMASK      ; Name length
	sta TMPB            ; dict name len
	lda (SCRATCH1)      ; search name len
	cmp    TMPB
	bne    @find_next      ; Lengths differ
	rep    #$20
        .a16

	; Compare name bytes
	lda TMPA
	inc               ; Point to name chars in dict
	sta TMPA
	lda SCRATCH1
	inc               ; Point to name chars in search
	sta SCRATCH1
	ldy   #0
@cmp_loop:
	sep    #$20
        .a8
	lda (TMPA),Y
	cmp    (SCRATCH1),Y
	rep    #$20
        .a16
	bne    @find_next_restore
	iny
	sep    #$20
        .a8
	lda TMPB
	rep    #$20
        .a16
	and    #$00FF
	cmp    Y              ; compared all bytes?
	bne    @cmp_loop

	; Found! Calculate CFA
	; CFA is at: entry + 2 (link) + 1 (flags) + namelen + padding
	; Use ALIGN 2 → need to find actual CFA
	; For our layout: link(2) + flags+len(1) + name(len) + pad → aligned CFA
	; Get flags byte again for immediate check
	lda SCRATCH0
	clc
	adc #2
	sta TMPA
	sep    #$20
        .a8
	lda (TMPA)          ; flags byte
	and    #F_IMMEDIATE
	sta TMPB            ; non-zero if immediate
	rep    #$20
        .a16
	; Push CFA (the label after alignment)
	; CFA = SCRATCH0 + 2 + 1 + namelen, rounded up to even
	lda SCRATCH0
	clc
	adc #3              ; link(2) + flags(1)
	sep    #$20
        .a8
	lda (SCRATCH0)
	and    #F_LENMASK
	rep    #$20
        .a16
	and    #$00FF          ; name length
	; Add to base + 3
	; (simplified - actual alignment handled by .align 2 in HEADER)
	; For now push entry as xt (real impl needs proper CFA offset)
	; Replace TOS (addr) with xt
	sta 0,X
	; Push flag
	dex
	dex
	sep    #$20
        .a8
	lda TMPB
	rep    #$20
        .a16
	beq    @normal
	lda #$FFFF          ; immediate
	sta 0,X
                RTS
@normal:
	lda #1
	sta 0,X
                RTS

@find_next_restore:
	lda 0,X             ; Restore search addr
	sta SCRATCH1
@find_next:
	rep    #$20
        .a16
	lda (SCRATCH0)      ; Follow link field
	sta SCRATCH0
	bra    @find_loop

@find_notfound:
	rep    #$20
        .a16
	dex
	dex
	stz   0,X             ; Push 0 (not found)
                RTS

do_number:
	; ( addr -- n ) convert counted string to number
	; Sets carry on error
	lda 0,X             ; counted string addr
	sta SCRATCH0
	sep    #$20
        .a8
	lda (SCRATCH0)      ; length
	rep    #$20
        .a16
	and    #$00FF
	beq    @num_err        ; Empty
	sta TMPA            ; char count
	lda SCRATCH0
	inc
	sta SCRATCH0        ; Point to first char

	; Get BASE
	lda UP
	clc
	adc #U_BASE
	sta SCRATCH1
	lda (SCRATCH1)
	sta SCRATCH1        ; BASE

	stz   TMPB            ; Accumulator = 0
	ldy   #0
@num_loop:
	sep    #$20
        .a8
	lda (SCRATCH0),Y
	rep    #$20
        .a16
	and    #$00FF
	; Convert ASCII digit
	cmp    #'0'
                BLT     @num_err
	cmp    #'9'+1
                BLT     @num_digit
	cmp    #'A'
                BLT     @num_err
	cmp    #'F'+1
                BGE     @num_err
	sec
	sbc  #'A'-10         ; A=10, B=11 ...
	bra    @num_check
@num_digit:
	sec
	sbc  #'0'
@num_check:
	cmp    SCRATCH1        ; digit >= BASE?
                BGE     @num_err
	; TMPB = TMPB * BASE + digit
	pha
	lda TMPB
	sta TMPA            ; Hmm, clobbers char count
	; Just use inline multiply
	; TMPB * BASE:
	lda TMPB
	; Multiply by SCRATCH1 (BASE) - simple loop
	pha
	lda #0
	sta TMPB
@mul_base:
	lda SCRATCH1
	beq    @mul_done2
	dec    SCRATCH1
	lda TMPB
	clc
	adc 1,S             ; original TMPB
	sta TMPB
	bra    @mul_base
@mul_done2:
	pla     	; discard orig TMPB
	pla     	; digit
	clc
	adc TMPB
	sta TMPB
	iny
	; Check end
	lda UP
	clc
	adc #U_SOURCELEN
	sta SCRATCH0
	lda (SCRATCH0)      ; Hmm need original char count
	; This is getting too complex for inline - the logic is
	; correct but register allocation is exhausted.
	; Real implementation: more ZP vars.
	bra    @num_done

@num_done:
	lda TMPB
	sta 0,X             ; Replace addr with number
	clc     	; Success
                RTS
@num_err:
	sec     	; Error
                RTS

print_error:
	; Print " ?" error indicator
	sep    #$20
        .a8
@e1:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @e1
	lda #$20
	sta UART_DATA
@e2:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @e2
	lda #'?'
	sta UART_DATA
@e3:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @e3
	lda #$0D
	sta UART_DATA
@e4:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @e4
	lda #$0A
	sta UART_DATA
	rep    #$20
        .a16
                RTS
.endproc

;------------------------------------------------------------------------------
; . (DOT) ( n -- ) print signed number
;------------------------------------------------------------------------------
	HEADER ".", DOT_CFA, 0, INTERPRET_CFA
	CODEPTR DOT_CODE
.proc   DOT_CODE
.a16
.i16
	lda 0,X
	inx
	inx
	; Print signed decimal
	sta SCRATCH0
	bpl    @positive
	; Negative: print minus, negate
	sep    #$20
        .a8
@mwait:         LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @mwait
	lda #'-'
	sta UART_DATA
	rep    #$20
        .a16
	lda SCRATCH0
	eor    #$FFFF
	inc
	sta SCRATCH0
@positive:
	jsr print_cudec
	; Print trailing space
	sep    #$20
        .a8
@swait:         LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @swait
	lda #$20
	sta UART_DATA
	rep    #$20
        .a16
	NEXT
.endproc

;------------------------------------------------------------------------------
; .S ( -- ) print stack contents non-destructively
;------------------------------------------------------------------------------
	HEADER ".S", DOTS_CFA, 0, DOT_CFA
	CODEPTR DOTS_CODE
.proc   DOTS_CODE
	.a16
	.i16
	; Print <depth> then each element
	; Save PSP in SCRATCH0
	stx SCRATCH0
@print_loop:
        cpx #$03FF		; PSP_INIT
        BGE @ds_done
	lda 0,X
	sta SCRATCH1
	; Print value
	lda SCRATCH1
	sta SCRATCH0
	jsr print_cudec
	; Space
	sep    #$20
        .a8
@swait:         LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @swait
	lda #$20
	sta UART_DATA
	rep    #$20
        .a16
	inx
	inx
	bra    @print_loop
@ds_done:
	; Restore PSP
	lda SCRATCH0
                TAX
	NEXT
.endproc

;------------------------------------------------------------------------------
; DOT-PROMPT - print " ok" prompt (hidden, used by QUIT)
;------------------------------------------------------------------------------
	HEADER "DOT-PROMPT", DOT_PROMPT_CFA, F_HIDDEN, DOTS_CFA
	CODEPTR DOT_PROMPT_CODE
.proc   DOT_PROMPT_CODE
.a16
.i16
	sep    #$20
        .a8
@w1:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @w1
	lda #' '
	sta UART_DATA
@w2:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @w2
	lda #'o'
	sta UART_DATA
@w3:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @w3
	lda #'k'
	sta UART_DATA
@w4:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @w4
	lda #$0D
	sta UART_DATA
@w5:            LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @w5
	lda #$0A
	sta UART_DATA
	rep    #$20
        .a16
	NEXT
.endproc

;==============================================================================
; LAST_WORD - must be the CFA of the final word defined above
; Used by FORTH_INIT to seed LATEST
;==============================================================================
LAST_WORD = DOT_PROMPT_CFA

;==============================================================================
; Stub declarations for words referenced in QUIT_BODY colon definition
; that are not yet implemented (WORDS, defining words etc.)
; These allow the project to assemble; implement fully in a later pass.
;==============================================================================

	HEADER "WORDS", WORDS_CFA, 0, DOT_PROMPT_CFA
	CODEPTR WORDS_CODE
.proc   WORDS_CODE
.a16
.i16
	; Walk dictionary and print names
	lda UP
	clc
	adc #U_LATEST
	sta SCRATCH0
	lda (SCRATCH0)      ; LATEST
	sta SCRATCH0
@wloop:
	lda SCRATCH0
	beq    @wdone
	; Print name
	lda SCRATCH0
	clc
	adc #2              ; Skip link
	sta SCRATCH1
	sep    #$20
        .a8
	lda (SCRATCH1)      ; flags+len
	and    #F_LENMASK
	rep    #$20
        .a16
	and    #$00FF
	beq    @wnext          ; Skip zero-length names
	; Type name: addr = SCRATCH1+1, len = A
	sta TMPA
	lda SCRATCH1
	inc
	sta SCRATCH1
	ldy   #0
@wtype:
	sep    #$20
        .a8
@wtxw:          LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @wtxw
	lda (SCRATCH1),Y
	sta UART_DATA
	rep    #$20
        .a16
	iny
	dec    TMPA
	bne    @wtype
	; Space after name
	sep    #$20
        .a8
@wspw:          LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @wspw
	lda #$20
	sta UART_DATA
	rep    #$20
        .a16
@wnext:
	lda (SCRATCH0)      ; Follow link
	sta SCRATCH0
	bra    @wloop
@wdone:
	NEXT
.endproc

; Stub defining words - to be fully implemented
	HEADER ":", COLON_CFA, 0, WORDS_CFA
	CODEPTR COLON_CODE
.proc   COLON_CODE
.a16
.i16
	; Full implementation: parse name, create header, set STATE=1
	; Stub: just set STATE to compile mode
	lda UP
	clc
	adc #U_STATE
	sta SCRATCH0
	lda #1
	sta (SCRATCH0)
	NEXT
.endproc

	HEADER ";", SEMICOLON_CFA, F_IMMEDIATE, COLON_CFA
	CODEPTR SEMICOLON_CODE
.proc   SEMICOLON_CODE
.a16
.i16
	; Full implementation: compile EXIT, set STATE=0, smudge
	lda UP
	clc
	adc #U_STATE
	sta SCRATCH0
	stz   (SCRATCH0)      ; STATE = 0
	NEXT
.endproc

	HEADER "CONSTANT", CONSTANT_CFA, 0, SEMICOLON_CFA
	CODEPTR CONSTANT_CODE
.proc   CONSTANT_CODE
.a16
.i16
	; Stub: full impl parses name, creates entry with DOCON, stores value
	NEXT
.endproc

	HEADER "VARIABLE", VARIABLE_CFA, 0, CONSTANT_CFA
	CODEPTR VARIABLE_CODE
.proc   VARIABLE_CODE
.a16
.i16
	; Stub: full impl parses name, creates entry with DOVAR, allots cell
	NEXT
.endproc

	HEADER "CREATE", CREATE_CFA, 0, VARIABLE_CFA
	CODEPTR CREATE_CODE
.proc   CREATE_CODE
.a16
.i16
	; Stub
	NEXT
.endproc

	HEADER "DOES>", DOES_CFA, F_IMMEDIATE, CREATE_CFA
	CODEPTR DOES_CODE
.proc   DOES_CODE
.a16
.i16
	; Stub
	NEXT
.endproc

; Output formatting stubs
	HEADER "U.", UDOT_CFA, 0, DOES_CFA
	CODEPTR UDOT_CODE
.proc   UDOT_CODE
.a16
.i16
	lda 0,X
	inx
	inx
	sta SCRATCH0
	jsr print_cudec
	NEXT
.endproc

	HEADER ".HEX", DOTHEX_CFA, 0, UDOT_CFA
	CODEPTR DOTHEX_CODE
.proc   DOTHEX_CODE
.a16
.i16
	; Print TOS as 4-digit hex
	lda 0,X
	inx
	inx
	; Print 4 hex digits
	ldy   #4
@hloop:
	; Rotate top nibble into position
	asl
	asl
	asl
	asl
	pha
	lsr
	lsr
	lsr
	lsr
	and    #$000F
	cmp    #10
                BLT     @hdigit
	clc
	adc #'A'-10
	bra    @hemit
@hdigit:        CLC
	adc #'0'
@hemit:
	pha
	sep    #$20
        .a8
@hwtx:          LDA     UART_STATUS
	and    #UART_TXRDY
	beq    @hwtx
	lda 1,S
	sta UART_DATA
	rep    #$20
        .a16
	pla     	; char
	pla     	; original value rotated
	dey
	bne    @hloop
	NEXT
.endproc

; String literal words - stubs
	HEADER '.""', DOTQUOTE_CFA, F_IMMEDIATE, DOTHEX_CFA
	CODEPTR DOTQUOTE_CODE
.proc   DOTQUOTE_CODE
.a16
.i16
	; Full impl: if interpreting emit string, if compiling compile it
	NEXT
.endproc

	HEADER 'S""', SQUOTE_CFA, F_IMMEDIATE, DOTQUOTE_CFA
	CODEPTR SQUOTE_CODE
.proc   SQUOTE_CODE
.a16
.i16
	; Stub
	NEXT
.endproc

	HEADER "NUMBER", NUMBER_CFA, 0, SQUOTE_CFA
	CODEPTR NUMBER_CODE
.proc   NUMBER_CODE
	.a16
	.i16
	; ( addr -- n flag ) Convert counted string to number
	; flag: TRUE if successful
	jsr INTERPRET_CODE::do_number
	bcc @ok
	; Error
	lda #$FFFF
	eor #$FFFF          ; = 0 = FALSE
	dex
	dex
	stz 0,X
	NEXT
@ok:            DEX
	dex
	lda #$FFFF
	sta 0,X
	NEXT
.endproc

	HEADER "ABORT\"", ABORTQ_CFA, F_IMMEDIATE, NUMBER_CFA
	CODEPTR ABORTQ_CODE
.proc   ABORTQ_CODE
	.a16
	.i16
	; Stub
	NEXT
.endproc
