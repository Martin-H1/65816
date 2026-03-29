; -----------------------------------------------------------------------------
; acceptTest - unit test for ACCEPT_CODE which is a key part of the interpreter
; REPL loop.
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

.import ACCEPT_CODE
.import DUP_CODE

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "accept test - enter!"
	lda #buffer
	PUSH
	lda #256
	PUSH
	jsr ACCEPT_CODE
	jsr DUP_CODE
	POP
	OFF16MEM
	sta length
	ON16MEM
	TYPESTR "Chars returned="
;	jsr DOT_CODE
	TYPESTR ", text='"
	lda #buffer
	jsr hal_lpputs
	TYPESTRCR "'"
	TYPESTRCR "accept test - exit!"
	rts
ENDPUBLIC
length:	.byte 00
buffer:	.res 256
