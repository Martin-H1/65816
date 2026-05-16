\ noname_test.fs - :NONAME regression tests

\ Basic :NONAME creates executable xt
:NONAME 42 ; CONSTANT ANSWER-XT
T{ ANSWER-XT EXECUTE -> 42 }T

\ :NONAME with parameters
:NONAME + ; CONSTANT ADD-XT
T{ 3 4 ADD-XT EXECUTE -> 7 }T

\ :NONAME stored in a DEFER
DEFER MYACTION
:NONAME 99 ; IS MYACTION
T{ MYACTION -> 99 }T

\ :NONAME xt can be stored in a VARIABLE
VARIABLE XT-VAR
:NONAME 123 ; XT-VAR !
T{ XT-VAR @ EXECUTE -> 123 }T

\ Multiple :NONAME definitions are independent
:NONAME 1 ; CONSTANT XT1
:NONAME 2 ; CONSTANT XT2
T{ XT1 EXECUTE -> 1 }T
T{ XT2 EXECUTE -> 2 }T

\ :NONAME with local stack manipulation
:NONAME DUP * ; CONSTANT SQUARE-XT
T{ 5 SQUARE-XT EXECUTE -> 25 }T

\ :NONAME does not affect LATEST
LATEST @ VALUE LATEST-BEFORE
LATEST @ TO LATEST-BEFORE       \ capture LATEST after LATEST-BEFORE creation
:NONAME 0 ; DROP                \ anonymous def
T{ LATEST @ LATEST-BEFORE = -> -1 }T

\ :NONAME works with control structures
:NONAME IF 1 ELSE 0 THEN ; CONSTANT BOOL-XT
T{ -1 BOOL-XT EXECUTE -> 1 }T
T{ 0 BOOL-XT EXECUTE -> 0 }T

\ Failed :NONAME rolls back dictionary
VARIABLE HERE-BEFORE
HERE HERE-BEFORE !
:NONAME UNDEFINED-XYZ ;
T{ HERE HERE-BEFORE @ = -> -1 }T
T{ RECOVERED? -> -1 }T

DONE
