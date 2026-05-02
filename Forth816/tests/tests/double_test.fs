\ double_test.fs - Double number regression tests

\ 2LIT and basic double literals
T{ 0. -> 0 0 }T
T{ 1234. -> 1234 0 }T
T{ -1. -> -1 -1 }T
T{ 100000. -> 34464 1 }T  \ $186A0

\ >NUMBER
T{ 0 0 S" 0" >NUMBER 2DROP -> 0 0 }T
T{ 0 0 S" 1234" >NUMBER 2DROP -> 1234 0 }T
T{ 0 0 S" 100000" >NUMBER 2DROP -> 34464 1 }T

\ D+
T{ 1. 2. D+ -> 3 0 }T
T{ -1. 1. D+ -> 0 0 }T
T{ 100000. 100000. D+ -> 3392 3 }T  \ 200000 = $30D40

\ D-
T{ 3. 2. D- -> 1 0 }T
T{ 0. 1. D- -> -1 -1 }T

\ DNEGATE
T{ 1. DNEGATE -> -1 -1 }T
T{ -1. DNEGATE -> 1 0 }T
T{ 0. DNEGATE -> 0 0 }T

\ DABS
T{ -1. DABS -> 1 0 }T
T{ 1. DABS -> 1 0 }T

\ D=
T{ 1. 1. D= -> -1 }T
T{ 1. 2. D= -> 0 }T
T{ 100000. 100000. D= -> -1 }T

\ D
T{ 1. 2. D< -> -1 }T
T{ 2. 1. D< -> 0 }T
T{ -1. 0. D< -> -1 }T

\ DU
T{ 1. 2. DU< -> -1 }T
T{ 2. 1. DU< -> 0 }T

\ D>S
T{ 1234. D>S -> 1234 }T

\ S>D
T{ 1234 S>D -> 1234 0 }T
T{ -1 S>D -> -1 -1 }T

\ M+
T{ 1. 2 M+ -> 3 0 }T
T{ -1. 1 M+ -> 0 0 }T

DONE
