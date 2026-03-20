; -----------------------------------------------------------------------------
; memoryTest - unit test for meemory.s module
; Martin Heermance <mheermance@gmail.com>
; -----------------------------------------------------------------------------

.include "ascii.inc"
.include "forth.inc"
.include "hal.inc"
.include "macros.inc"
.include "memory.inc"
.include "print.inc"

; Main entry point for the test
PUBLIC main
	PRINTLN enter

	jsr fetchTest
	jsr storeTest
	jsr cfetchTest
	jsr cstoreTest
	jsr twoFetchTest
	jsr twoStoreTest
	jsr moveTest
	jsr fillTest
	
	PRINTLN exit
	rts
ENDPUBLIC

; These are stubs are to allow the binary to link.
; TODO find a way to gather these into a stubs file
PUBLIC RSHIFT_CFA
	nop
ENDPUBLIC
PUBLIC LAST_WORD
	nop
ENDPUBLIC
PUBLIC QUIT_CFA
	nop
ENDPUBLIC

enter:	.asciiz "memory test - enter!"
exit:	.asciiz "memory test - exit!"


.proc fetchTest
	lda #fetch1
	PUSH
	jsr FETCH_CODE
	PRINTLN_POP fetch2
	rts
.endproc
fetch1:
	.word $beef
fetch2:
	.asciiz "@ test output (expected BEEF) = "

.proc storeTest
	lda #$feed
	PUSH
	lda #store1
	PUSH
	jsr STORE_CODE
	lda store1
	PUSH
	PRINTLN_POP store2
	rts
.endproc
store1:
	.word $beef
store2:
	.asciiz "! test output (expected FEED) = "

.proc cfetchTest
	lda #cfetch1
	PUSH
	jsr CFETCH_CODE
	PRINTLN_POP cfetch1
	rts
.endproc
cfetch1:
	.asciiz "C@ test output (expected C 0043) = "

.proc cstoreTest
	lda #'$'
	PUSH
	lda #cstore1
	PUSH
	jsr CSTORE_CODE
	lda cstore1
	PUSH
	PRINTLN_POP cstore2
	rts
.endproc
cstore1:
	.word $FFFF
cstore2:
	.asciiz "C! test output (expected FF24) = "

.proc twoFetchTest
	lda #twofetch1
	PUSH
	jsr TWOFETCH_CODE
	PRINTLN_POP twofetch2
	PRINTLN_POP twofetch2
	rts
.endproc
twofetch1:
	.word $FEED, $BEEF
twofetch2:
	.asciiz "2@ test output (exepcted BEEF, FEED) = "

.proc twoStoreTest
	lda #$feed
	PUSH
	lda #$beef
	PUSH
	lda #twostore1
	PUSH
	jsr TWOSTORE_CODE
	lda twostore1
	PUSH
	lda twostore1+2
	PUSH
	PRINTLN_POP twostore2
	PRINTLN_POP twostore2
	rts
.endproc
twostore1:
	.word $0000, $0000
twostore2:
	.asciiz "2! test (exepcted FEED, BEEF) = "

.proc moveTest
	lda #movesrc
	PUSH
	lda #movedst2
	PUSH
	lda #$0008
	PUSH
	jsr MOVE_CODE
	PRINTLN movedst1
	rts
.endproc
movesrc:
	.asciiz "original"
movedst1:
	.byte "MOVE test (expected original) = "
movedst2:
	.asciiz "        "

.proc fillTest
	lda #filldst2
	PUSH
	lda #$0008
	PUSH
	lda #'$'
	PUSH
	jsr FILL_CODE
	PRINTLN filldst1
	rts
.endproc
filldst1:
	.byte "FILL test (expected $$$$$$$$) = "
filldst2:
	.asciiz "        "
