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

DONE
