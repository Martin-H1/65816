; -----------------------------------------------------------------------------
; compareTest - Hello World sample for the Mench Reloaded SBC.
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "forth.inc"
.include "hal.inc"
.include "macros.inc"
.include "print.inc"
.include "stack.inc"

; Main entry point for the test
PUBLIC main
	PRINTLN enter

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

	PRINTLN exit
	rts
ENDPUBLIC

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

	;; temp debug code start
	PUSH
	PRINTLN_POP msg1
	TYA
	PUSH
	PRINTLN_POP msg2
	lda W
	PUSH
	PRINTLN_POP msg3
	lda (W)
	PRINTLN_POP msg4
	sta SCRATCH0
	lda (SCRATCH0)
	PRINTLN_POP msg5
	rts
msg1:	.asciiz "C = "
msg2:	.asciiz "Y = "
msg3:	.asciiz "W = "
msg4:	.asciiz "(W) = "
msg5:	.asciiz "(SCRATCH0) = "
	;; temp debug code end

	jsr DEPTH_CODE
	PRINTLN_POP dup1
	PRINTLN_POP dup2
	PRINTLN_POP dup2
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
	PRINTLN_POP drop1
	jsr DROP_CODE
	jsr DROP_CODE
	jsr DEPTH_CODE
	PRINTLN_POP drop1
	rts
.endproc
drop1:	.asciiz "drop test depth = "

.proc swapTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr SWAP_CODE
	PRINTLN_POP swaptest1
	PRINTLN_POP swaptest1
	rts
.endproc
swaptest1:
	.asciiz "swap test pop = "

.proc overTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr OVER_CODE

	PRINTLN_POP overtest1
	PRINTLN_POP overtest1
	PRINTLN_POP overtest1

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

	PRINTLN_POP rottest1
	PRINTLN_POP rottest1
	PRINTLN_POP rottest1

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

	PRINTLN_POP niptest1

	jsr DEPTH_CODE
	PRINTLN_POP niptest1

	rts
.endproc
niptest1:
	.asciiz "nip test pop = "

.proc tuckTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr TUCK_CODE

	PRINTLN_POP tuck1
	PRINTLN_POP tuck1
	PRINTLN_POP tuck1
	rts
.endproc
tuck1:	.asciiz "tuck test - "

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

	PRINTLN_POP twodrop1
	PRINTLN_POP twodrop1
	rts
.endproc
twodrop1:
	.asciiz "2DROP test - "

.proc twoDupTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr TWODUP_CODE
	PRINTLN_POP twodup1
	PRINTLN_POP twodup1
	PRINTLN_POP twodup1
	PRINTLN_POP twodup1
	rts
.endproc
twodup1:
	.asciiz "2DUP test - "

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
	PRINTLN_POP twoswap1
	PRINTLN_POP twoswap1
	PRINTLN_POP twoswap1
	PRINTLN_POP twoswap1

	rts
.endproc
twoswap1:
	.asciiz "2SWAP test - "

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
	PRINTLN_POP twoover1
	PRINTLN_POP twoover1
	PRINTLN_POP twoover1
	PRINTLN_POP twoover1
	PRINTLN_POP twoover1
	PRINTLN_POP twoover1
	rts
.endproc
twoover1:
	.asciiz "2OVER test - "

.proc depthTest
	lda #1
	PUSH
	lda #2
	PUSH

	jsr DEPTH_CODE
	PRINTLN_POP depth1
	POP
	POP
	rts
.endproc
depth1:	.asciiz "DEPTH test - "

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
	PRINTLN_POP pick1
	POP
	POP
	POP
	rts
.endproc
pick1:
	.asciiz "PICK test - "

; CFA used to handle the NEXT at the end of code were testing.
TORTESTCFA_LIST:
	.word RTEST_CFA
HEADER "RTS", RTEST_CFA, 0, 0
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
	PRINTLN_POP tor1
	ply
	rts
.endproc
tor1:
	.asciiz ">R test - "

.proc rFromTest
	lda #32
	pha
	jsr RFROM_CODE
	PRINTLN_POP rfrom1
	rts
.endproc
rfrom1:
	.asciiz "R> test - "

.proc rFetchTest
	lda #32
	pha
	jsr RFETCH_CODE
	PRINTLN_POP rfrom1
	pla
	rts
.endproc
rfetch1:
	.asciiz "R@ test - "
