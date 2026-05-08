\ math_test.fs - Arithmetic regression tests

\ +
T{ 597 4133 + -> 4730 }T

\ +!
VARIABLE DATA
33 DATA !
T{ 13 DATA +! DATA @ -> 46 }T

\ -
T{ 4133 597 - -> 3536 }T

\ *
T{ 4133 7 * -> 28931 }T
T{ 4133 -3 * -> -12399 }T
T{ -3 -3 * -> 9 }T
T{ -3 20 * -> -60 }T

\ UM*
T{ 4133 20 UM* -> 17124 1 }T
T{ 4133 65533 UM* -> 53137 4132 }T
T{ 65533 65533 UM* -> 9 65530 }T
T{ 65533 20 UM* -> 65476 19 }T

\ UM/MOD
T{ 1025 0 14 UM/MOD -> 3 73 }T
T{ 1025 0 0 UM/MOD -> 1025 -1 }T

\ /MOD
T{ 4133 20 /MOD -> 13 206 }T
T{ 4133 -3 /MOD -> -1 -1378 }T
T{ -3 -3 /MOD -> 0 1 }T
T{ -3 20 /MOD -> 17 -1 }T

\ /
T{ 4133 20 / -> 206 }T
T{ 4133 -3 / -> -1378 }T
T{ -3 -3 / -> 1 }T
T{ -3 20 / -> -1 }T
T{ -3 1 / -> -3 }T

\ MOD
T{ 4133 20 MOD -> 13 }T
T{ 4133 -3 MOD -> -1 }T
T{ -3 -3 MOD -> 0 }T
T{ -3 20 MOD -> 17 }T

\ NEGATE
T{ -32 NEGATE -> 32 }T
T{ 224 NEGATE -> -224 }T

\ ABS
T{ -32 ABS -> 32 }T
T{ 224 ABS -> 224 }T

\ MAX
T{ 50 4146 MAX -> 4146 }T

\ MIN
T{ 50 4146 MIN -> 50 }T

\ 1+
T{ 4146 1+ -> 4147 }T

\ 1-
T{ 1335 1- -> 1334 }T

\ 2*
T{ $0537 2* -> $0A6E }T

\ 2/
T{ $0537 2/ -> $029B }T

\ S>D
T{ $0537 S>D -> $0537 0 }T
T{ $8537 S>D -> $8537 -1 }T

\ WITHIN
T{  1 -5  5 WITHIN -> TRUE }T
T{ -5  1  5 WITHIN -> FALSE }T
T{  1  5 -5 WITHIN -> FALSE }T

DONE
