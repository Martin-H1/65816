\ interpret_test.fs - Interpreter regression tests

\ COMPARE
T{ S" abcdef" S" bcdefg" COMPARE -> -1 }T
T{ S" bcdefg" S" abcdef" COMPARE ->  1 }T
T{ S" bcdefg" S" bcdefg" COMPARE ->  0 }T
T{ S" cdefgh" S" cdefghi" COMPARE -> -1 }T

\ FIND - word not found
T{ BL WORD FOOBAR FIND NIP -> 0 }T

\ FIND - normal word
T{ BL WORD NUMBER FIND NIP -> 1 }T

\ FIND - immediate word
T{ BL WORD IF FIND NIP -> -1 }T

\ FIND - case insensitive
T{ BL WORD number FIND NIP -> 1 }T

\ Basic interpretation
T{ 1 -> 1 }T
T{ 2 3 + -> 5 }T
T{ -1 ABS -> 1 }T

DONE
