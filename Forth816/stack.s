;==============================================================================
; stack.s - 65816 Forth Kernel Stack Primitives
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
; SECTION 1: STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; DUP ( a -- a a )
;------------------------------------------------------------------------------
	HEADER "DUP", DUP_CFA, 0, 0
	CODEPTR DUP_CODE
.proc DUP_CODE
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
	; Officially this function peeks at return stack without popping.
	; Unofficially it's easier to pop and push back.
	pla			; Pop R@ value
	pha			; Push R@ back
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
.endproc
