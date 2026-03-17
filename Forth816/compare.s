;==============================================================================
; compare.s - 65816 Forth Kernel Comparison and Logic Primitives
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
; SECTION 4: COMPARISON PRIMITIVES
; ANS Forth: TRUE = $FFFF, FALSE = $0000
;==============================================================================

;------------------------------------------------------------------------------
; = ( a b -- flag )
;------------------------------------------------------------------------------
	HEADER "=", EQUAL_CFA, 0, TWOSLASH_CFA
	CODEPTR EQUAL_CODE
PUBLIC EQUAL_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; <> ( a b -- flag )
;------------------------------------------------------------------------------
	HEADER "<>", NOTEQUAL_CFA, 0, EQUAL_CFA
	CODEPTR NOTEQUAL_CODE
PUBLIC NOTEQUAL_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; < ( a b -- flag ) signed
;------------------------------------------------------------------------------
	HEADER "<", LESS_CFA, 0, NOTEQUAL_CFA
	CODEPTR LESS_CODE
PUBLIC LESS_CODE
	lda 2,X			; a
	sec
	sbc 0,X			; a - b
	bvs @overflow		; Overflow-aware signed compare
	bmi @true		; result negative and no overflow = a<b
	lda #$0000		; set TOS to false
	bra @return
@overflow:
	bpl @true		; overflow + positive result = a<b
@false:	lda #$0000		; set TOS to false
	bra @return
@true:	lda #$FFFF		; set TOS to true
@return:
	inx			; drop b
	inx
	sta 0,X			; set TOS to result
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; > ( a b -- flag ) signed
;------------------------------------------------------------------------------
	HEADER ">", GREATER_CFA, 0, LESS_CFA
	CODEPTR GREATER_CODE
PUBLIC GREATER_CODE
	lda 0,X			; b
	sec
	sbc  2,X		; b - a (reversed for >)
	bvs @overflow		; Overflow-aware signed compare
	bmi @true		; like the previous function
	lda #$0000		; set TOS to false
	bra @return
@overflow:
	bpl @true
@false:	lda #$000		; set TOS to false
	bra @return
@true:	lda #$FFFF		; set TOS to true
@return:
	inx			; drop b
	inx
	sta 0,X			; set TOS to result
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; U< ( u1 u2 -- flag ) unsigned less than
;------------------------------------------------------------------------------
	HEADER "U<", ULESS_CFA, 0, GREATER_CFA
	CODEPTR ULESS_CODE
PUBLIC ULESS_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; U> ( u1 u2 -- flag ) unsigned greater than
;------------------------------------------------------------------------------
	HEADER "U>", UGREATER_CFA, 0, ULESS_CFA
	CODEPTR UGREATER_CODE
PUBLIC UGREATER_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; 0= ( a -- flag )
;------------------------------------------------------------------------------
	HEADER "0=", ZEROEQ_CFA, 0, UGREATER_CFA
	CODEPTR ZEROEQ_CODE
PUBLIC ZEROEQ_CODE
	lda 0,X			; load and test TOS
	bne @false
	lda #$FFFF		; if it's zero, set TOS to TRUE
	sta 0,X
	NEXT
@false:	stz 0,X			; otherwise, set TOS to FALSE
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 0< ( a -- flag )
;------------------------------------------------------------------------------
	HEADER "0<", ZEROLESS_CFA, 0, ZEROEQ_CFA
	CODEPTR ZEROLESS_CODE
PUBLIC ZEROLESS_CODE
	lda 0,X			; load and test TOS
	bpl @false
	lda #$FFFF		; on negative, set TOS to TRUE
	sta 0,X
	NEXT
@false:	stz 0,X			; otherwise, set TOS to FALSE
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 0> ( a -- flag )
;------------------------------------------------------------------------------
	HEADER "0>", ZEROGT_CFA, 0, ZEROLESS_CFA
	CODEPTR ZEROGT_CODE
PUBLIC ZEROGT_CODE
	lda 0,X			; load and test TOS
	beq @false		; handle zero, as it is a positive
	bpl @true
@false:	stz 0,X			; zero or negative, set TOS to FALSE
	NEXT
@true:	lda #$FFFF		; otherwise, set TOS to TRUE
	sta 0,X
	NEXT
ENDPUBLIC

;==============================================================================
; SECTION 5: LOGIC PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; AND ( a b -- a&b )
;------------------------------------------------------------------------------
	HEADER "AND", AND_CFA, 0, ZEROGT_CFA
	CODEPTR AND_CODE
PUBLIC AND_CODE
	lda 0,X			; b
	inx			; drop b
	inx
	and 0,X			; a AND b
	sta 0,X			; set TOS to a AND b
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; OR ( a b -- a|b )
;------------------------------------------------------------------------------
	HEADER "OR", OR_CFA, 0, AND_CFA
	CODEPTR OR_CODE
PUBLIC OR_CODE
	lda 0,X			; b
	inx			; drop b
	inx
	ora 0,X			; a OR b
	sta 0,X			; set TOS to a OR b
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; XOR ( a b -- a^b )
;------------------------------------------------------------------------------
	HEADER "XOR", XOR_CFA, 0, OR_CFA
	CODEPTR XOR_CODE
PUBLIC XOR_CODE
	lda 0,X			; b
	inx			; drop b
	inx
	eor 0,X
	sta 0,X			; set TOS to a XOR b
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; INVERT ( a -- ~a )
;------------------------------------------------------------------------------
	HEADER "INVERT", INVERT_CFA, 0, XOR_CFA
	CODEPTR INVERT_CODE
PUBLIC INVERT_CODE
	lda 0,X
	eor #$FFFF
	sta 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; LSHIFT ( a u -- a<<u )
;------------------------------------------------------------------------------
	HEADER "LSHIFT", LSHIFT_CFA, 0, INVERT_CFA
	CODEPTR LSHIFT_CODE
PUBLIC LSHIFT_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; RSHIFT ( a u -- a>>u ) logical shift right
;------------------------------------------------------------------------------
	HEADER "RSHIFT", RSHIFT_CFA, 0, LSHIFT_CFA
	CODEPTR RSHIFT_CODE
PUBLIC RSHIFT_CODE
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
ENDPUBLIC
