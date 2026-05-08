\ ttester.fs - John Hayes's test framework (no floating point)
\ Adapted for Forth816

MARKER RESET-TEST   \ restore dictionary to this point after each test

\ Clear the parameter stack
: CLEAR-STACK BEGIN DEPTH WHILE DROP REPEAT ;
CLEAR-STACK

DECIMAL

VARIABLE ACTUAL-DEPTH
CREATE ACTUAL-RESULTS 32 CELLS ALLOT
VARIABLE START-DEPTH
VARIABLE XCURSOR
VARIABLE ERROR-XT

: ERROR ( c-addr u -- )
    TYPE CR ;

' ERROR ERROR-XT !  \ default error handler

: T{
    DEPTH START-DEPTH ! ;

: ->
    DEPTH DUP ACTUAL-DEPTH !
    START-DEPTH @ - DUP 0< IF
        S" WRONG NUMBER OF RESULTS: " ERROR
    THEN
    0 ?DO
        ACTUAL-RESULTS I CELLS + !
    LOOP ;

: }T
    DEPTH START-DEPTH @ - ACTUAL-DEPTH @ <> IF
        S" WRONG NUMBER OF RESULTS: " TYPE CR
    ELSE
        ACTUAL-DEPTH @ 0 ?DO
            ACTUAL-RESULTS I CELLS + @ <> IF
                S" INCORRECT RESULT: " TYPE CR
            THEN
        LOOP
    THEN ;

\ Helper to verify interpreter recovered after an error
: RECOVERED? 1 1 + 2 = ;

: DONE ." ###DONE###" CR RESET-TEST ;
