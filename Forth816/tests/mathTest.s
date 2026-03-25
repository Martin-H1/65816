; -----------------------------------------------------------------------------
; mathTest - Mathematics unit test
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
	jsr umSlashmodTest
	jsr slashmodTest
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
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr STAR_CODE
	PRINTLN_POP star2
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr STAR_CODE
	PRINTLN_POP star3
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr STAR_CODE
	PRINTLN_POP star4
	rts
.endproc
star1:	.asciiz "* test $1025 * $0014 (expect 42E4) = "
star2:	.asciiz "* test $1025 * $fffd (expect CF91) = "
star3:	.asciiz "* test $fffd * $fffd (expect 0009) = "
star4:	.asciiz "* test $fffd * $0014 (expect FFC4) = "

.proc umStarTest
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr UMSTAR_CODE
	PRINTLN_POP umstar11
	PRINTLN_POP umstar12
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr UMSTAR_CODE
	PRINTLN_POP umstar21
	PRINTLN_POP umstar22
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr UMSTAR_CODE
	PRINTLN_POP umstar31
	PRINTLN_POP umstar32
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr UMSTAR_CODE
	PRINTLN_POP umstar41
	PRINTLN_POP umstar42
	rts
.endproc
umstar11:	.asciiz "UM* test $1025 * $0014 HIGH (expect 0000) = "
umstar12:	.asciiz "UM* test $1025 * $0014 LOW (expect 42E4) = "
umstar21:	.asciiz "UM* test $1025 * $fffd HIGH (expect 1024) = "
umstar22:	.asciiz "UM* test $1025 * $fffd LOW (expect CF91) = "
umstar31:	.asciiz "UM* test $fffd * $fffd HIGH (expect FFFA) = "
umstar32:	.asciiz "UM* test $fffd * $fffd LOW (expect 0009) = "
umstar41:	.asciiz "UM* test $fffd * $0014 HIGH (expect 0013) = "
umstar42:	.asciiz "UM* test $fffd * $0014 LOW (expect FFC4) = "

.proc umSlashmodTest
	lda #$0000
	PUSH
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr UMSLASHMOD_CODE
	PRINTLN_POP umslashmod11
	PRINTLN_POP umslashmod12
	lda #$0000
	PUSH
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr UMSLASHMOD_CODE
	PRINTLN_POP umslashmod21
	PRINTLN_POP umslashmod22
	lda #$0009
	PUSH
	lda #$0e79
	PUSH
	lda #$fffd
	PUSH
	jsr UMSLASHMOD_CODE
	PRINTLN_POP umslashmod31
	PRINTLN_POP umslashmod32
	lda #$ffff
	PUSH
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr UMSLASHMOD_CODE
	PRINTLN_POP umslashmod41
	PRINTLN_POP umslashmod42
	rts
.endproc
umslashmod11:	.asciiz "UM/MOD test $00001025 UM/MOD $0014 HIGH (expect 00CE) = "
umslashmod12:	.asciiz "UM/MOD test $00001025 UM/MOD $0014 LOW (expect 000D) = "
umslashmod21:	.asciiz "UM/MOD test $00001025 UM/MOD $fffd HIGH (expect 0000) = "
umslashmod22:	.asciiz "UM/MOD test $00001025 UM/MOD $fffd LOW (expect 1025) = "
umslashmod31:	.asciiz "UM/MOD test $00090E70 UM/MOD $fffd HIGH (expect 0009) = "
umslashmod32:	.asciiz "UM/MOD test $00090E70 UM/MOD $fffd LOW (expect 0E8B) = "
umslashmod41:	.asciiz "UM/MOD test $fffffffd UM/MOD $0014 HIGH (expect FFC4) = "
umslashmod42:	.asciiz "UM/MOD test $fffffffd UM/MOD $0014 LOW (expect FFC4) = "

.proc slashmodTest
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr SLASHMOD_CODE
	PRINTLN_POP slashmod11
	PRINTLN_POP slashmod12
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr SLASHMOD_CODE
	PRINTLN_POP slashmod21
	PRINTLN_POP slashmod22
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr SLASHMOD_CODE
	PRINTLN_POP slashmod31
	PRINTLN_POP slashmod32
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr SLASHMOD_CODE
	PRINTLN_POP slashmod41
	PRINTLN_POP slashmod42
	rts
.endproc
slashmod11:	.asciiz "/MOD test $1025 /MOD $0014 HIGH (expect 00CE) = "
slashmod12:	.asciiz "/MOD test $1025 /MOD $0014 LOW (expect 000D) = "
slashmod21:	.asciiz "/MOD test $1025 /MOD $fffd HIGH (expect FA9E) = "
slashmod22:	.asciiz "/MOD test $1025 /MOD $fffd LOW (expect FFFF = "
slashmod31:	.asciiz "/MOD test $fffd /MOD $fffd HIGH (expect 0001) = "
slashmod32:	.asciiz "/MOD test $fffd /MOD $fffd LOW (expect 0000) = "
slashmod41:	.asciiz "/MOD test $fffd /MOD $0014 HIGH (expect 0000) = "
slashmod42:	.asciiz "/MOD test $fffd /MOD $0014 LOW (expect FFFD) = "

.proc slashTest
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr SLASH_CODE
	PRINTLN_POP slash1
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr SLASH_CODE
	PRINTLN_POP slash2
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr SLASH_CODE
	PRINTLN_POP slash3
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr SLASH_CODE
	PRINTLN_POP slash4
	lda #$fffd
	PUSH
	lda #$1
	PUSH
	jsr SLASH_CODE
	PRINTLN_POP slash5
	rts
.endproc
slash1:	.asciiz "/ test $1025 / $0014 (expect 00CE) = "
slash2:	.asciiz "/ test $1025 / $fffd (expect FA9F) = "
slash3:	.asciiz "/ test $fffd / $fffd (expect 0001) = "
slash4:	.asciiz "/ test $fffd / $0014 (expect 0000) = "
slash5:	.asciiz "/ test $fffd / $0001 (expect fffd) = "

.proc modTest
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr MOD_CODE
	PRINTLN_POP mod1
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr MOD_CODE
	PRINTLN_POP mod2
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr MOD_CODE
	PRINTLN_POP mod3
	lda #$fffd
	PUSH
	lda #$1
	PUSH
	jsr MOD_CODE
	PRINTLN_POP mod4
	rts
.endproc
mod1:	.asciiz "MOD test $1025 MOD $0014 (expect 000D) = "
mod2:	.asciiz "MOD test $1025 MOD $fffd (expect FFFF) = "
mod3:	.asciiz "MOD test $fffd MOD $fffd (expect 0000) = "
mod4:	.asciiz "MOD test $fffd MOD $0014 (expect 0011) = "

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
