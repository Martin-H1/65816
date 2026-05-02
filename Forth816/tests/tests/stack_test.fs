\ stack_test.fs - Parameter stack regression tests

T{ 1 2 3 SWAP -> 1 3 2 }T
T{ 1 2 3 SWAP -> 1 3 2 }T

\ DUP
T{ 1 DUP -> 1 1 }T
T{ -1 DUP -> -1 -1 }T

\ DROP
T{ 1 2 DROP -> 1 }T

\ OVER
T{ 1 2 OVER -> 1 2 1 }T

\ ROT
T{ 1 2 3 ROT -> 2 3 1 }T

\ NIP
T{ 1 2 NIP -> 2 }T

\ TUCK
T{ 1 2 TUCK -> 2 1 2 }T

\ 2DUP
T{ 1 2 2DUP -> 1 2 1 2 }T

\ 2DROP
T{ 1 2 3 4 2DROP -> 1 2 }T

\ 2SWAP
T{ 1 2 3 4 2SWAP -> 3 4 1 2 }T

\ 2OVER
T{ 1 2 3 4 2OVER -> 1 2 3 4 1 2 }T

\ PICK
T{ 1 2 3 4 1 2 PICK -> 1 2 3 4 1 3 }T

\ DEPTH
T{ 1 2 3 4 1 3 PICK -> 1 2 3 4 1 2 }T

CLEAR-STACK

: TEST>R  ( n -- n ) >R R> ;

T{ 42 TEST>R -> 42 }T

: TEST>R2  ( a b -- b a ) >R >R R> R> ;

T{ 1 2 TEST>R2 -> 1 2 }T

: TESTR@  ( n -- n n ) >R R@ R> ;

T{ 42 TESTR@ -> 42 42 }T

DONE
