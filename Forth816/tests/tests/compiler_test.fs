\ compiler_test.fs - Compiler and defining word regression tests

\ : and ;
: FOO 42 ;
T{ FOO -> 42 }T

\ CONSTANT
55 CONSTANT LIMIT
T{ LIMIT -> 55 }T

\ CREATE/DOES>
: KONS CREATE , DOES> @ ;
55 KONS KLIMIT
T{ KLIMIT -> 55 }T

\ VARIABLE
VARIABLE DATE
T{ 12 DATE ! DATE @ -> 12 }T

\ ' and [']
: BAR ['] DUP ;
T{ ' DUP BAR = -> -1 }T

\ IF/THEN
: TEST-IF1 1 IF 99 THEN ;
T{ TEST-IF1 -> 99 }T

: TEST-IF2 0 IF 99 THEN ;
T{ TEST-IF2 -> }T

\ IF/ELSE/THEN
: TEST-IF3 1 IF 99 ELSE 42 THEN ;
T{ TEST-IF3 -> 99 }T

: TEST-IF4 0 IF 99 ELSE 42 THEN ;
T{ TEST-IF4 -> 42 }T

\ CASE/OF/ENDOF/ENDCASE
: TEST-CASE ( n -- n )
    CASE
        1 OF 10 ENDOF
        2 OF 20 ENDOF
        30
    ENDCASE ;
T{ 1 TEST-CASE -> 10 }T
T{ 2 TEST-CASE -> 20 }T
T{ 3 TEST-CASE -> 30 }T

\ CELL, CELLS, CELL+
T{ CELL -> 2 }T
T{ 2 CELLS -> 4 }T
T{ 3 CELL+ -> 5 }T

\ BL
T{ BL -> 32 }T

\ ?DUP
T{ 0 ?DUP -> 0 }T
T{ 5 ?DUP -> 5 5 }T

DONE
