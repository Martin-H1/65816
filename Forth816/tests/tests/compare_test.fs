\ compare_test.fs - Comparison and bitwise operator regression tests

\ =
T{ 32 32 = -> -1 }T
T{ 42 32 = -> 0 }T

\ <>
T{ 32 32 <> -> 0 }T
T{ 42 32 <> -> -1 }T

\ <
T{ 32 32 < -> 0 }T
T{ 42 32 < -> 0 }T
T{ 32 42 < -> -1 }T
T{ 32 -42 < -> 0 }T

\ >
T{ 32 32 > -> 0 }T
T{ 42 32 > -> -1 }T
T{ 32 42 > -> 0 }T
T{ 32 -42 > -> -1 }T

\ U<
T{ 32 32 U< -> 0 }T
T{ 42 32 U< -> 0 }T
T{ 32 42 U< -> -1 }T
T{ 32 65534 U< -> -1 }T

\ U>
T{ 32 32 U> -> 0 }T
T{ 42 32 U> -> -1 }T
T{ 32 42 U> -> 0 }T
T{ 32 65534 U> -> 0 }T

\ 0=
T{ 32 0= -> 0 }T
T{ 0 0= -> -1 }T

\ 0<
T{ 32 0< -> 0 }T
T{ -42 0< -> -1 }T

\ 0>
T{ 32 0> -> -1 }T
T{ -42 0> -> 0 }T
T{ 0 0> -> 0 }T

\ AND
T{ $FF00 $0FF0 AND -> $0F00 }T

\ OR
T{ $FF00 $0FF0 OR -> $FFF0 }T

\ XOR
T{ $FF00 $0FF0 XOR -> $F0F0 }T

\ INVERT
T{ $F0F0 INVERT -> $0F0F }T

\ LSHIFT
T{ 32 0 LSHIFT -> 32 }T
T{ 32 3 LSHIFT -> 256 }T

\ RSHIFT
T{ 32 0 RSHIFT -> 32 }T
T{ 32 3 RSHIFT -> 4 }T

DONE
