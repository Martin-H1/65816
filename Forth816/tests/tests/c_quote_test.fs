\ c_quote_test.fs - C" regression tests

\ Length byte is correct
T{ C" hi" C@ -> 2 }T
T{ C" hello" C@ -> 5 }T
T{ C" " C@ -> 0 }T

\ First character is correct
: abc C" ABC" 1+ C@ ;
: xyz C" XYZ" 1+ C@ ;
T{ abc -> 65 }T      \ 'A' = $41 = 65
T{ xyz -> 88 }T      \ 'X' = $58 = 88

\ Last character is correct
T{ abc 3 + C@ -> 67 }T     \ 'C' = $43 = 67

\ C" in a definition - string lives in dictionary not PAD
: CSTR1 C" testing" ;
: CSTR2 C" hello" ;
T{ CSTR1 C@ -> 7 }T
T{ CSTR2 C@ -> 5 }T

\ Two calls don't collide since strings are in dictionary
T{ CSTR1 COUNT NIP -> 7 }T
T{ CSTR2 COUNT NIP -> 5 }T

\ Natural use case - FIND with counted string
T{ C" DUP" FIND NIP -> 1 }T
T{ C" IF" FIND NIP -> -1 }T
T{ C" NOTAWORD" FIND NIP -> 0 }T

DONE
