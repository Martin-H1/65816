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

; This is the next link in the dictionary. Place a stub here.
; TODO remove this when the dictionary is collapsed into a single module.
PUBLIC RSHIFT_CFA
	nop
ENDPUBLIC

enter:	.asciiz "memory test - enter!"
exit:	.asciiz "memory test - exit!"


.proc fetchTest
	jsr FETCH_CODE
	rts
.endproc

.proc storeTest
	jsr STORE_CODE
	rts
.endproc

.proc cfetchTest
	jsr CFETCH_CODE
	rts
.endproc

.proc cstoreTest
	jsr CSTORE_CODE
	rts
.endproc

.proc twoFetchTest
	jsr TWOFETCH_CODE
	rts
.endproc

.proc twoStoreTest
	jsr TWOSTORE_CODE
	rts
.endproc

.proc moveTest
	jsr MOVE_CODE
	rts
.endproc

.proc fillTest
	jsr FILL_CODE
	rts
.endproc

spaces1:
	.asciiz "spaces test output = '"
spaces2:
	.asciiz "'."
