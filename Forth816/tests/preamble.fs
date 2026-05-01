\ ttester.fs - John Hayes's test framework (no floating point)
\ Adapted for Forth816

DECIMAL

VARIABLE ACTUAL-DEPTH
CREATE ACTUAL-RESULTS 32 CELLS ALLOT
VARIABLE START-DEPTH
VARIABLE XCURSOR
VARIABLE ERROR-XT

: ERROR ( c-addr u -- )
    TYPE CR ;

ERROR-XT !  \ default error handler

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

: DONE ." ###DONE###" CR ;

MARKER RESET-TEST   \ restore dictionary to this point after each test

: DONE ." ###DONE###" CR RESET-TEST ;
