; -----------------------------------------------------------------------------
; memoryTest - unit test for meemory.s module
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

.import FETCH_CODE
.import STORE_CODE
.import CFETCH_CODE
.import CSTORE_CODE
.import TWOFETCH_CODE
.import TWOSTORE_CODE
.import MOVE_CODE
.import FILL_CODE

; Main entry point for the test
PUBLIC MAIN
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
	.asciiz "@ test output (expect BEEF) = "

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
	.asciiz "! test output (expect FEED) = "

.proc cfetchTest
	lda #cfetch1
	PUSH
	jsr CFETCH_CODE
	PRINTLN_POP cfetch1
	rts
.endproc
cfetch1:
	.asciiz "C@ test output (expect C 0043) = "

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
	.asciiz "C! test output (expect FF24) = "

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
	.asciiz "2@ test output (expect BEEF, FEED) = "

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
	.asciiz "2! test (expect FEED, BEEF) = "

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
	.byte "MOVE test (expect original) = "
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
	.byte "FILL test (expect $$$$$$$$) = "
filldst2:
	.asciiz "        "
