\ loop_test.fs - Loop and recursion regression tests

\ BEGIN/UNTIL
: TST5 0 BEGIN 1+ DUP 5 = UNTIL ;
T{ TST5 -> 5 }T

\ BEGIN/AGAIN with DO/LOOP, UNLOOP and EXIT
: TEST-BEGIN-AGAIN
    0 BEGIN
        1+
        5 0 DO
            I .
            DUP 3 = IF UNLOOP EXIT THEN
        LOOP
    AGAIN ;
\ This word prints output and exits when index reaches 3
\ Expected output: 0 1 2 3 4 0 1 2 3 4 0
\ We test the return value only
T{ TEST-BEGIN-AGAIN -> 3 }T

\ DO/LOOP with I
: TEST7 0 5 0 DO I + LOOP ;
T{ TEST7 -> 10 }T

\ Nested DO/LOOP with I and J
: NESTED-OUT ( -- )
    3 0 DO
        3 0 DO
            I J + .
        LOOP
    LOOP ;
\ Expected printed output: 0 1 2 1 2 3 2 3 4
\ No stack result to test, so test via output word
T{ NESTED-OUT -> }T

\ LEAVE
: TSTLEAVE ( -- )
    10 0 DO
        I .
        I 5 = IF LEAVE THEN
    LOOP ;
\ Expected printed output: 0 1 2 3 4 5
T{ TSTLEAVE -> }T

\ Nested LEAVE
: TEST-LEAVE3 ( -- )
    3 0 DO
        3 0 DO
            I 1 = IF LEAVE THEN
            I J + .
        LOOP
    LOOP ;
\ Expected printed output: 0 1 2
T{ TEST-LEAVE3 -> }T

\ +LOOP stepping by 2
: TEST-PLUS1 6 0 DO I . 2 +LOOP ;
T{ TEST-PLUS1 -> }T  \ prints: 0 2 4

: TEST-PLUS2 7 0 DO I . 2 +LOOP ;
T{ TEST-PLUS2 -> }T  \ prints: 0 2 4 6

: TEST-PLUS3 3 0 DO I . 1 +LOOP ;
T{ TEST-PLUS3 -> }T  \ prints: 0 1 2

\ +LOOP negative step
: TEST-PLUS4 0 3 DO I . -1 +LOOP ;
T{ TEST-PLUS4 -> }T  \ prints: 3 2 1 0

: TEST-PLUS5 0 5 DO I . -2 +LOOP ;
T{ TEST-PLUS5 -> }T  \ prints: 5 3 1

\ +LOOP with LEAVE
: TEST-PLUS6 10 0 DO I . I 4 = IF LEAVE THEN 2 +LOOP ;
T{ TEST-PLUS6 -> }T  \ prints: 0 2 4

\ Nested +LOOP
: TEST-PLUS7 4 0 DO 4 0 DO I . J . 2 +LOOP 2 +LOOP ;
T{ TEST-PLUS7 -> }T  \ prints: 0 0 2 0 0 2 2 2

\ RECURSE - factorial
: FACTORIAL DUP 1 > IF DUP 1- RECURSE * THEN ;
T{ 5 FACTORIAL -> 120 }T
T{ 0 FACTORIAL -> 0 }T
T{ 1 FACTORIAL -> 1 }T

DONE
