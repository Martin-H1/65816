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
.include "macrosdbg.inc"

.import PLUS_CODE
.import MINUS_CODE
.import STAR_CODE
.import UMSTAR_CODE
.import UMSLASHMOD_CODE
.import SLASHMOD_CODE
.import NEGATE_CODE
.import ABS_CODE
.import MAX_CODE
.import MIN_CODE
.import ONEPLUS_CODE
.import ONEMINUS_CODE
.import TWOSTAR_CODE
.import TWOSLASH_CODE

.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "math test - enter!"
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

	TYPESTRCR "math test - exit!"
	rts
ENDPUBLIC

.proc plusTest
	lda #597
	PUSH
	lda #4133
	PUSH
	jsr PLUS_CODE
	TYPESTR_DOT "+ test 597 + 4133 (expect 4730) = "
	rts
.endproc

.proc minusTest
	lda #4133
	PUSH
	lda #597
	PUSH
	jsr MINUS_CODE
	TYPESTR_DOT "- test 4133 - 597 (expect 3536) = "
	rts
.endproc

.proc starTest
	lda #4133
	PUSH
	lda #7
	PUSH
	jsr STAR_CODE
	TYPESTR_DOT "* test 4133 * 7 (expect 28931) = "
	lda #4133
	PUSH
	lda #$fffd
	PUSH
	jsr STAR_CODE
	TYPESTR_DOT "* test 4133 * -3 (expect -12399) = "
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr STAR_CODE
	TYPESTR_DOT "* test -3 * -3 (expect 9) = "
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr STAR_CODE
	TYPESTR_DOT "* test -3 * 20 (expect -60) = "
	rts
.endproc

.proc umStarTest
	lda #4133
	PUSH
	lda #20
	PUSH
	jsr UMSTAR_CODE
	TYPESTR_UDOT "UM* test 4133 * 20 HIGH (expect 1) = "
	TYPESTR_UDOT "UM* test 4133 * 20 LOW (expect 17124) = "
	lda #4133
	PUSH
	lda #65533
	PUSH
	jsr UMSTAR_CODE
	TYPESTR_UDOT "UM* test 4133 * 65533 HIGH (expect 4132) = "
	TYPESTR_UDOT "UM* test 4133 * 65533 LOW (expect 53137) = "
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr UMSTAR_CODE
	TYPESTR_UDOT "UM* test 65533 * 65533 HIGH (expect 65530) = "
	TYPESTR_UDOT "UM* test 65533 * 65533 LOW (expect 9) = "
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr UMSTAR_CODE
	TYPESTR_UDOT "UM* test $fffd * $0014 HIGH (expect 0013) = "
	TYPESTR_UDOT "UM* test $fffd * $0014 LOW (expect FFC4) = "
	rts
.endproc

.proc umSlashmodTest
	lda #$0000
	PUSH
	lda #$1025
	PUSH
	lda #$14
	PUSH
	jsr UMSLASHMOD_CODE
	TYPESTR_UDOT "UM/MOD test $00001025 UM/MOD $0014 HIGH (expect 00CE) = "
	TYPESTR_UDOT "UM/MOD test $00001025 UM/MOD $0014 LOW (expect 000D) = "
	lda #$0000
	PUSH
	lda #$1025
	PUSH
	lda #$fffd
	PUSH
	jsr UMSLASHMOD_CODE
	TYPESTR_UDOT "UM/MOD test $00001025 UM/MOD $fffd HIGH (expect 0000) = "
	TYPESTR_UDOT "UM/MOD test $00001025 UM/MOD $fffd LOW (expect 1025) = "
	lda #$0009
	PUSH
	lda #$0e79
	PUSH
	lda #$fffd
	PUSH
	jsr UMSLASHMOD_CODE
	TYPESTR_UDOT "UM/MOD test $00090E70 UM/MOD $fffd HIGH (expect 0009) = "
	TYPESTR_UDOT "UM/MOD test $00090E70 UM/MOD $fffd LOW (expect 0E8B) = "
	lda #$ffff
	PUSH
	lda #$fffd
	PUSH
	lda #$14
	PUSH
	jsr UMSLASHMOD_CODE
	TYPESTR_UDOT "UM/MOD test $fffffffd UM/MOD $0014 HIGH (expect FFC4) = "
	TYPESTR_UDOT "UM/MOD test $fffffffd UM/MOD $0014 LOW (expect FFC4) = "
	rts
.endproc

.proc slashmodTest
	lda #4133
	PUSH
	lda #20
	PUSH
	jsr SLASHMOD_CODE
	TYPESTR_DOT "/MOD test 4133 /MOD 20 HIGH (expect 206) = "
	TYPESTR_DOT "/MOD test 4133 /MOD 20 LOW (expect 13) = "
	lda #4133
	PUSH
	lda #$fffd
	PUSH
	jsr SLASHMOD_CODE
	TYPESTR_DOT "/MOD test 4133 /MOD -3 HIGH (expect -1377) = "
	TYPESTR_DOT "/MOD test 4133 /MOD -3 LOW (expect -1) = "
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	jsr SLASHMOD_CODE
	TYPESTR_DOT "/MOD test -3 /MOD -3 HIGH (expect 0001) = "
	TYPESTR_DOT "/MOD test -3 /MOD -3 LOW (expect 0000) = "
	lda #$fffd
	PUSH
	lda #20
	PUSH
	jsr SLASHMOD_CODE
	TYPESTR_DOT "/MOD test -3 /MOD 20 HIGH (expect 0000) = "
	TYPESTR_DOT "/MOD test -3 /MOD 20 LOW (expect 17) = "
	rts
.endproc

.proc slashTest
	lda #4133
	PUSH
	lda #20
	PUSH
	CALL_DOCOL SLASH_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "/ test 4133 / 20 (expect 206) = "
	lda #4133
	PUSH
	lda #$fffd
	PUSH
	CALL_DOCOL SLASH_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "/ test 4133 / -3 (expect -1377) = "
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	CALL_DOCOL SLASH_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "/ test -3 / -3 (expect 1) = "
	lda #$fffd
	PUSH
	lda #20
	PUSH
	CALL_DOCOL SLASH_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "/ test -3 / 20 (expect 0) = "
	lda #$fffd
	PUSH
	lda #$1
	PUSH
	CALL_DOCOL SLASH_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "/ test -3 / 1 (expect -3) = "
	rts
.endproc

.proc modTest
	lda #$1025
	PUSH
	lda #20
	PUSH
	CALL_DOCOL MOD_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "MOD test 4133 MOD 20 (expect 13) = "
	lda #$4133
	PUSH
	lda #$fffd
	PUSH
	CALL_DOCOL MOD_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "MOD test 4133 MOD -3 (expect -1) = "
	lda #$fffd
	PUSH
	lda #$fffd
	PUSH
	CALL_DOCOL MOD_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "MOD test -3 MOD -3 (expect 0) = "
	lda #$fffd
	PUSH
	lda #20
	PUSH
	CALL_DOCOL MOD_CFA    ; RTS_CFA will return here.
	TYPESTR_DOT "MOD test -3 MOD 20 (expect 17) = "
	rts
.endproc

.proc negateTest
	lda #$ffe0
	PUSH
	jsr NEGATE_CODE
	TYPESTR_DOT "NEGATE test -32 (expect 32) = "

	lda #224
	PUSH
	jsr NEGATE_CODE
	TYPESTR_DOT "NEGATE test 224 (expect -224) = "
	rts
.endproc

.proc absTest
	lda #$ffe0
	PUSH
	jsr ABS_CODE
	TYPESTR_DOT "ABS test -32 (expect 32) = "

	lda #224
	PUSH
	jsr ABS_CODE
	TYPESTR_DOT "ABS test 224 (expect 224) = "
	rts
.endproc

.proc maxTest
	lda #50
	PUSH
	lda #4146
	PUSH
	jsr MAX_CODE
	TYPESTR_DOT "MAX test 50 4146 (expect 4146) = "
	rts
.endproc

.proc minTest
	lda #50
	PUSH
	lda #4146
	PUSH
	jsr MIN_CODE
	TYPESTR_DOT "MIN test 50 41146 (expect 50) = "
	rts
.endproc

.proc onePlusTest
	lda #4146
	PUSH
	jsr ONEPLUS_CODE
	TYPESTR_DOT "1+ test 4146 (expect 4147) = "
	rts
.endproc

.proc oneMinusTest
	lda #1335
	PUSH
	jsr ONEMINUS_CODE
	TYPESTR_DOT "1- test 1335 (expect 1334) = "
	rts
.endproc

.proc twoStarTest
	lda #$0537
	PUSH
	jsr TWOSTAR_CODE
	TYPESTR_DOTHEX "2* test $0537 (expect 0A6E) = "
	rts
.endproc

.proc twoSlashTest
	lda #$0537
	PUSH
	jsr TWOSLASH_CODE
	TYPESTR_DOTHEX "2/ test $0537 (expect 029B) = "
	rts
.endproc
