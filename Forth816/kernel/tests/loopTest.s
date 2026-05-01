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
.import TRACEON_CODE

.importzp UP
.importzp W

; Main entry point for the test
PUBLIC MAIN
	TYPESTRCR "Compiler test - enter!"

	jsr loopTest
	jsr plusLoopTest
	jsr recurseTest

	TYPESTRCR "Compiler test - exit!"
	rts
ENDPUBLIC

.proc loopTest
	MOVE_TIB ": tst5  0 begin 1+ dup 5 = until ; tst5"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': tst5  0 begin 1+ dup 5 = until ; tst5 .' (expect 5) = "

	TYPESTR "test-begin-again (expect 0 1 2 3 4 0 1 2 3 4 0 3) = "
	MOVE_TIB ": test-begin-again 0 BEGIN 1+ 5 0 DO I . DUP 3 = IF UNLOOP"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "EXIT THEN LOOP AGAIN ; test-begin-again ."
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	MOVE_TIB ": test7 0 5 0 do i + loop ; test7"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': test7 0 5 0 do i + loop ; test7 .' (expect 10) = "

	TYPESTR "'Test nested 3 0, 3 0' (expect 0 1 2 1 2 3 2 3 4) = "
	MOVE_TIB ": nested 3 0 DO 3 0 DO I J + . LOOP LOOP ; nested"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test leave' (expect 0 1 2 3 4 5) = "
	MOVE_TIB ": tstleave 10 0 do i dup . 5 = if leave then loop ; tstleave"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test3 (expect 0 1 2) = "
	MOVE_TIB ": test-leave3 3 0 DO 3 0 DO I 1 = IF LEAVE THEN I J + . LOOP"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "LOOP ; test-leave3"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	rts
.endproc

.proc plusLoopTest
	TYPESTR "test-plus1 (expect 0 2 4) = "
	MOVE_TIB ": test-plus1 6 0 do i . 2 +loop ; test-plus1"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test-plus2 (expect 0 2 4 6) = "
	MOVE_TIB ": test-plus2 7 0 DO I . 2 +LOOP ; test-plus2"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE


	TYPESTR "test-plus3 (expect 0 1 2) = "
	MOVE_TIB ": test-plus3 3 0 DO I . 1 +LOOP ; test-plus3"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test-plus4 (expect 3 2 1 0) = "
	MOVE_TIB ": test-plus4 0 3 DO I . -1 +LOOP ; test-plus4"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test-plu5 (expect 5 3 1) = "
	MOVE_TIB ": test-plus5 0 5 DO I . -2 +LOOP ; test-plus5"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test-plus6 (expect 0 2 4) = "
	MOVE_TIB ": test-plus6 10 0 DO I . I 4 = IF LEAVE THEN 2 +LOOP ; test-plus6"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	TYPESTR "test-plus7 (expect 0 0 2 0 0 2 2 2) = "
	MOVE_TIB ": test-plus7 4 0 DO 4 0 DO I . J . 2 +LOOP 2 +LOOP ; test-plus7"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	jsr CR_CODE

	rts
.endproc

.proc recurseTest
	MOVE_TIB ": factorial dup 1 > if dup 1- recurse * then ; 5 factorial"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': factorial dup 1 > if dup 1- recurse * then ; 5 factorial' (expect 120) = "
	rts
.endproc
