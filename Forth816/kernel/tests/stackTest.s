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

.import DUP_CODE
.import DROP_CODE
.import SWAP_CODE
.import OVER_CODE
.import ROT_CODE
.import NIP_CODE
.import TUCK_CODE
.import TWODROP_CODE
.import TWODUP_CODE
.import TWOSWAP_CODE
.import TWOOVER_CODE
.import DEPTH_CODE
.import PICK_CODE
.import TOR_CODE
.import RFROM_CODE
.import RFETCH_CODE

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "stack test - enter!"

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
	; At present these tests fail because debug RTS in TOR_CODE will fail
	; jsr rFromTest
	; jsr rFetchTest

	TYPESTRCR "stack test - exit!"
	rts
ENDPUBLIC

.proc dupTest
	lda #32
	PUSH
	jsr DUP_CODE

	jsr DEPTH_CODE
	TYPESTR_DOT "dup test depth (expect 2) = "
	TYPESTR_DOT "dup test pop (expect 32) = "
	TYPESTR_DOT "dup test pop (expect 32) = "
	rts
.endproc

.proc dropTest
	lda #32
	PUSH
	lda #32
	PUSH
	jsr DEPTH_CODE
	TYPESTR_DOT "drop test depth (expect 2) = "
	jsr DROP_CODE
	jsr DROP_CODE
	jsr DEPTH_CODE
	TYPESTR_DOT "drop test depth (expect 0) = "
	rts
.endproc

.proc swapTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr SWAP_CODE
	TYPESTR_DOT "swap test pop (expect 1) = "
	TYPESTR_DOT "swap test pop (expect 2) = "
	rts
.endproc

.proc overTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr OVER_CODE

	TYPESTR_DOT "over test pop (expect 1) = "
	TYPESTR_DOT "over test pop (expect 2) = "
	TYPESTR_DOT "over test pop (expect 1) = "

	rts
.endproc

.proc rotTest
	lda #1
	PUSH
	lda #2
	PUSH
	lda #3
	PUSH
	jsr ROT_CODE

	TYPESTR_DOT "rot test pop (expect 1) = "
	TYPESTR_DOT "rot test pop (expect 3) = "
	TYPESTR_DOT "rot test pop (expect 2) = "

	rts
.endproc

.proc nipTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr NIP_CODE

	TYPESTR_DOT "nip test pop (expect 2) = "

	jsr DEPTH_CODE
	TYPESTR_DOT "nip test pop (expect 0) = "

	rts
.endproc

.proc tuckTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr TUCK_CODE

	TYPESTR_DOT "tuck test (expect 2) = "
	TYPESTR_DOT "tuck test (expect 1) = "
	TYPESTR_DOT "tuck test (expect 2) = "
	rts
.endproc

.proc twoDropTest
	lda #1
	PUSH
	lda #1
	PUSH
	lda #2
	PUSH
	lda #2
	PUSH

	jsr TWODROP_CODE

	TYPESTR_DOT "2DROP test (expect 1) = "
	TYPESTR_DOT "2DROP test (expect 1) = "
	rts
.endproc

.proc twoDupTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr TWODUP_CODE
	TYPESTR_DOT "2DUP test (expect 2) = "
	TYPESTR_DOT "2DUP test (expect 1) = "
	TYPESTR_DOT "2DUP test (expect 2) = "
	TYPESTR_DOT "2DUP test (expect 1) = "
	rts
.endproc

.proc twoSwapTest
	lda #$1
	PUSH
	lda #$2
	PUSH
	lda #$3
	PUSH
	lda #$4
	PUSH
	jsr TWOSWAP_CODE
	TYPESTR_DOT "2SWAP test (expect 2) = "
	TYPESTR_DOT "2SWAP test (expect 1) = "
	TYPESTR_DOT "2SWAP test (expect 4) = "
	TYPESTR_DOT "2SWAP test (expect 3) = "

	rts
.endproc

.proc twoOverTest
	lda #$1
	PUSH
	lda #$2
	PUSH
	lda #$3
	PUSH
	lda #$4
	PUSH
	jsr TWOOVER_CODE
	TYPESTR_DOT "2OVER test (expect 2) = "
	TYPESTR_DOT "2OVER test (expect 1) = "
	TYPESTR_DOT "2OVER test (expect 4) = "
	TYPESTR_DOT "2OVER test (expect 3) = "
	TYPESTR_DOT "2OVER test (expect 2) = "
	TYPESTR_DOT "2OVER test (expect 1) = "
	rts
.endproc

.proc depthTest
	lda #1
	PUSH
	lda #2
	PUSH

	jsr DEPTH_CODE
	TYPESTR_DOT "DEPTH test (expect 2) = "
	POP
	POP
	rts
.endproc

.proc pickTest
	lda #1
	PUSH
	lda #2
	PUSH
	lda #3
	PUSH
	lda #2
	PUSH
	jsr PICK_CODE
	TYPESTR_DOT "PICK test (expect 1) = "
	POP
	POP
	POP
	rts
.endproc

; CFA used to handle the NEXT at the end of code were testing.
TORTESTCFA_LIST:
	.word RTEST_CFA
HEADER "RTS", RTEST_ENTRY, RTEST_CFA, 0, 0
CODEPTR RTEST_CODE
PUBLIC  RTEST_CODE
	pla			; pull the item pushed by the pimitive
	PUSH			; push it onto the parameter stack
	rts
ENDPUBLIC

.proc toRTest
	phy			; save unit test IP list
	ldy #TORTESTCFA_LIST
	lda #32
	PUSH
	jsr TOR_CODE
	ply
	TYPESTR_DOT ">R test (expect 32) = "
	rts
.endproc

.proc rFromTest
	lda #32
	pha
	jsr RFROM_CODE
	TYPESTR_DOT "R> test - "
	rts
.endproc

.proc rFetchTest
	lda #32
	pha
	jsr RFETCH_CODE
	TYPESTR_DOT "R@ test - "
	pla
	rts
.endproc
