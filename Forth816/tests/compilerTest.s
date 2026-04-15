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
.import MOVE_CODE

.importzp UP
.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "Compiler test - enter!"

	jsr colonTest
	jsr constantTest
	jsr createDoesTest
	jsr variableTest

	TYPESTRCR "Compiler test - exit!"
	rts
ENDPUBLIC

.proc colonTest
	MOVE_TIB "  : foo 42 ; foo                "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Compile test of ': foo 32 ;  foo .' (expect 42) = "
	rts
.endproc

.proc constantTest
	MOVE_TIB "55 constant limit limit         "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Compile test of '55 constant limit limit' (expect 55) = "
	rts
.endproc

.proc createDoesTest
	MOVE_TIB ": kons create , does> @ ;   "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "55 kons limit   limit       "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Compile test of 'create does' (expect 55) = "
	rts
.endproc

.proc variableTest
	MOVE_TIB "VARIABLE DATE 12 DATE ! DATE @  "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "Compile test of 'VARIABLE DATE 12 DATE ! DATE @' (expect 12) = "
	rts
.endproc
