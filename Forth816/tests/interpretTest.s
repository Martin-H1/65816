; -----------------------------------------------------------------------------
; interpreterTest - unit test for interpreter words (e.g. WORD, FIND,
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
.import SKIPCHAR_CODE
.import PLACE_CODE
.import PARSE_CODE
.import WORD_CODE
.import FIND_CODE
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
	jsr skipCharTest
	jsr placeTest
	jsr parseTest
	jsr parseNameTest
	jsr wordTest
	jsr compareTest
	jsr findTest
	jsr interpretTest

	TYPESTRCR "interpret test - exit!"
	rts
ENDPUBLIC

.proc skipCharTest
	MOVE_TIB "   .c hello world"
	lda #' '
	PUSH
	jsr SKIPCHAR_CODE
	phy
	ldy #U_TOIN
	lda (UP),Y
	PUSH
	ply
	TYPESTR_DOT "skip char test (expect 3) TOIN = "
	rts
.endproc

.proc placeTest
	lda #plsrc
	PUSH
	lda #.strlen("hi mom.")
	PUSH
	lda #pldst
	PUSH
	jsr PLACE_CODE

	TYPESTR "place test (expect 'HI MOM.') = "
	lda #pldst
	jsr hal_lpputs
	jsr CR_CODE
	rts
pldst:	.byte 00,"          "
plsrc:	.asciiz "hi mom."
.endproc

.proc parseTest
	MOVE_TIB "   .c hello worldc                     "
	lda #'c'
	PUSH
	jsr PARSE_CODE
	TYPESTR "parse test='"
	jsr TYPE_CODE
	TYPESTR "'"
	jsr CR_CODE
	RTS
.endproc

.proc parseNameTest
	MOVE_TIB "   hello world                     "

	CALL_DOCOL PARSENAME_CFA	; RTS_CFA will return here.
	TYPESTR "parse name test='"
	jsr TYPE_CODE
	TYPESTR "'"
	jsr CR_CODE
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
	CALL_DOCOL WORD_CFA	; RTS_CFA will return here.
	lda $600
	and #$00ff
	PUSH
	TYPESTR "word test size="
	jsr DOT_CODE
	TYPESTR ", WORD='"
	POP
	jsr hal_lpputs
	TYPESTRCR "'"

	; Word at end of input with no trailing delimiter
	MOVE_TIB "                             you"
	lda #SPACE
	PUSH
	CALL_DOCOL WORD_CFA	; RTS_CFA will return here.
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
	CALL_DOCOL WORD_CFA	; RTS_CFA will return here.
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
	CALL_DOCOL WORD_CFA	; RTS_CFA will return here.
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
	CALL_DOCOL WORD_CFA	; RTS_CFA will return here.
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
