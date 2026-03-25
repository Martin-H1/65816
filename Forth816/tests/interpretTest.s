; -----------------------------------------------------------------------------
; interpreterTest - unit test for interpreter words (e.g. WORD, FIND, NUMBER,
; and INTERPRET.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.p816                   ; Enable 65816 instruction set
.smart off              ; Manual size tracking (safer for Forth)
.A16
.I16

.include "ascii.inc"
.include "constants.inc"
.include "dictionary.inc"
.include "hal.inc"
.include "macros.inc"
.include "print.inc"

.import MOVE_CODE
.import WORD_CODE
.import FIND_CODE
.import NUMBER_CODE
.import INTERPRET_CODE

.importzp SCRATCH0
.importzp UP

; Main entry point for the test
PUBLIC MAIN
	PRINTLN enter
	phy
	; Perform Forth interpreter initialization
	LDA #UP_BASE			; Initialize User Pointer
	STA UP

	LDY #U_BASE			; --- User area: BASE = 10 ---
	LDA #10
	STA (UP),Y

	LDY #U_STATE  			; --- User area: STATE = 0 (interpret) ---
	LDA #0
	STA (UP),Y

	LDY #U_DP			; --- User area: DP = DICT_BASE ---
	LDA #DICT_BASE
	STA (UP),Y

	LDY #U_LATEST			; --- User area: LATEST = last ROM word ---
	LDA #LAST_WORD			; Defined at end of dictionary.s
	STA (UP),Y

	LDY #U_TIB			; --- User area: TIB = TIB_BASE ---
	LDA #TIB_BASE
	STA (UP),Y

	LDY #U_TOIN			; --- User area: >IN = 0 and SOURCE-LEN = 0 ---
	LDA #0
	STA (UP),Y			; >IN = 0

        LDY #U_SOURCELEN		; SOURCE-LEN = $20
	LDA #$20
	STA (UP),Y
	ply
	jsr wordTest

	PRINTLN exit
	rts

	jsr findTest
	jsr numberTest
	jsr interpretTest

ENDPUBLIC

enter:	.asciiz "interpret test - enter!"
exit:	.asciiz "interpret test - exit!"

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
	PRINT wordmsg1
	lda $600
	and #$00ff
	PRINTC
	PRINT wordmsg2
	POP
	jsr hal_lpputs
	PRINTLN wordmsg3

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
	PRINT wordmsg1
	lda $600
	and #$00ff
	PRINTC
	PRINT wordmsg2
	POP
	jsr hal_lpputs
	PRINTLN wordmsg3

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
	PRINT wordmsg1
	lda $600
	and #$00ff
	PRINTC
	PRINT wordmsg2
	POP
	jsr hal_lpputs
	PRINTLN wordmsg3

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
	PRINT wordmsg1
	lda $600
	and #$00ff
	PRINTC
	PRINT wordmsg2
	POP
	jsr hal_lpputs
	PRINTLN wordmsg3

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
	PRINT wordmsg1
	lda $600
	and #$00ff
	PRINTC
	PRINT wordmsg2
	POP
	jsr hal_lpputs
	PRINTLN wordmsg3

	; Maximum length words
	rts
.endproc
word1:	.asciiz "             can                "
word2:	.asciiz "                             you"
word3:	.asciiz "read                            "
word4:	.asciiz "                                "
word5:	.asciiz " this                           "
wordmsg1:
	.asciiz "Size="
wordmsg2:
	.asciiz ", WORD='"
wordmsg3:
	.asciiz "'"

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
