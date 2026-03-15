;==============================================================================
; memory.s - 65816 Forth Kernel Memory Primitives
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

.include "forth.inc"
.include "macros.inc"
.include "dictionary.inc"
.include "print.inc"

.segment "CODE"

;==============================================================================
; SECTION 6: MEMORY PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; @ ( addr -- val ) fetch cell
;------------------------------------------------------------------------------
	HEADER "@", FETCH_CFA, 0, RSHIFT_CFA
	CODEPTR FETCH_CODE
.proc FETCH_CODE
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
