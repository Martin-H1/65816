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
	jsr loopTest
	jsr cellsTest
	jsr blDupTest
	jsr recurseTest

	; : test-nq 32 word number? . . ;
	; test-nq cell
	; : test-nq 32 word number? . . ;
	; test-nq cell
	; : test-again  0 begin 1+ dup . dup 5 = until ;
	; test-again              \ should print 1 2 3 4 5

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

.proc loopTest
	MOVE_TIB ": tst5  0 begin 1+ dup 5 = until ; tst5"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': tst5  0 begin 1+ dup 5 = until ; tst5 .' (expect 5) = "

	MOVE_TIB ": test7 0 5 0 do i + loop ; test7"
	CALL_DOCOL INTERPRET_CFA	; RTS_CFA will return here.
	TYPESTR_DOT "': test7 0 5 0 do i + loop ; test7 .' (expect 10) = "

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
