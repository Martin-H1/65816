;==============================================================================
; stubs.s - 65816 Forth Kernel Unimplmented Primitives
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
.include "hal.inc"
.include "macros.inc"
.include "dictionary.inc"
.include "print.inc"

.segment "CODE"

;==============================================================================
; Stub declarations for words referenced in QUIT_BODY colon definition
; that are not yet implemented (WORDS, defining words etc.)
; These allow the project to assemble; implement fully in a later pass.
;==============================================================================

	HEADER "WORDS", WORDS_CFA, 0, DOT_PROMPT_CFA
	CODEPTR WORDS_CODE
.proc   WORDS_CODE
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
	OFF16MEM
	lda (SCRATCH1),Y
	ON16MEM
	jsr hal_putch
	iny
	dec    TMPA
	bne    @wtype
	; Space after name
	lda #$20
	jsr hal_putch
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
	; Full implementation: compile EXIT, set STATE=0, smudge
	lda UP
	clc
	adc #U_STATE
	sta SCRATCH0
	lda #0
	sta (SCRATCH0)      ; STATE = 0
	NEXT
.endproc

	HEADER "CONSTANT", CONSTANT_CFA, 0, SEMICOLON_CFA
	CODEPTR CONSTANT_CODE
.proc   CONSTANT_CODE
	; Stub: full impl parses name, creates entry with DOCON, stores value
	NEXT
.endproc

	HEADER "VARIABLE", VARIABLE_CFA, 0, CONSTANT_CFA
	CODEPTR VARIABLE_CODE
.proc   VARIABLE_CODE
	; Stub: full impl parses name, creates entry with DOVAR, allots cell
	NEXT
.endproc

	HEADER "CREATE", CREATE_CFA, 0, VARIABLE_CFA
	CODEPTR CREATE_CODE
.proc   CREATE_CODE
	; Stub
	NEXT
.endproc

	HEADER "DOES>", DOES_CFA, F_IMMEDIATE, CREATE_CFA
	CODEPTR DOES_CODE
.proc   DOES_CODE
	; Stub
	NEXT
.endproc

; Output formatting stubs
	HEADER "U.", UDOT_CFA, 0, DOES_CFA
	CODEPTR UDOT_CODE
.proc   UDOT_CODE
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
	; Print TOS as 4-digit hex
	lda 0,X
	inx
	inx
	jsr print_chex			; Print 4 hex digits
	NEXT
.endproc

; String literal words - stubs
; todo: fix the quote problem in .", s", and abort"
	HEADER ".Q", DOTQUOTE_CFA, F_IMMEDIATE, DOTHEX_CFA
	CODEPTR DOTQUOTE_CODE
.proc   DOTQUOTE_CODE
	; Full impl: if interpreting emit string, if compiling compile it
	NEXT
.endproc

	HEADER "SQ", SQUOTE_CFA, F_IMMEDIATE, DOTQUOTE_CFA
	CODEPTR SQUOTE_CODE
.proc   SQUOTE_CODE
	; Stub
	NEXT
.endproc

	HEADER "NUMBER", NUMBER_CFA, 0, SQUOTE_CFA
	CODEPTR NUMBER_CODE
.proc   NUMBER_CODE
	; ( addr -- n flag ) Convert counted string to number
	; flag: TRUE if successful
;	jsr INTERPRET_CODE::do_number TODO What does it want to do here?
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

	HEADER "ABORTQ", ABORTQ_CFA, F_IMMEDIATE, NUMBER_CFA
	CODEPTR ABORTQ_CODE
.proc   ABORTQ_CODE
	; Stub
	NEXT
.endproc
