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

.import COMPARE_CODE
.import MOVE_CODE
.import WORD_CODE
.import FIND_CODE
.import NUMBER_CODE
.import INTERPRET_CODE
.import TRACEON_CODE

.importzp SCRATCH0
.importzp UP
.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "interpret test - enter!"

	jsr wordsTest
	jsr wordTest
	jsr compareTest
	jsr numberTest
	jsr findTest
	jsr interpretTest

	TYPESTRCR "interpret test - exit!"
	rts
ENDPUBLIC

.proc wordsTest
	phy			; Push IP on return stack
	ldy #WORDS_CFA		; Invoke WORDS
	iny			; Body starts at CFA+2
	iny
	NEXT			; Execute first body word
	; RTS_CFA will be called by NEXT and return
.endproc

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

.proc compareTest
	LDA #compare1
	PUSH
	LDA #.strlen("abcdef")
	PUSH
	lda #compare2
	PUSH
	lda #.strlen("bcdefg")
	PUSH
	jsr COMPARE_CODE
	TYPESTR_DOT "compare abcdef bcdefg (expect -1) = "

	LDA #compare2
	PUSH
	lda #.strlen("bcdefg")
	PUSH
	lda #compare1
	PUSH
	LDA #.strlen("abcdef")
	PUSH
	jsr COMPARE_CODE
	TYPESTR_DOT "compare bcdefg abcdef (expect 1) = "

	LDA #compare2
	PUSH
	lda #.strlen("bcdefg")
	PUSH
	lda #compare2
	PUSH
	lda #.strlen("bcdefg")
	PUSH
	jsr COMPARE_CODE
	TYPESTR_DOT "compare bcdefg bcdefg (expect 0) = "

	LDA #compare3
	PUSH
	lda #.strlen("cdefgh")
	PUSH
	lda #compare4
	PUSH
	lda #.strlen("xdefghi")
	PUSH
	jsr COMPARE_CODE
	TYPESTR_DOT "compare cdefgh cdefghi (expect -1) = "

	rts
.endproc
compare1:
	.asciiz "abcdef"
compare2:
	.asciiz "bcdefg"
compare3:
	.asciiz "cdefgh"
compare4:
	.asciiz "cdefghi"

.proc numberTest
	; Invalid input returning error flag
	LPPUTS numsg1		; empty string test
	lda #error1
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; two minus signs
	lda #error2
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; not a number
	lda #error3
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; a number with trailing junk
	lda #error4
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	; Decimal and hex conversion
	; Zero first
	LPPUTS numsg1
	lda #num1
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	; Negative numbers
	LPPUTS numsg1
	lda #num2
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #num3
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	phy
	ldy #U_BASE
	lda #16
	sta (UP),y
	ply

	LPPUTS numsg1
	lda #hex1
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex2
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex3
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex4
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex5
	PUSH
	jsr hal_lpputs
	jsr NUMBER_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	phy
	ldy #U_BASE
	lda #10
	sta (UP),y
	ply

	;Boundary values like $7FFF and $8000
	rts
.endproc
numsg1:	PString "Number test input='"
numsg2:	PString "', Status="
numsg3:	PString ", Result="
error1:	PString ""
error2:	PString "--"
error3:	PString "fpp"
error4:	PString "12G"
num1:	PString "0"
num2:	PString "-10"
num3:	PString "500"
hex1:	PString "7FF"
hex2:	PString "-7FF"
hex3:	PString "DEAD"
hex4:	PString "7FFF"
hex5:	PString "8000"

.proc findTest
	; Word that doesn't exist
	TYPESTR "Find test of "
	lda #find1
	jsr hal_lpputs
	lda #find1
	PUSH
	jsr FIND_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	TYPESTR ", addr="
	JSR DOTHEX_CODE
	JSR CR_CODE

	; Word that exists in dictionary
	TYPESTR "Find test of "
	lda #find2
	jsr hal_lpputs
	lda #find2
	PUSH
	jsr FIND_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	TYPESTR ", addr="
	JSR DOTHEX_CODE
	JSR CR_CODE

	; Immediate vs normal word flag returned correctly
	TYPESTR "Find test of "
	lda #find3
	jsr hal_lpputs
	lda #find3
	PUSH
	jsr FIND_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	TYPESTR ", addr="
	JSR DOTHEX_CODE
	JSR CR_CODE

	; Case sensitivity
	TYPESTR "Find test of "
	lda #find4
	jsr hal_lpputs
	lda #find4
	PUSH
	jsr FIND_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	TYPESTR ", addr="
	JSR DOTHEX_CODE
	JSR CR_CODE

	rts
.endproc
find1:	PString "foobar"
find2:	PString "NUMBER"
find3:	PString ";"
find4:	PString "number"

.proc interpretTest
	jsr TRACEON_CODE

	; Interpreting state

	; Parse a number
	jsr interpretNumTest
	TYPESTR_DOT "Interpret test of '1' (expect 1) = "

	; Executing the plus operator primitive by name
	jsr interpretPlusTest
	TYPESTR_DOT "Interpret '2 2 + ' (expect 4) = "

	; Unknown word triggering error
	jsr interpretErrorTest
	; Compiling state

	rts
.endproc

.proc interpretNumTest
	LDA #interpret1
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$10
	PUSH
	jsr MOVE_CODE
	phy			; Push IP on return stack
	ldy #INTERPRET_CFA	; Invoke INTERPRET
	iny			; Body starts at CFA+2
	iny
	NEXT			; Execute first body word
	; RTS_CFA will be called by NEXT and return
.endproc
interpret1:
	.asciiz "    1             "

.proc interpretPlusTest
	LDA #interpret2
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$10
	PUSH
	jsr MOVE_CODE
	phy			; Push IP on return stack
	ldy #INTERPRET_CFA	; Invoke INTERPRET
	iny			; Body starts at CFA+2
	iny
	NEXT			; Execute first body word
	; RTS_CFA will be called by NEXT and return
.endproc
interpret2:
	.asciiz " 2 2 +         "

.proc interpretErrorTest
	LDA #interpret3
	PUSH
	LDA #TIB_BASE
	PUSH
	LDA #$10
	PUSH
	jsr MOVE_CODE
	phy			; Push IP on return stack
	ldy #INTERPRET_CFA	; Invoke INTERPRET
	iny			; Body starts at CFA+2
	iny
	NEXT			; Execute first body word
	; RTS_CFA will be called by NEXT and return
.endproc
interpret3:
	.asciiz " splat         "
