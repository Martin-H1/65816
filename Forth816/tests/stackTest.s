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
	ldx PSP_INIT

	jsr dupTest
	jsr dropTest
	jsr swapTest
	jsr overTest
	jsr rotTest
	jsr nipTest
	jsr tuckTest
	jsr twoDropTest
	jsr twoDupTest
	jsr twoSwapTest
	jsr twoOverTest
	jsr depthTest
	jsr pickTest
	jsr toRTest
	jsr fromRTest
	jsr RAtTest

	println exit
	rtl
.endproc

; This is the next link in the dictionary. Place a stub here.
; TODO remove this when the dictionary is collapsed into a single module.
PUBLIC TWOSLASH_CFA
	nop
ENDPUBLIC

enter:	.asciiz "stack test - enter!"
exit:	.asciiz "stack test - exit!"

.proc dupTest
	lda #32
	PUSH
	jsr DUP_CODE
	jsr DEPTH_CODE
	POP
	print dup1
	printc
	printcr
	POP
	print dup2
	printc
	printcr
	POP
	print dup2
	printc
	printcr

	rts
.endproc
dup1:	.asciiz "dup test depth = "
dup2:	.asciiz "dup test pop = "

.proc dropTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr DEPTH_CODE
	POP
	print drop1
	printc
	printcr
	POP
	POP
	jsr DEPTH_CODE
	POP
	print drop1
	printc
	printcr
	rts
.endproc
drop1:	.asciiz "drop test depth = "

.proc swapTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr SWAP_CODE
	POP
	print swaptest1
	printc
	printcr
	POP
	print swaptest1
	printc
	printcr

	rts
.endproc
swaptest:
	.asciiz "swap test pop = "

.proc overTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr OVER_CODE

	POP
	print overtest1
	printc
	printcr
	PUSH

	POP
	print overtest1
	printc
	printcr

	POP
	print overtest1
	printc
	printcr

	rts
.endproc
overtest1:
	.asciiz "over test pop = "

.proc rotTest
	lda #1
	PUSH
	lda #2
	PUSH
	lda #3
	PUSH
	jsr ROT_CODE

	POP
	print rottest1
	printc
	printcr

	POP
	print rottest1
	printc
	printcr

	POP
	print rottest1
	printc
	printcr

	rts
.endproc
rottest1:
	.asciiz "rot test pop = "

.proc nipTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr NIP_CODE

	POP
	print niptest1
	printc
	printcr

	jsr DEPTH_CODE
	POP
	printc
	printcr

	rts
.endproc
niptest1:
	.asciiz "nip test pop = "

.proc zeroEqualsTest
	lda #32
	PUSH
	jsr ZEROEQ_CODE
	POP
	print zequal1
	printc

	lda #0000
	PUSH
	jsr ZEROEQ_CODE
	POP
	print zequal2
	printc
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
	POP
	print zeroless1
	printc

	lda #$ffbe
	PUSH
	jsr ZEROLESS_CODE
	POP
	print zeroless2
	printc
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
	POP
	print zerogt1
	printc

	lda #$ffbe
	PUSH
	jsr ZEROGT_CODE
	POP
	print zerogt2
	printc
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
	POP
	print and1
	printc

	rts
.endproc
and1:	.asciiz "AND test ff00 and 0ff0 - "

.proc orTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr OR_CODE
	POP
	print or1
	printc

	rts
.endproc
or1:	.asciiz "OR test ff00 and 0ff0 - "

.proc xorTest
	lda #$ff00
	PUSH
	lda #$0ff0
	PUSH
	jsr XOR_CODE
	POP
	print xor1
	printc

	rts
.endproc
xor1:	.asciiz "XOR test ff00 and 0ff0 - "

.proc invertTest
	lda #$f0f0
	PUSH
	jsr INVERT_CODE
	POP
	print invert1
	printc

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
	POP
	print lshift1
	printc

	lda #32
	PUSH
	lda #3
	PUSH
	jsr LSHIFT_CODE
	POP
	print lshift2
	printc
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
	POP
	print rshift1
	printc

	lda #32
	PUSH
	lda #3
	PUSH
	jsr RSHIFT_CODE
	POP
	print rshift2
	printc
	rts
.endproc
rshift1:
	.asciiz "rshift test 32 0 - "
rshift2:
	.asciiz "rshift test 32 3 - "
