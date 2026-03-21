; -----------------------------------------------------------------------------
; compareTest - Hello World sample for the Mench Reloaded SBC.
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
	PRINTLN enter

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

	PRINTLN exit
	rts
ENDPUBLIC

enter:	.asciiz "compare test - enter!"
exit:	.asciiz "compare test - exit!"

.proc equalsTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr EQUAL_CODE
	PRINTLN_POP  equal1

	lda #42
	PUSH
	lda #32
	PUSH
	jsr EQUAL_CODE
	PRINTLN_POP equal2
	rts
.endproc
equal1:	.asciiz "= test 32=32 (expect FFFF) = "
equal2:	.asciiz "= test 42=32 (expect 0000) = "

.proc notEqualsTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr NOTEQUAL_CODE
	PRINTLN_POP nequal1

	lda #42
	PUSH
	lda #32
	PUSH
	jsr NOTEQUAL_CODE
	PRINTLN_POP nequal2
	rts
.endproc
nequal1:
	.asciiz "<> test 32=32 (expect 0000) = "
nequal2:
	.asciiz "<> test 42=32 (expect FFFF) = "

.proc lessThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr LESS_CODE
	PRINTLN_POP less_test1

	lda #42
	PUSH
	lda #32
	PUSH
	jsr LESS_CODE
	PRINTLN_POP less_test2

	lda #32
	PUSH
	lda #42
	PUSH
	jsr LESS_CODE
	PRINTLN_POP less_test3

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr LESS_CODE
	PRINTLN_POP less_test4

	rts
.endproc
less_test1:
	.asciiz "< test 32 < 32 (expect 0000) = "
less_test2:
	.asciiz "< test 42 < 32 (expect 0000) = "
less_test3:
	.asciiz "< test 32 < 42 (expect FFFF) = "
less_test4:
	.asciiz "< test 32 < -42 (expect 0000) = "

.proc GreaterThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr GREATER_CODE
	PRINTLN_POP gt_test1

	lda #42
	PUSH
	lda #32
	PUSH
	jsr GREATER_CODE
	PRINTLN_POP gt_test2

	lda #32
	PUSH
	lda #42
	PUSH
	jsr GREATER_CODE
	PRINTLN_POP gt_test3

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr GREATER_CODE
	PRINTLN_POP gt_test4

	rts
.endproc
gt_test1:
	.asciiz "> test 32 > 32 (expect 0000) = "
gt_test2:
	.asciiz "> test 42 > 32 (expect FFFF) = "
gt_test3:
	.asciiz "> test 32 > 42 (expect 0000) = "
gt_test4:
	.asciiz "> test 32 > -42 (expect FFFF) = "

.proc ulessThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr ULESS_CODE
	PRINTLN_POP uless_test1

	lda #42
	PUSH
	lda #32
	PUSH
	jsr ULESS_CODE
	PRINTLN_POP uless_test2

	lda #32
	PUSH
	lda #42
	PUSH
	jsr ULESS_CODE
	PRINTLN_POP uless_test3

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr ULESS_CODE
	PRINTLN_POP uless_test4

	rts
.endproc
uless_test1:
	.asciiz "U< test 32 < 32 (expect 0000) = "
uless_test2:
	.asciiz "U< test 42 < 32 (expect 0000) = "
uless_test3:
	.asciiz "U< test 32 < 42 (expect FFFF) = "
uless_test4:
	.asciiz "U< test 32 < -42 (expect FFFF) = "

.proc uGreaterThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr UGREATER_CODE
	PRINTLN_POP ugt_test1

	lda #42
	PUSH
	lda #32
	PUSH
	jsr UGREATER_CODE
	PRINTLN_POP ugt_test2

	lda #32
	PUSH
	lda #42
	PUSH
	jsr UGREATER_CODE
	PRINTLN_POP gt_test3

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr UGREATER_CODE
	PRINTLN_POP ugt_test4

	rts
.endproc
ugt_test1:
	.asciiz "U> test 32 > 32 (expect 0000) = "
ugt_test2:
	.asciiz "U> test 42 > 32 (expect FFFF) = "
ugt_test3:
	.asciiz "U> test 32 > 42 (expect 0000) = "
ugt_test4:
	.asciiz "U> test 32 > -42 (expect 0000) = "

.proc zeroEqualsTest
	lda #32
	PUSH
	jsr ZEROEQ_CODE
	PRINTLN_POP zequal1

	lda #0000
	PUSH
	jsr ZEROEQ_CODE
	PRINTLN_POP zequal2

	rts
.endproc
zequal1:
	.asciiz "0= 32 test (expect 0000) = "
zequal2:
	.asciiz "0= 0 equals (expect FFFF) = "

.proc zeroLessTest
	lda #32
	PUSH
	jsr ZEROLESS_CODE
	PRINTLN_POP zeroless1

	lda #$ffbe
	PUSH
	jsr ZEROLESS_CODE
	PRINTLN_POP zeroless2

	rts
.endproc
zeroless1:
	.asciiz "0< 32 test (expect 0000) = "
zeroless2:
	.asciiz "0< -42 test (expect FFFF) = "

.proc zeroGtTest
	lda #32
	PUSH
	jsr ZEROGT_CODE
	PRINTLN_POP zerogt1

	lda #$ffbe
	PUSH
	jsr ZEROGT_CODE
	PRINTLN_POP zerogt2

	rts
.endproc
zerogt1:
	.asciiz "0> 32 test (expect FFFF) = "
zerogt2:
	.asciiz "0> -42 test (expect 0000) = "

.proc andTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr AND_CODE
	PRINTLN_POP and1

	rts
.endproc
and1:	.asciiz "AND test ff00 and 0ff0 (expect 0F00) = "

.proc orTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr OR_CODE
	PRINTLN_POP or1

	rts
.endproc
or1:	.asciiz "OR test ff00 and 0ff0 (expect FFF0) = "

.proc xorTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr XOR_CODE
	PRINTLN_POP xor1

	rts
.endproc
xor1:	.asciiz "XOR test ff00 and 0ff0 (expect F0F0) = "

.proc invertTest
	lda #$f0f0
	PUSH
	jsr INVERT_CODE
	PRINTLN_POP invert1

	rts
.endproc
invert1:
	.asciiz "Invert test f0f0 (expect 0F0F) = "

.proc lshiftTest
	lda #32
	PUSH
	lda #0
	PUSH
	jsr LSHIFT_CODE
	PRINTLN_POP lshift1

	lda #32
	PUSH
	lda #3
	PUSH
	jsr LSHIFT_CODE
	PRINTLN_POP lshift2

	rts
.endproc
lshift1:
	.asciiz "lshift test 0020 0 (expect 0020) = "
lshift2:
	.asciiz "lshift test 0020 3  (expect 0100) = "

.proc rshiftTest
	lda #32
	PUSH
	lda #0
	PUSH
	jsr RSHIFT_CODE
	PRINTLN_POP rshift1

	lda #32
	PUSH
	lda #3
	PUSH
	jsr RSHIFT_CODE
	PRINTLN_POP rshift2

	rts
.endproc
rshift1:
	.asciiz "rshift test 0020 0 (expect 0020) = "
rshift2:
	.asciiz "rshift test 0020 3 (expect 0004) = "
