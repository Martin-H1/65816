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
.include "print.inc"

.import EMIT_CODE
.import KEY_CODE
.import KEYQ_CODE
.import TYPE_CODE
.import CR_CODE
.import SPACE_CODE
.import SPACES_CODE

; Main entry point for the test
PUBLIC MAIN
	PRINTLN enter

	jsr emitTest
	jsr keyTest
	jsr keyqTest
	jsr typeTest
	jsr crTest
	jsr spaceTest
	jsr spacesTest

	PRINTLN exit
	rts
ENDPUBLIC

enter:	.asciiz "io test - enter!"
exit:	.asciiz "io test - exit!"

.proc emitTest
	lda #'E'
	PUSH
	PRINT emit1
	jsr EMIT_CODE
	PRINTLN emit2
	rts
.endproc
emit1:	.asciiz "emit test char (expect E) = "
emit2:	.asciiz "."

.proc keyTest
	PRINT key1
	jsr KEY_CODE
	PRINTLN_POP key2
	rts
.endproc
key1:	.asciiz "key test char = "
key2:	.asciiz "."

.proc keyqTest
	jsr KEYQ_CODE
	PRINTLN_POP keyq1
	PRINTLN keyq2
	rts
.endproc
keyq1:	.asciiz "keyq test flag = "
keyq2:	.asciiz "."

.proc typeTest
	lda #type1
	PUSH
	lda #12
	PUSH
	jsr TYPE_CODE
	PRINTCR

	rts
.endproc
type1:	.asciiz "type test = "

.proc crTest
	PRINTLN cr1
	jsr CR_CODE
	PRINTLN cr2

	rts
.endproc
cr1:	.asciiz "cr test - enter "
cr2:	.asciiz "cr test - exit "

.proc spaceTest
	PRINT space1
	jsr SPACE_CODE
	PRINTLN space2

	rts
.endproc
space1:	.asciiz "space test output = '"
space2:	.asciiz "'."

.proc spacesTest
	lda #10
	PUSH
	PRINT spaces1
	jsr SPACES_CODE
	PRINTLN spaces2

	rts
.endproc
spaces1:
	.asciiz "spaces test output = '"
spaces2:
	.asciiz "'."
