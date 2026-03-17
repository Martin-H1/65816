; -----------------------------------------------------------------------------
; compareTest - Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "compare.inc"
.include "forth.inc"
.include "hal.inc"
.include "macros.inc"
.include "print.inc"

; Main entry point for the test
.proc main
	ON16MEM
	ON16X
	printcr
	println enter
	ldx #PSP_INIT

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

	println exit
	rtl
.endproc

; This is the next link in the dictionary. Place a stub here.
; TODO remove this when the dictionary is collapsed into a single module.
PUBLIC TWOSLASH_CFA
	nop
ENDPUBLIC

enter:	.asciiz "compare test - enter!"
exit:	.asciiz "compare test - exit!"

.proc equalsTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr EQUAL_CODE
	print equal1
	POP
	printc
	printcr

	lda #42
	PUSH
	lda #32
	PUSH
	jsr EQUAL_CODE
	print equal2
	POP
	printc
	printcr
	rts
.endproc
equal1:	.asciiz "= test 32=32 - "
equal2:	.asciiz "= test 42=32 - "

.proc notEqualsTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr NOTEQUAL_CODE
	print nequal1
	POP
	printc
	printcr

	lda #42
	PUSH
	lda #32
	PUSH
	jsr NOTEQUAL_CODE
	print nequal2
	POP
	printc
	printcr
	rts
.endproc
nequal1:
	.asciiz "<> test 32=32 - "
nequal2:
	.asciiz "<> test 42=32 - "

.proc lessThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr LESS_CODE
	print less_test1
	POP
	printc
	printcr

	lda #42
	PUSH
	lda #32
	PUSH
	jsr LESS_CODE
	print less_test2
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #42
	PUSH
	jsr LESS_CODE
	print less_test3
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr LESS_CODE
	print less_test4
	POP
	printc
	printcr

	rts
.endproc
less_test1:
	.asciiz "< test 32 < 32 - "
less_test2:
	.asciiz "< test 42 < 32 - "
less_test3:
	.asciiz "< test 32 < 42 - "
less_test4:
	.asciiz "< test 32 < -42 - "

.proc GreaterThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr GREATER_CODE
	print gt_test1
	POP
	printc
	printcr

	lda #42
	PUSH
	lda #32
	PUSH
	jsr GREATER_CODE
	print gt_test2
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #42
	PUSH
	jsr GREATER_CODE
	print gt_test3
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr GREATER_CODE
	print gt_test4
	POP
	printc
	printcr

	rts
.endproc
gt_test1:
	.asciiz "> test 32 > 32 - "
gt_test2:
	.asciiz "> test 42 > 32 - "
gt_test3:
	.asciiz "> test 32 > 42 - "
gt_test4:
	.asciiz "> test 32 > -42 - "

.proc ulessThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr ULESS_CODE
	print uless_test1
	POP
	printc
	printcr

	lda #42
	PUSH
	lda #32
	PUSH
	jsr ULESS_CODE
	print uless_test2
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #42
	PUSH
	jsr ULESS_CODE
	print uless_test3
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr ULESS_CODE
	print uless_test4
	POP
	printc
	printcr

	rts
.endproc
uless_test1:
	.asciiz "U< test 32 < 32 - "
uless_test2:
	.asciiz "U< test 42 < 32 - "
uless_test3:
	.asciiz "U< test 32 < 42 - "
uless_test4:
	.asciiz "U< test 32 < -42 - "

.proc uGreaterThanTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr UGREATER_CODE
	print ugt_test1
	POP
	printc
	printcr

	lda #42
	PUSH
	lda #32
	PUSH
	jsr UGREATER_CODE
	print ugt_test2
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #42
	PUSH
	jsr UGREATER_CODE
	print gt_test3
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #$ffbe
	PUSH
	jsr UGREATER_CODE
	print ugt_test4
	POP
	printc
	printcr

	rts
.endproc
ugt_test1:
	.asciiz "U> test 32 > 32 - "
ugt_test2:
	.asciiz "U> test 42 > 32 - "
ugt_test3:
	.asciiz "U> test 32 > 42 - "
ugt_test4:
	.asciiz "U> test 32 > -42 - "

.proc zeroEqualsTest
	lda #32
	PUSH
	jsr ZEROEQ_CODE
	print zequal1
	POP
	printc
	printcr

	lda #0000
	PUSH
	jsr ZEROEQ_CODE
	print zequal2
	POP
	printc
	printcr
	rts
.endproc
zequal1:
	.asciiz "0= 32 test - "
zequal2:
	.asciiz "0= 0 equals - "

.proc zeroLessTest
	lda #32
	PUSH
	jsr ZEROLESS_CODE
	print zeroless1
	POP
	printc
	printcr

	lda #$ffbe
	PUSH
	jsr ZEROLESS_CODE
	print zeroless2
	POP
	printc
	printcr
	rts
.endproc
zeroless1:
	.asciiz "0< 32 test - "
zeroless2:
	.asciiz "0< -42 test - "

.proc zeroGtTest
	lda #32
	PUSH
	jsr ZEROGT_CODE
	print zerogt1
	POP
	printc
	printcr

	lda #$ffbe
	PUSH
	jsr ZEROGT_CODE
	print zerogt2
	POP
	printc
	printcr
	rts
.endproc
zerogt1:
	.asciiz "0> 32 test - "
zerogt2:
	.asciiz "0> -42 test - "

.proc andTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr AND_CODE
	print and1
	POP
	printc
	printcr

	rts
.endproc
and1:	.asciiz "AND test ff00 and 0ff0 - "

.proc orTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr OR_CODE
	print or1
	POP
	printc
	printcr

	rts
.endproc
or1:	.asciiz "OR test ff00 and 0ff0 - "

.proc xorTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr XOR_CODE
	print xor1
	POP
	printc
	printcr

	rts
.endproc
xor1:	.asciiz "XOR test ff00 and 0ff0 - "

.proc invertTest
	lda #$f0f0
	PUSH
	jsr INVERT_CODE
	print invert1
	POP
	printc
	printcr

	rts
.endproc
invert1:
	.asciiz "Invert test f0f0 - "

.proc lshiftTest
	lda #32
	PUSH
	lda #0
	PUSH
	jsr LSHIFT_CODE
	print lshift1
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #3
	PUSH
	jsr LSHIFT_CODE
	print lshift2
	POP
	printc
	printcr
	rts
.endproc
lshift1:
	.asciiz "lshift test 32 0 - "
lshift2:
	.asciiz "lshift test 32 3 - "

.proc rshiftTest
	lda #32
	PUSH
	lda #0
	PUSH
	jsr RSHIFT_CODE
	print rshift1
	POP
	printc
	printcr

	lda #32
	PUSH
	lda #3
	PUSH
	jsr RSHIFT_CODE
	print rshift2
	POP
	printc
	printcr
	rts
.endproc
rshift1:
	.asciiz "rshift test 32 0 - "
rshift2:
	.asciiz "rshift test 32 3 - "
