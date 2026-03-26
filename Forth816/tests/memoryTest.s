; -----------------------------------------------------------------------------
; memoryTest - unit test for meemory.s module
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
	TYPESTRCR "memory test - enter!"

	jsr fetchTest
	jsr storeTest
	jsr cfetchTest
	jsr cstoreTest
	jsr twoFetchTest
	jsr twoStoreTest
	jsr moveTest
	jsr fillTest

	TYPESTRCR "memory test - exit!"
	rts
ENDPUBLIC

.proc fetchTest
	lda #fetch1
	PUSH
	jsr FETCH_CODE
	TYPESTR_DOTHEX "@ test output (expect BEEF) = "
	rts
.endproc
fetch1:
	.word $beef

.proc storeTest
	lda #$feed
	PUSH
	lda #store1
	PUSH
	jsr STORE_CODE
	lda store1
	PUSH
	TYPESTR_DOTHEX "! test output (expect FEED) = "
	rts
.endproc
store1:
	.word $beef

.proc cfetchTest
	lda #cfetch1
	PUSH
	jsr CFETCH_CODE
	TYPESTR_DOTHEX "C@ test output (expect C 0043) = "
	rts
.endproc
cfetch1:
	.asciiz "C@"

.proc cstoreTest
	lda #'$'
	PUSH
	lda #cstore1
	PUSH
	jsr CSTORE_CODE
	lda cstore1
	PUSH
	TYPESTR_DOTHEX "C! test output (expect FF24) = "
	rts
.endproc
cstore1:
	.word $FFFF

.proc twoFetchTest
	lda #twofetch1
	PUSH
	jsr TWOFETCH_CODE
	TYPESTR_DOTHEX "2@ test output (expect BEEF) = "
	TYPESTR_DOTHEX "2@ test output (expect FEED) = "
	rts
.endproc
twofetch1:
	.word $FEED, $BEEF

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
	TYPESTR_DOTHEX "2! test (expect FEED) = "
	TYPESTR_DOTHEX "2! test (expect BEEF) = "
	rts
.endproc
twostore1:
	.word $0000, $0000

.proc moveTest
	lda #movesrc
	PUSH
	lda #movedst2
	PUSH
	lda #$0008
	PUSH
	jsr MOVE_CODE
	TYPESTR "MOVE test (expect original) = "
	lda #movedst2
	PUSH
	lda #$0008
	PUSH
	jsr TYPE_CODE
	jsr CR_CODE
	rts
.endproc
movesrc:
	.asciiz "original"
movedst2:
	.asciiz "        "

.proc fillTest
	lda #filldst1
	PUSH
	lda #$0008
	PUSH
	lda #'$'
	PUSH
	jsr FILL_CODE
	TYPESTR "FILL test (expect $$$$$$$$) = "
	lda #filldst1
	PUSH
	lda #$0008
	PUSH
	jsr TYPE_CODE
	jsr CR_CODE
	rts
.endproc
filldst1:
	.asciiz "        "
