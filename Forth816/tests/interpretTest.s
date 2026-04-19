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
.import DROP_CODE
.import MOVE_CODE
.import PARSE_CODE
.import WORD_CODE
.import FIND_CODE
.import TONUMBER_CODE
.import NUMBERQ_CODE
.import INTERPRET_CODE
.import TRACEOFF_CODE
.import TRACEON_CODE

.importzp SCRATCH0
.importzp UP
.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "interpret test - enter!"
	jsr TRACEOFF_CODE	; tracing initialization.

	jsr wordsTest
	jsr parseTest
	jsr wordTest
	jsr compareTest
	jsr tonumberTest
	jsr numberTest
	jsr findTest
	jsr interpretTest

	TYPESTRCR "interpret test - exit!"
	rts
ENDPUBLIC

.proc parseTest
	MOVE_TIB "   .c hello worldc                     "
	lda #'c'
	PUSH
	jsr PARSE_CODE
	TYPESTR "parse test='"
	jsr TYPE_CODE
	TYPESTR "'"
	RTS
.endproc

.proc wordsTest
	CALL_DOCOL WORDS_CFA	; RTS_CFA will return here.
	RTS
.endproc

.proc wordTest
	; Leading delimiters being skipped
	MOVE_TIB "             can                "
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
	MOVE_TIB "                             you"
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
	MOVE_TIB "read                            "
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
	MOVE_TIB "                                "
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
	MOVE_TIB " this                           "
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

.macro TONUMARGS str
.scope
	lda #0000
	PUSH
	PUSH
	lda #@addr
	PUSH
	lda #.strlen(str)
	PUSH
	BRA @over
@addr:	.asciiz str
@over:
.endscope
.endmacro

.proc tonumberTest
	TYPESTR ">NUMBER test input=''"
	TONUMARGS ""
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='--'"
	TONUMARGS "--"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='12G'"
	TONUMARGS "12G"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='0'"
	TONUMARGS "0"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='-10'"
	TONUMARGS "-10"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='500'"
	TONUMARGS "500"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	phy
	ldy #U_BASE
	lda #16
	sta (UP),y
	ply

	TYPESTR ">NUMBER test input='7FF'"
	TONUMARGS "7FF"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOT ", Result="

	TYPESTR ">NUMBER test input='DEAD'"
	TONUMARGS "DEAD"
	jsr TONUMBER_CODE
	TYPESTR ", Status="
	JSR DOT_CODE
	jsr DROP_CODE
	jsr DROP_CODE
	TYPESTR_DOTHEX ", Result="

	phy
	ldy #U_BASE
	lda #10
	sta (UP),y
	ply

	rts
.endproc

.proc numberTest
	; Invalid input returning error flag
	LPPUTS numsg1		; empty string test
	lda #error1
	PUSH
	jsr hal_lpputs
	LPPUTS numsg2
	jsr NUMBERQ_CODE
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; two minus signs
	lda #error2
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; not a number
	lda #error3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; a number with trailing junk
	lda #error4
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1		; a word instead of a number
	lda #error5
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
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
	jsr NUMBERQ_CODE
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
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #num3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex1
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex2
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOT_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex3
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex4
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

	LPPUTS numsg1
	lda #hex5
	PUSH
	jsr hal_lpputs
	jsr NUMBERQ_CODE
	LPPUTS numsg2
	jsr DOTHEX_CODE
	LPPUTS numsg3
	jsr DOTHEX_CODE
	jsr CR_CODE

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
error5:	PString "CELL"
num1:	PString "0"
num2:	PString "-10"
num3:	PString "500"
hex1:	PString "7FF"
hex2:	PString "-$7FF"
hex3:	PString "$DEAD"
hex4:	PString "$7FFF"
hex5:	PString "$8000"

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
	; Interpreting state
	; Parse a number
	MOVE_TIB "    1                           "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Interpret test of '1' (expect 1) = "
jsr DOTS_CODE
	; Executing the plus operator primitive by name
	MOVE_TIB "    2 3 +                       "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Interpret '2 3 + ' (expect 5) = "

	; Unknown word triggering error
	MOVE_TIB "    splat                       "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Interpret ' splat ' (expect error) = "

	rts
.endproc
