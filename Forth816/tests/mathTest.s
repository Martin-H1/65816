; -----------------------------------------------------------------------------
; mathTest - Mathematics unit test
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "forth.inc"
.include "hal.inc"
.include "macros.inc"
.include "math.inc"
.include "print.inc"

; Main entry point for the test
.proc main
	ON16MEM
	ON16X
	PRINTCR
	PRINTLN enter
	ldx #PSP_INIT

	jsr plusTest
	jsr minusTest
	jsr starTest
	jsr umStarTest
	jsr umSlashModTest
	jsr slashModTest
	jsr slashTest
	jsr modTest
	jsr negateTest
	jsr absTest
	jsr maxTest
	jsr minTest
	jsr onePlusTest
	jsr oneMinusTest
	jsr twoStarTest
	jsr twoSlashTest

	PRINTLN exit
	rtl
.endproc

; This is the next link in the dictionary. Place a stub here.
; TODO remove this when the dictionary is collapsed into a single module.
PUBLIC RFETCH_CFA
	nop
ENDPUBLIC

enter:	.asciiz "math test - enter!"
exit:	.asciiz "math test - exit!"

.proc plusTest
	lda #255
	PUSH
	lda #1025
	PUSH
	jsr PLUS_CODE
	PRINTLN_POP plus1
	rts
.endproc
plus1:	.asciiz "+ test 255 + 1025 = "

.proc minusTest
	lda #1025
	PUSH
	lda #255
	PUSH
	jsr MINUS_CODE
	PRINTLN_POP minus1
	rts
.endproc
minus1:	.asciiz "- test 1025 - 255 = "

.proc starTest
	lda #1025
	PUSH
	lda #255
	PUSH
	jsr STAR_CODE
	PRINTLN_POP star1
	rts
.endproc
star1:	.asciiz "* test 1025 * 255 = "

.proc umStarTest
	lda #1025
	PUSH
	lda #255
	PUSH
	jsr UMSTAR_CODE
	PRINTLN_POP umstar1
	PRINTLN_POP umstar2
	rts
.endproc
umstar1:
	.asciiz "UM* test 1025 * 255 High = "
umstar2:
	.asciiz "UM* test 1025 * 255 Low = "

.proc umSlashModTest
	lda #$0009
	PUSH
	lda #$27C0
	PUSH
	lda #10
	PUSH
	jsr UMSLASHMOD_CODE
	PRINTLN_POP umslashmod1
	PRINTLN_POP umslashmod2
	rts
.endproc
umslashmod1:
	.asciiz "UM/MOD test 1025 * 255 = "
umslashmod2:
	.asciiz "UM/MOD test remainder = "

.proc slashModTest
	lda #32768
	PUSH
	lda #10
	PUSH
	jsr SLASHMOD_CODE
	PRINTLN_POP slashmod1
	PRINTLN_POP slashmod2
	rts
.endproc
slashmod1:
	.asciiz "/MOD test 1025 /MOD 255 = "
slashmod2:
	.asciiz "/MOD test remainder = "

.proc slashTest
	lda #32768
	PUSH
	lda #10
	PUSH
	jsr SLASH_CODE
	rts
.endproc
slash1:
	.asciiz "/ test 32768 / 10 = "

.proc modTest
	jsr MOD_CODE
	rts
.endproc
mod1:
	.asciiz "/MOD test 1025 /MOD 255 = "

.proc negateTest
	lda #$ffe0
	PUSH
	jsr NEGATE_CODE
	PRINTLN_POP negate1

	lda #$00e0
	PUSH
	jsr NEGATE_CODE
	PRINTLN_POP negate2
	rts
.endproc
negate1:
	.asciiz "NEGATE test $ffe0 = "
negate2:
	.asciiz "NEGATE test $00e0 = "

.proc absTest
	lda #$ffe0
	PUSH
	jsr ABS_CODE
	PRINTLN_POP abs1

	lda #$00e0
	PUSH
	jsr ABS_CODE
	PRINTLN_POP abs2
	rts
.endproc
abs1:	.asciiz "ABS test $ffe0 = "
abs2:	.asciiz "ABS test $00e0 = "

.proc maxTest
	lda #$0032
	PUSH
	lda #$1032
	PUSH
	jsr MAX_CODE
	PRINTLN_POP max1
	rts
.endproc
max1:	.asciiz "MAX test $0032 $1032 = "

.proc minTest
	lda #$0032
	PUSH
	lda #$1032
	PUSH
	jsr MIN_CODE
	PRINTLN_POP min1
	rts
.endproc
min1:	.asciiz "MIN test $0032 $1032 = "

.proc onePlusTest
	lda #$1032
	PUSH
	jsr ONEPLUS_CODE
	PRINTLN_POP onePlus1
.endproc
onePlus1:
	.asciiz "1+ test $1032 = "

.proc oneMinusTest
	lda #$0537
	PUSH
	jsr ONEMINUS_CODE
	PRINTLN_POP twoStar1
.endproc
oneMinus1:
	.asciiz "1- test $0537 = "

.proc twoStarTest
	lda #$0537
	PUSH
	jsr TWOSTAR_CODE
	PRINTLN_POP twoStar1
.endproc
twoStar1:
	.asciiz "2* test $0537 = "

.proc twoSlashTest
	lda #$0537
	PUSH
	jsr TWOSLASH_CODE
	PRINTLN_POP twoSlash1
	rts
.endproc
twoSlash1:
	.asciiz "2/ test $0537 = "
