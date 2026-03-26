; -----------------------------------------------------------------------------
; interpreterTest - unit test for interpreter words (e.g. WORD, FIND, NUMBER,
; and INTERPRET.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.p816                   ; Enable 65816 instruction set
.smart off              ; Manual size tracking (safer for Forth)
.A16
.I16

.include "constants.inc"
.include "dictionary.inc"
.include "hal.inc"
.include "macros.inc"
.include "macrosdbg.inc"

.import MOVE_CODE
.import WORD_CODE
.import FIND_CODE
.import NUMBER_CODE
.import INTERPRET_CODE

.importzp SCRATCH0
.importzp UP

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "interpret test - enter!"

	jsr wordTest

	TYPESTRCR "interpret test - exit!"
	rts

	jsr findTest
	jsr numberTest
	jsr interpretTest

ENDPUBLIC

.proc wordTest
	; Leading delimiters being skipped
	LDA #word1
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$20
	PUSH
	jsr MOVE_CODE
	lda #SPACE
	PUSH
	jsr WORD_CODE
	lda $600
	and #$00ff
	PUSH
	TYPESTR "Size="
	jsr DOT_CODE
	TYPESTR ", WORD='"
	POP
	jsr hal_lpputs
	TYPESTRCR "'"

	; Word at end of input with no trailing delimiter
	LDA #word2
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$20
	PUSH
	jsr MOVE_CODE
	lda #SPACE
	PUSH
	jsr WORD_CODE
	TYPESTR "Size="
	lda $600
	and #$00ff
	PUSH
	jsr DOT_CODE
	TYPESTR ", WORD='"
	POP
	jsr hal_lpputs
	TYPESTRCR "'"

	; Word at start of input with trailing delimiter
	LDA #word3
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$20
	PUSH
	jsr MOVE_CODE
	lda #SPACE
	PUSH
	jsr WORD_CODE
	TYPESTR "Size="
	lda $600
	and #$00ff
	PUSH
	jsr DOT_CODE
	TYPESTR ", WORD='"
	POP
	jsr hal_lpputs
	TYPESTRCR "'"

	; Empty input returning zero-length string
	LDA #word4
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$20
	PUSH
	jsr MOVE_CODE
	lda #SPACE
	PUSH
	jsr WORD_CODE
	TYPESTR "Size="
	lda $600
	and #$00ff
	PUSH
	jsr DOT_CODE
	TYPESTR ", WORD='"
	POP
	jsr hal_lpputs
	TYPESTRCR "'"

	; Word with a single leading delimiter
	LDA #word5
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$20
	PUSH
	jsr MOVE_CODE
	lda #SPACE
	PUSH
	jsr WORD_CODE
	TYPESTR "Size="
	lda $600
	and #$00ff
	PUSH
	jsr DOT_CODE
	TYPESTR ", WORD='"
	POP
	jsr hal_lpputs
	TYPESTRCR "'"

	; Maximum length words
	rts
.endproc
word1:	.asciiz "             can                "
word2:	.asciiz "                             you"
word3:	.asciiz "read                            "
word4:	.asciiz "                                "
word5:	.asciiz " this                           "

.proc numberTest
	;Decimal and hex conversion
	;Negative numbers
	;Invalid input returning error flag
	;Boundary values like $7FFF and $8000
	rts
.endproc
num1:	.byte 01
	.asciiz "0"
num2:	.byte 03
	.asciiz "-10"
num3:	.byte 03
	.asciiz "500"
num4:	.byte 03
	.asciiz "fpp"
hex1:	.byte 00
	.asciiz "DEAD"
nummsg1:
	.asciiz "Size="
nummsg2:
	.asciiz ", WORD='"
nummsg3:
	.asciiz "'"

.proc findTest
	;Word that exists in dictionary
	;Word that doesn't exist
	;Immediate vs normal word flag returned correctly
	;Case sensitivity
	rts
.endproc
find1:	.asciiz "word = "
find2:	.asciiz "."

.proc interpretTest
	;Executing a known primitive by name
	;Compiling vs interpreting state
	;Unknown word triggering error
	rts
.endproc
interpret1:
	.asciiz ""
