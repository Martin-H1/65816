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
.include "macros.inc"
.include "print.inc"

.import WORD_CODE
.import FIND_CODE
.import NUMBER_CODE
.import INTERPRET_CODE

.globalzp UP

; Main entry point for the test
PUBLIC MAIN
	PRINTLN enter

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

	LDA #U_TIB			; --- User area: TIB = TIB_BASE ---
	LDA #TIB_BASE
	STA (UP),Y

	LDY #U_TOIN			; --- User area: >IN = 0 and SOURCE-LEN = 0 ---
	LDA #0
	STA (UP),Y			; >IN = 0

        LDY #U_SOURCELEN		; SOURCE-LEN = 0
	STA (UP),Y

	jsr wordTest
	jsr findTest
	jsr numberTest
	jsr interpretTest

	PRINTLN exit
	rts
ENDPUBLIC

enter:	.asciiz "interpret test - enter!"
exit:	.asciiz "interpret test - exit!"

.proc wordTest
	;Leading delimiters being skipped
	;Empty input returning zero-length string
	;Word at end of input with no trailing delimiter
	;Maximum length words

	rts
.endproc
word1:	.asciiz "word = "
word2:	.asciiz "."

.proc findTest
	;Word that exists in dictionary
	;Word that doesn't exist
	;Immediate vs normal word flag returned correctly
	;Case sensitivity
	rts
.endproc
find1:	.asciiz "word = "
find2:	.asciiz "."

.proc numberTest
	;Decimal and hex conversion
	;Negative numbers
	;Invalid input returning error flag
	;Boundary values like $7FFF and $8000
	rts
.endproc
number1:
	.asciiz ""

.proc interpretTest
	;Executing a known primitive by name
	;Compiling vs interpreting state
	;Unknown word triggering error
	rts
.endproc
interpret1:
	.asciiz ""
