;==============================================================================
; io.s - 65816 Forth Kernel I/O Primitives
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

.include "dictionary.inc"
.include "forth.inc"
.include "hal.inc"
.include "macros.inc"
.include "print.inc"
	
.segment "CODE"

;==============================================================================
; SECTION 7: Serial I/O PRIMITIVES
;==============================================================================

;------------------------------------------------------------------------------
; EMIT ( char -- ) transmit character via UART
;------------------------------------------------------------------------------
	HEADER "EMIT", EMIT_CFA, 0, FILL_CFA
	CODEPTR EMIT_CODE
PUBLIC EMIT_CODE
	lda 0,X			; pop char and call HAL
	inx
	inx
	jsr hal_putch
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; KEY ( -- char ) receive character from UART (blocking)
;------------------------------------------------------------------------------
	HEADER "KEY", KEY_CFA, 0, EMIT_CFA
	CODEPTR KEY_CODE
PUBLIC KEY_CODE
	jsr hal_getch
	and #$00FF          ; Zero extend to 16-bit
	dex		    ; push to TOS
	dex
	sta 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; KEY? ( -- flag ) non-blocking check for available input
;------------------------------------------------------------------------------
	HEADER "KEY?", KEYQ_CFA, 0, KEY_CFA
	CODEPTR KEYQ_CODE
PUBLIC KEYQ_CODE
	dex
	dex
	jsr hal_cready
	beq @false
	lda #$FFFF
	sta 0,X
	NEXT
@false: stz 0,X
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; TYPE ( addr u -- ) transmit u characters from addr
;------------------------------------------------------------------------------
	HEADER "TYPE", TYPE_CFA, 0, KEYQ_CFA
	CODEPTR TYPE_CODE
PUBLIC TYPE_CODE
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
	OFF16MEM
	lda (SCRATCH0),Y
	ON16MEM
	jsr hal_putch
        INY
	dec TMPA
	bne @loop
@done:	ply
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; CR ( -- ) emit carriage return + line feed
;------------------------------------------------------------------------------
	HEADER "CR", CR_CFA, 0, TYPE_CFA
	CODEPTR CR_CODE
PUBLIC CR_CODE
	lda #$000D		; CR
	jsr hal_putch
	lda #$000A		; LF
	jsr hal_putch
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; SPACE ( -- ) emit a single space
;------------------------------------------------------------------------------
	HEADER "SPACE", SPACE_CFA, 0, CR_CFA
	CODEPTR SPACE_CODE
PUBLIC SPACE_CODE
	lda #$0020		; TODO get rid of magic number
	jsr hal_putch
	NEXT
ENDPUBLIC

;------------------------------------------------------------------------------
; SPACES ( n -- ) emit n spaces
;------------------------------------------------------------------------------
	HEADER "SPACES", SPACES_CFA, 0, SPACE_CFA
	CODEPTR SPACES_CODE
PUBLIC SPACES_CODE
	lda 0,X
	beq @done
	sta TMPA		; peek count n to TMPA
@loop:
	lda #$0020
	jsr hal_putch
	dec TMPA
	bne @loop
@done:	inx			; drop n
	inx
	NEXT
ENDPUBLIC

