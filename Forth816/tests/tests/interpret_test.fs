\ interpret_test.fs - Interpreter regression tests

\ COMPARE
CREATE ABC  3 C, $61 C, $62 C, $63 C,
CREATE BCD  3 C, $62 C, $63 C, $64 C,
CREATE ABCD 4 C, $61 C, $62 C, $63 C, $64 C,

T{ ABC  COUNT BCD  COUNT COMPARE -> -1 }T
T{ BCD  COUNT ABC  COUNT COMPARE ->  1 }T
T{ ABC  COUNT ABC  COUNT COMPARE ->  0 }T
T{ ABC  COUNT ABCD COUNT COMPARE -> -1 }T
T{ ABCD COUNT ABC  COUNT COMPARE ->  1 }T

\ FIND - word not found
: FINDWORD ( "name" -- flag ) BL WORD FIND NIP ;
T{ FINDWORD NOTAWORD -> 0 }T
T{ FINDWORD NUMBER -> 1 }T
T{ FINDWORD IF -> -1 }T

\ Basic interpretation
T{ 1 -> 1 }T
T{ 2 3 + -> 5 }T
T{ -1 ABS -> 1 }T

\ CHAR [CHAR]

T{ CHAR X     -> $58 }T
T{ CHAR HELLO -> $48 }T

T{ : GC1 [CHAR] X     ; -> }T
T{ : GC2 [CHAR] HELLO ; -> }T
T{ GC1 -> $58 }T
T{ GC2 -> $48 }T

DONE
