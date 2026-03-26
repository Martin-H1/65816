; -----------------------------------------------------------------------------
; compareTest - Hello World sample for the Mench Reloaded SBC.
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

.import EQUAL_CODE
.import NOTEQUAL_CODE
.import LESS_CODE
.import GREATER_CODE
.import ULESS_CODE
.import UGREATER_CODE
.import ZEROEQ_CODE
.import ZEROLESS_CODE
.import ZEROGT_CODE
.import AND_CODE
.import OR_CODE
.import XOR_CODE
.import INVERT_CODE
.import LSHIFT_CODE
.import RSHIFT_CODE

; Main entry point for the test
PUBLIC MAIN
	TYPESTR "compare test - enter!"

	jsr equalsTest
	jsr notEqualsTest
	jsr lessThanTest
	jsr GreaterThanTest
	jsr ulessThanTest
	jsr uGreaterThanTest
	jsr zeroEqualsTest
	jsr zeroLessTest
	jsr zeroGtTest
	jsr andTest
	jsr orTest
	jsr xorTest
	jsr invertTest
	jsr lshiftTest
	jsr rshiftTest

	TYPESTR "compare test - exit!"
	rts
ENDPUBLIC

.proc equalsTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr EQUAL_CODE
	TYPESTR_DOT "= test 32=32 (expect -1) = "

	lda #42
	PUSH
	lda #32
	PUSH
	jsr EQUAL_CODE
	TYPESTR_DOT "= test 42=32 (expect 0) = "
	rts
.endproc

.proc notEqualsTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr NOTEQUAL_CODE
	TYPESTR_DOT "<> test 32=32 (expect 0) = "

	lda #42
	PUSH
	lda #32
	PUSH
	jsr NOTEQUAL_CODE
	TYPESTR_DOT "<> test 42=32 (expect -1) = "
	rts
.endproc

.proc lessThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr LESS_CODE
	TYPESTR_DOT "< test 32 < 32 (expect 0) = "

	lda #42
	PUSH
	lda #32
	PUSH
	jsr LESS_CODE
	TYPESTR_DOT "< test 42 < 32 (expect 0) = "

	lda #32
	PUSH
	lda #42
	PUSH
	jsr LESS_CODE
	TYPESTR_DOT "< test 32 < 42 (expect -1) = "

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr LESS_CODE
	TYPESTR_DOT "< test 32 < -42 (expect 0) = "

	rts
.endproc

.proc GreaterThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr GREATER_CODE
	TYPESTR_DOT "> test 32 > 32 (expect 0) = "

	lda #42
	PUSH
	lda #32
	PUSH
	jsr GREATER_CODE
	TYPESTR_DOT "> test 42 > 32 (expect -1) = "

	lda #32
	PUSH
	lda #42
	PUSH
	jsr GREATER_CODE
	TYPESTR_DOT "> test 32 > 42 (expect 0) = "

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr GREATER_CODE
	TYPESTR_DOT "> test 32 > -42 (expect -1) = "

	rts
.endproc

.proc ulessThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr ULESS_CODE
	TYPESTR_DOT "U< test 32 < 32 (expect 0) = "

	lda #42
	PUSH
	lda #32
	PUSH
	jsr ULESS_CODE
	TYPESTR_DOT "U< test 42 < 32 (expect 0) = "

	lda #32
	PUSH
	lda #42
	PUSH
	jsr ULESS_CODE
	TYPESTR_DOT "U< test 32 < 42 (expect -1) = "

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr ULESS_CODE
	TYPESTR_DOT "U< test 32 < -42 (expect -1) = "

	rts
.endproc

.proc uGreaterThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr UGREATER_CODE
	TYPESTR_DOT "U> test 32 > 32 (expect 0) = "

	lda #42
	PUSH
	lda #32
	PUSH
	jsr UGREATER_CODE
	TYPESTR_DOT "U> test 42 > 32 (expect -1) = "

	lda #32
	PUSH
	lda #42
	PUSH
	jsr UGREATER_CODE
	TYPESTR_DOT "U> test 32 > 42 (expect 0) = "

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr UGREATER_CODE
	TYPESTR_DOT "U> test 32 > -42 (expect 0) = "

	rts
.endproc

.proc zeroEqualsTest
	lda #32
	PUSH
	jsr ZEROEQ_CODE
	TYPESTR_DOT "0= 32 test (expect 0) = "

	lda #0000
	PUSH
	jsr ZEROEQ_CODE
	TYPESTR_DOT "0= 0 equals (expect -1) = "

	rts
.endproc

.proc zeroLessTest
	lda #32
	PUSH
	jsr ZEROLESS_CODE
	TYPESTR_DOT "0< 32 test (expect 0) = "

	lda #$ffbe
	PUSH
	jsr ZEROLESS_CODE
	TYPESTR_DOT "0< -42 test (expect -1) = "

	rts
.endproc

.proc zeroGtTest
	lda #32
	PUSH
	jsr ZEROGT_CODE
	TYPESTR_DOT "0> 32 test (expect -1) = "

	lda #$ffbe
	PUSH
	jsr ZEROGT_CODE
	TYPESTR_DOT "0> -42 test (expect 0) = "

	rts
.endproc

.proc andTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr AND_CODE
	TYPESTR_DOTHEX "AND test ff00 and 0ff0 (expect 0F00) = "

	rts
.endproc

.proc orTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr OR_CODE
	TYPESTR_DOTHEX "OR test ff00 and 0ff0 (expect FFF0) = "

	rts
.endproc

.proc xorTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr XOR_CODE
	TYPESTR_DOTHEX "XOR test ff00 and 0ff0 (expect F0F0) = "

	rts
.endproc

.proc invertTest
	lda #$f0f0
	PUSH
	jsr INVERT_CODE
	TYPESTR_DOTHEX "Invert test f0f0 (expect 0F0F) = "

	rts
.endproc

.proc lshiftTest
	lda #32
	PUSH
	lda #0
	PUSH
	jsr LSHIFT_CODE
	TYPESTR_DOTHEX "lshift test 0020 0 (expect 0020) = "

	lda #32
	PUSH
	lda #3
	PUSH
	jsr LSHIFT_CODE
	TYPESTR_DOTHEX "lshift test 0020 3  (expect 0100) = "

	rts
.endproc

.proc rshiftTest
	lda #32
	PUSH
	lda #0
	PUSH
	jsr RSHIFT_CODE
	TYPESTR_DOTHEX "rshift test 0020 0 (expect 0020) = "

	lda #32
	PUSH
	lda #3
	PUSH
	jsr RSHIFT_CODE
	TYPESTR_DOTHEX "rshift test 0020 3 (expect 0004) = "

	rts
.endproc
