; -----------------------------------------------------------------------------
; ioTest - unit test for io.s module
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

.import DOT_PROMPT_CODE
.import EMIT_CODE
.import KEY_CODE
.import KEYQ_CODE
.import TYPE_CODE
.import SPACE_CODE
.import SPACES_CODE

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "io test - enter!"

	jsr emitTest
	jsr keyTest
	jsr keyqTest
	jsr typeTest
	jsr crTest
	jsr spaceTest
	jsr spacesTest

	jsr dotTest
	TYPESTRCR "io test - exit!"
	rts
ENDPUBLIC

.proc emitTest
	lda #'E'
	PUSH
	TYPESTR "emit test char (expect E) = "
	jsr EMIT_CODE
	TYPESTRCR "."
	rts
.endproc

.proc keyTest
	TYPESTR "key test char = "
	jsr KEY_CODE
	TYPESTR_DOT "."
	rts
.endproc

.proc keyqTest
	jsr KEYQ_CODE
	TYPESTR_DOT "keyq test flag = "
	TYPESTRCR "."
	rts
.endproc

.proc typeTest
	TYPESTRCR "type test = "
	rts
.endproc

.proc crTest
	TYPESTR "cr test - enter "
	jsr CR_CODE
	TYPESTR "cr test - exit "

	rts
.endproc

.proc spaceTest
	TYPESTR "space test output = '"
	jsr SPACE_CODE
	TYPESTRCR "'."

	rts
.endproc

.proc spacesTest
	lda #10
	PUSH
	TYPESTR "spaces test output = '"
	jsr SPACES_CODE
	TYPESTRCR "'."

	rts
.endproc

.proc dotTest
	jsr DOT_PROMPT_CODE
	jsr CR_CODE
	lda #0
	PUSH
	lda #10
	PUSH
	lda #$fffd
	PUSH
	lda #15936
	PUSH
	jsr DOTS_CODE
	jsr CR_CODE

	rts
.endproc
