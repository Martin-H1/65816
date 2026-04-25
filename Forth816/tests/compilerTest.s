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

	jsr colonTest
	jsr constantTest
	jsr createDoesTest
	jsr variableTest
	jsr tickTest
	jsr ifTest
	jsr caseTest
	jsr loopTest
	jsr plusLoopTest
	jsr cellsTest
	jsr blDupTest
	jsr recurseTest

	TYPESTRCR "Compiler test - exit!"
	rts
ENDPUBLIC

.proc colonTest
	MOVE_TIB ": foo 42 ; foo"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': foo 42 ; foo .' (expect 42) = "
	rts
.endproc

.proc constantTest
	MOVE_TIB "55 constant limit limit"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'55 constant limit limit' (expect 55) = "
	rts
.endproc

.proc createDoesTest
	MOVE_TIB ": kons create , does> @ ;"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "55 kons limit limit"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'create does' (expect 55) = "
	rts
.endproc

.proc variableTest
	MOVE_TIB "VARIABLE DATE 12 DATE ! DATE @"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'VARIABLE DATE 12 DATE ! DATE @' (expect 12) = "
	rts
.endproc

.proc tickTest
	MOVE_TIB "' dup"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOTHEX "'' dup .' (expect 4916) = "

	MOVE_TIB ": bar ['] dup ; bar"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOTHEX "': bar ['] dup ; bar .' (expect 4916) = "

	MOVE_TIB ": bar ['] dup ; bar"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOTHEX "': bar ['] dup ; bar .' (expect 4916) = "

	; create foo
	; ' foo execute .s

	rts
.endproc

.proc ifTest
	MOVE_TIB ": test1 1 if 99 then ; test1 "
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': test1 1 if 99 then ; test1 .' (expect 99) = "

	MOVE_TIB ": test2 0 0 if 99 then ; test2"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': test2 0 if 99 then ; test2 .' (expect 0) = "

	MOVE_TIB ": test3 1 if 99 else 42 then ; test3"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': test3  1 if 99 else 42 then ; test3' (expect 99) = "

	MOVE_TIB ": test4 0 if 99 else 42 then ; test4"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': test4 0 if 99 else 42 then ; test4' (expect 42) = "

	rts
.endproc

.proc caseTest
	MOVE_TIB ": test-case ( n -- ) CASE"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "1 OF 10 ENDOF"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "2 OF 20 ENDOF"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "30"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	MOVE_TIB "ENDCASE ;"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.

	MOVE_TIB "1 test-case"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "test case 1 (expect 10) = "

	MOVE_TIB "2 test-case"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "test case 2 (expect 20) = "

	MOVE_TIB "3 test-case"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "test case default (expect 30) = "

	rts
.endproc

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





.proc functionTest
	MOVE_TIB ": kons create , does> @ ; 42 kons ans ans"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': kons create , does> @ ; 4 kons ans ans' (expect 4) = "

	rts
.endproc

.proc cellsTest
	MOVE_TIB "cell"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'cell .' (expect 2) = "

	MOVE_TIB "2 cells"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'2 cells .' (expect 4) = "

	MOVE_TIB "3 cell+"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'3 cell+ .' (expect 5) = "

	rts
.endproc

.proc blDupTest
	MOVE_TIB "bl"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'bl .' (expect 32) = "

	MOVE_TIB "0 ?dup"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "'0 ?dup' (expect 0) = "

	TYPESTR "'5 ?dup .s' (expect 5 5) = "
	MOVE_TIB "5 ?dup .s"
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
