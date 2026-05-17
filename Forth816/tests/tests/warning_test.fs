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

DONE
