; -----------------------------------------------------------------------------
; compilerTest - unit test for compiler words (e.g. ":", ";" "[", "]" )
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

.import COLON_CODE
.import SEMICOLON_CODE
.import RBRACKET_CODE
.import LBRACKET_CODE

.importzp UP
.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "Compiler test - enter!"
	jsr colonTest
	jsr semicolonTest
	jsr rbracketTest
	jsr lbracketTest

	TYPESTRCR "Compiler test - exit!"
	rts
ENDPUBLIC

.proc colonTest
.endproc

.proc semicolonTest
.endproc

.proc rbracketTest
	rts
.endproc

.proc lbracketTest
	rts
.endproc
