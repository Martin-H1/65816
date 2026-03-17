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
.proc main
	ON16MEM
	ON16X
	PRINTCR
	PRINTLN enter
	ldx #PSP_INIT

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
	jsr rFromTest
	jsr rFetchTest

	PRINTLN exit
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
	POP_PRINTCR dup1
	POP_PRINTCR dup2
	POP_PRINTCR dup2
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
	POP_PRINTCR drop1
	POP
	POP
	jsr DEPTH_CODE
	POP_PRINTCR drop1
	rts
.endproc
drop1:	.asciiz "drop test depth = "

.proc swapTest
	lda #1
	PUSH
	lda #2
	PUSH
	jsr SWAP_CODE
	POP_PRINTCR swaptest1
	POP_PRINTCR swaptest1
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

	POP_PRINTCR overtest1
	PUSH

	POP_PRINTCR overtest1
	POP_PRINTCR overtest1

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

	POP_PRINTCR rottest1
	POP_PRINTCR rottest1
	POP_PRINTCR rottest1

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

	POP_PRINTCR niptest1

	jsr DEPTH_CODE
	POP_PRINTCR niptest1

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

	POP_PRINTCR tuck1
	POP_PRINTCR tuck1
	POP_PRINTCR tuck1
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

	POP_PRINTCR twodrop1
	POP_PRINTCR twodrop1
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
	POP_PRINTCR twodup1
	POP_PRINTCR twodup1
	POP_PRINTCR twodup1
	POP_PRINTCR twodup1
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
	POP_PRINTCR twoswap1
	POP_PRINTCR twoswap1
	POP_PRINTCR twoswap1
	POP_PRINTCR twoswap1

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
	POP_PRINTCR twoover1
	POP_PRINTCR twoover1
	POP_PRINTCR twoover1
	POP_PRINTCR twoover1
	POP_PRINTCR twoover1
	POP_PRINTCR twoover1
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
	POP_PRINTCR depth1
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
	POP_PRINTCR pick1
	POP
	POP
	POP
	rts
.endproc
pick1:
	.asciiz "PICK test - "

.proc toRTest
	lda #32
	PUSH
	jsr TOR_CODE
	PRINT tor1
	pla
	PRINTC
	PRINTCR
	rts
.endproc
tor1:
	.asciiz ">R test - "

.proc rFromTest
	lda #32
	pha
	jsr RFROM_CODE
	POP_PRINTCR rfrom1
	rts
.endproc
rfrom1:
	.asciiz "R> test - "

.proc rFetchTest
	lda #32
	pha
	jsr RFETCH_CODE
	POP_PRINTCR rfrom1
	pla
	rts
.endproc
rfetch1:
	.asciiz "R@ test - "
