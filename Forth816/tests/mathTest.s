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
	rts
.endproc
umstar1:
	.asciiz "UM* test 1025 * 255 = "

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
	jsr SLASHMOD_CODE
	rts
.endproc
slashmod1:
	.asciiz "/MOD test 1025 /MOD 255 = "
slashmod2:
	.asciiz "/MOD test remainder = "

.proc slashTest
	jsr SLASH_CODE
	rts
.endproc

.proc modTest
	jsr MOD_CODE
	rts
.endproc

.proc negateTest
	jsr NEGATE_CODE
	rts
.endproc

.proc absTest
	jsr ABS_CODE
	rts
.endproc

.proc maxTest
	jsr MAX_CODE
	rts
.endproc

.proc minTest
	jsr MIN_CODE
	rts
.endproc

.proc onePlusTest
	jsr ONEPLUS_CODE
.endproc

.proc oneMinusTest
	jsr ONEMINUS_CODE
.endproc

.proc twoStarTest
	jsr TWOSTAR_CODE
.endproc

.proc twoSlashTest
	jsr TWOSLASH_CODE	
	rts
.endproc
