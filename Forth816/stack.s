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
PUBLIC DUP_CODE
	lda 0,X			; Load TOS
	dex
	dex
	sta 0,X			; Push copy
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; DROP ( a -- )
;------------------------------------------------------------------------------
	HEADER "DROP", DROP_CFA, 0, DUP_CFA
	CODEPTR DROP_CODE
PUBLIC DROP_CODE
	inx
	inx
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; SWAP ( a b -- b a )
;------------------------------------------------------------------------------
	HEADER "SWAP", SWAP_CFA, 0, DROP_CFA
	CODEPTR SWAP_CODE
PUBLIC SWAP_CODE
	lda 0,X			; b (TOS)
	sta SCRATCH0
	lda 2,X			; a (NOS)
	sta 0,X			; TOS = a
	lda SCRATCH0		; b
	sta 2,X			; NOS = b
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; OVER ( a b -- a b a )
;------------------------------------------------------------------------------
	HEADER "OVER", OVER_CFA, 0, SWAP_CFA
	CODEPTR OVER_CODE
PUBLIC OVER_CODE
	lda 2,X			; a (NOS)
	dex
	dex
	sta 0,X			; Push copy of a
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; ROT ( a b c -- b c a )
;------------------------------------------------------------------------------
	HEADER "ROT", ROT_CFA, 0, OVER_CFA
	CODEPTR ROT_CODE
PUBLIC ROT_CODE
	lda 4,X			; a (bottom)
	sta SCRATCH0
	lda 2,X			; b
	sta 4,X			; bottom slot = b
	lda 0,X			; c (TOS)
	sta 2,X			; middle slot = c
	lda SCRATCH0		; a
	sta 0,X			; TOS = a
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; NIP ( a b -- b )
;------------------------------------------------------------------------------
	HEADER "NIP", NIP_CFA, 0, ROT_CFA
	CODEPTR NIP_CODE
PUBLIC NIP_CODE
	lda 0,X			; b (TOS)
	inx
	inx
	sta 0,X			; Overwrite a with b
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; TUCK ( a b -- b a b )
;------------------------------------------------------------------------------
	HEADER "TUCK", TUCK_CFA, 0, NIP_CFA
	CODEPTR TUCK_CODE
PUBLIC TUCK_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; 2DROP ( a b -- )
;------------------------------------------------------------------------------
	HEADER "2DROP", TWODROP_CFA, 0, TUCK_CFA
	CODEPTR TWODROP_CODE
PUBLIC TWODROP_CODE
	inx
	inx
	inx
	inx
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; 2DUP ( a b -- a b a b )
;------------------------------------------------------------------------------
	HEADER "2DUP", TWODUP_CFA, 0, TWODROP_CFA
	CODEPTR TWODUP_CODE
PUBLIC   TWODUP_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; 2SWAP ( a b c d -- c d a b )
;------------------------------------------------------------------------------
	HEADER "2SWAP", TWOSWAP_CFA, 0, TWODUP_CFA
	CODEPTR TWOSWAP_CODE
PUBLIC TWOSWAP_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; 2OVER ( a b c d -- a b c d a b )
;------------------------------------------------------------------------------
	HEADER "2OVER", TWOOVER_CFA, 0, TWOSWAP_CFA
	CODEPTR TWOOVER_CODE
PUBLIC TWOOVER_CODE
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
ENDPUBLIC

;------------------------------------------------------------------------------
; DEPTH ( -- n ) number of items on parameter stack
;------------------------------------------------------------------------------
	HEADER "DEPTH", DEPTH_CFA, 0, TWOOVER_CFA
	CODEPTR DEPTH_CODE
PUBLIC DEPTH_CODE
	stx SCRATCH0		; compute (PSP_INIT - x) / 2
	lda #PSP_INIT
	sec
	sbc SCRATCH0
	lsr			; Divide by 2 (cells)
	dex
	dex
	sta 0,X			; push to TOS
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; PICK ( xu...x1 x0 u -- xu...x1 x0 xu )
;------------------------------------------------------------------------------
	HEADER "PICK", PICK_CFA, 0, DEPTH_CFA
	CODEPTR PICK_CODE
PUBLIC PICK_CODE
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
ENDPUBLIC

;==============================================================================
; SECTION 2: RETURN STACK PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; >R ( a -- ) (R: -- a)
;------------------------------------------------------------------------------
	HEADER ">R", TOR_CFA, 0, PICK_CFA
	CODEPTR TOR_CODE
PUBLIC TOR_CODE
	lda 0,X			; Pop from parameter stack
	inx
	inx
	pha			; Push onto return stack
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; R> ( -- a ) (R: a -- )
;------------------------------------------------------------------------------
	HEADER "R>", RFROM_CFA, 0, TOR_CFA
	CODEPTR RFROM_CODE
PUBLIC RFROM_CODE
	pla			; Pop from return stack
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; R@ ( -- a ) (R: a -- a)
;------------------------------------------------------------------------------
	HEADER "R@", RFETCH_CFA, 0, RFROM_CFA
	CODEPTR RFETCH_CODE
PUBLIC RFETCH_CODE
	; Officially this function peeks at return stack without popping.
	; Unofficially it's easier to pop and push back.
	pla			; Pop R@ value
	pha			; Push R@ back
	dex
	dex
	sta 0,X			; Push onto parameter stack
	NEXT
ENDPUBLIC
