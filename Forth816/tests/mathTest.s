; -----------------------------------------------------------------------------
; mathTest - Mathematics unit test
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

.import PLUS_CODE
.import MINUS_CODE
.import STAR_CODE
.import UMSTAR_CODE
.import UMSLASHMOD_CODE
.import SLASHMOD_CODE
.import SLASH_CODE
.import MOD_CODE
.import NEGATE_CODE
.import ABS_CODE
.import MAX_CODE
.import MIN_CODE
.import ONEPLUS_CODE
.import ONEMINUS_CODE
.import TWOSTAR_CODE
.import TWOSLASH_CODE

; Main entry point for the test
PUBLIC MAIN
	PRINTLN enter

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
	rts
ENDPUBLIC

enter:	.asciiz "math test - enter!"
exit:	.asciiz "math test - exit!"

.proc plusTest
	lda #$255
	PUSH
	lda #$1025
	PUSH
	jsr PLUS_CODE
	PRINTLN_POP plus1
	rts
.endproc
plus1:	.asciiz "+ test $255 + $1025 (expect 127A) = "

.proc minusTest
	lda #$1025
	PUSH
	lda #$255
	PUSH
	jsr MINUS_CODE
	PRINTLN_POP minus1
	rts
.endproc
minus1:	.asciiz "- test $1025 - $255 (expect 0DD0) = "

.proc starTest
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr STAR_CODE
	PRINTLN_POP star1
	rts
.endproc
star1:	.asciiz "* test $1025 * $0014 (expect 42E4) = "

.proc umStarTest
	lda #$1025
	PUSH
	lda #$255
	PUSH
	jsr UMSTAR_CODE
	PRINTLN_POP umstar1
	PRINTLN_POP umstar2
	rts
.endproc
umstar1:
	.asciiz "UM* test $1025 * $255 High (expect 0025) = "
umstar2:
	.asciiz "UM* test $1025 * $255 Low (expect A649) = "

.proc umSlashModTest
	lda #$0009
	PUSH
	lda #$27C0
	PUSH
	lda #$0A
	PUSH
	jsr UMSLASHMOD_CODE
	PRINTLN_POP umslashmod1
	PRINTLN_POP umslashmod2
	rts
.endproc
umslashmod1:
	.asciiz "UM/MOD test $000927C0 / $0A (expect EA60) = "
umslashmod2:
	.asciiz "UM/MOD test remainder (expect 0000) = "

.proc slashModTest
	lda #$8000
	PUSH
	lda #$0A
	PUSH
	jsr SLASHMOD_CODE
	PRINTLN_POP slashmod1
	PRINTLN_POP slashmod2
	rts
.endproc
slashmod1:
	.asciiz "/MOD test $8000 /MOD $0A (expect 0CCC) = "
slashmod2:
	.asciiz "/MOD test remainder (expect 0008) = "

.proc slashTest
	lda #$777
	PUSH
	lda #$0A
	PUSH
	jsr SLASH_CODE
	rts
.endproc
slash1:
	.asciiz "/ test $777 / $0A (expect 00BF) = "

.proc modTest
	lda #$777
	PUSH
	lda #$0A
	PUSH
	jsr MOD_CODE
	rts
.endproc
mod1:
	.asciiz "MOD test $777 MOD $0A (expect 0001) = "

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
	.asciiz "NEGATE test $ffe0 (expect 0020) = "
negate2:
	.asciiz "NEGATE test $00e0 (expect FF20) = "

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
abs1:	.asciiz "ABS test $ffe0 (expect 0020) = "
abs2:	.asciiz "ABS test $00e0 (expect 00E0) = "

.proc maxTest
	lda #$0032
	PUSH
	lda #$1032
	PUSH
	jsr MAX_CODE
	PRINTLN_POP max1
	rts
.endproc
max1:	.asciiz "MAX test $0032 $1032 (expect 1032) = "

.proc minTest
	lda #$0032
	PUSH
	lda #$1032
	PUSH
	jsr MIN_CODE
	PRINTLN_POP min1
	rts
.endproc
min1:	.asciiz "MIN test $0032 $1032 (expect 0032) = "

.proc onePlusTest
	lda #$1032
	PUSH
	jsr ONEPLUS_CODE
	PRINTLN_POP onePlus1
	rts
.endproc
onePlus1:
	.asciiz "1+ test $1032 (expect 1033) = "

.proc oneMinusTest
	lda #$0537
	PUSH
	jsr ONEMINUS_CODE
	PRINTLN_POP oneMinus1
	rts
.endproc
oneMinus1:
	.asciiz "1- test $0537 (expect 0536) = "

.proc twoStarTest
	lda #$0537
	PUSH
	jsr TWOSTAR_CODE
	PRINTLN_POP twoStar1
	rts
.endproc
twoStar1:
	.asciiz "2* test $0537 (expect 0A6E) = "

.proc twoSlashTest
	lda #$0537
	PUSH
	jsr TWOSLASH_CODE
	PRINTLN_POP twoSlash1
	rts
.endproc
twoSlash1:
	.asciiz "2/ test $0537 (expect 029B) = "
