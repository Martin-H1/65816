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

\ 2CONSTANT
$FFFF $3FFF 2CONSTANT HI-2INT
$0000 $C000 2CONSTANT LO-2INT

: ?floored [ -3 2 / -2 = ] LITERAL IF 1 0 D- THEN ;

T{       5.       7             11 M*/ ->  3. }T
T{       5.      -7             11 M*/ -> -3. ?floored }T
T{      -5.       7             11 M*/ -> -3. ?floored }T
T{      -5.      -7             11 M*/ ->  3. }T
T{ MAX-2INT       8             16 M*/ -> HI-2INT }T
T{ MAX-2INT      -8             16 M*/ -> HI-2INT DNEGATE ?floored }T
T{ MIN-2INT       8             16 M*/ -> LO-2INT }T
T{ MIN-2INT      -8             16 M*/ -> LO-2INT DNEGATE }T

T{ MAX-2INT MAX-INT        MAX-INT M*/ -> MAX-2INT }T
T{ MAX-2INT MAX-INT 2/     MAX-INT M*/ -> MAX-INT 1- HI-2INT NIP }T
T{ MIN-2INT LO-2INT NIP DUP NEGATE M*/ -> MIN-2INT }T
T{ MIN-2INT LO-2INT NIP 1- MAX-INT M*/ -> MIN-INT 3 + HI-2INT NIP 2 + }T
T{ MAX-2INT LO-2INT NIP DUP NEGATE M*/ -> MAX-2INT DNEGATE }T
T{ MIN-2INT MAX-INT            DUP M*/ -> MIN-2INT }T

DONE
