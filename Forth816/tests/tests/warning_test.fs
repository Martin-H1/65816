\ warning_test.fs - Redefinition and literal warning regression tests

\ Redefinition warning
: REDEF-TEST 42 ;
: REDEF-TEST 99 ;        \ should print "warning: redefined REDEF-TEST"
T{ REDEF-TEST -> 99 }T   \ new definition should work correctly

\ Literal defined as word warning
: 42 ." forty-two" ;     \ should print "warning: defined literal 42 as a word"
T{ 42 -> }T              \ new word should execute correctly

\ No warning for first definition
: FIRST-DEF 1 ;
T{ FIRST-DEF -> 1 }T

\ No warning for non-numeric name
: NOT-A-NUMBER 2 ;
T{ NOT-A-NUMBER -> 2 }T

\ Double literal warning
: 1234. ." double" ;     \ should print "warning: defined literal 1234. as a word"
T{ 1234. -> }T

\ VARIABLE warnings
VARIABLE WARNVAR
VARIABLE WARNVAR         \ should warn: redefined WARNVAR
VARIABLE 97              \ should warn: defined literal 97 as a word

\ CONSTANT warnings
42 CONSTANT WARNCON
42 CONSTANT WARNCON      \ should warn: redefined WARNCON
55 CONSTANT 98           \ should warn: defined literal 98 as a word

\ VALUE warnings
42 VALUE WARNVAL
42 VALUE WARNVAL         \ should warn: redefined WARNVAL
55 VALUE 96              \ should warn: defined literal 96 as a word

\ 2VARIABLE warnings
2VARIABLE WARN2VAR
2VARIABLE WARN2VAR       \ should warn: redefined WARN2VAR
2VARIABLE 95             \ should warn: defined literal 95 as a word

\ 2CONSTANT warnings
1. 2CONSTANT WARN2CON
1. 2CONSTANT WARN2CON    \ should warn: redefined WARN2CON
1. 2CONSTANT 94          \ should warn: defined literal 94 as a word

\ 2VALUE warnings
1. 2VALUE WARN2VAL
1. 2VALUE WARN2VAL       \ should warn: redefined WARN2VAL
1. 2VALUE 93             \ should warn: defined literal 93 as a word

\ : warnings
: REDEF-TEST 42 ;
: REDEF-TEST 99 ;        \ should warn: redefined REDEF-TEST
: 92 ." ninety-two" ;    \ should warn: defined literal 92 as a word

DONE
