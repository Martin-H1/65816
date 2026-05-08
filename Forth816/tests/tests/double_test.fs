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

\ D<
T{ 1. 2. D< -> -1 }T
T{ 2. 1. D< -> 0 }T
T{ -1. 0. D< -> -1 }T

\ DU<
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

\ 2CONSTANT
$FFFF $3FFF 2CONSTANT HI-2INT
$0000 $C000 2CONSTANT LO-2INT

\ 2VARIABLE
T{ 2VARIABLE 2v1 -> }T
T{ 0. 2v1 2! ->    }T
T{    2v1 2@ -> 0. }T

\ D2*
T{              0. D2* -> 0. D2* }T
T{ MIN-INT       0 D2* -> 0 1 }T
T{         HI-2INT D2* -> MAX-2INT 1. D- }T
T{         LO-2INT D2* -> MIN-2INT }T

\ D2/
T{       0. D2/ -> 0.        }T
T{       1. D2/ -> 0.        }T
T{      0 1 D2/ -> MIN-INT 0 }T
T{ MAX-2INT D2/ -> HI-2INT   }T
T{      -1. D2/ -> -1.       }T
T{ MIN-2INT D2/ -> LO-2INT   }T

\ D0=
T{               1. D0= -> FALSE }T
T{ MIN-INT        0 D0= -> FALSE }T
T{         MAX-2INT D0= -> FALSE }T
T{      -1  MAX-INT D0= -> FALSE }T
T{               0. D0= -> TRUE  }T
T{              -1. D0= -> FALSE }T
T{       0  MIN-INT D0= -> FALSE }T

\ D0<
T{                0. D0< -> FALSE }T
T{                1. D0< -> FALSE }T
T{  MIN-INT        0 D0< -> FALSE }T
T{        0  MAX-INT D0< -> FALSE }T
T{          MAX-2INT D0< -> FALSE }T
T{               -1. D0< -> TRUE  }T
T{          MIN-2INT D0< -> TRUE  }T

\ DMAX
T{       1.       2. DMAX ->  2.      }T
T{       1.       0. DMAX ->  1.      }T
T{       1.      -1. DMAX ->  1.      }T
T{       1.       1. DMAX ->  1.      }T
T{       0.       1. DMAX ->  1.      }T
T{       0.      -1. DMAX ->  0.      }T
T{      -1.       1. DMAX ->  1.      }T
T{      -1.      -2. DMAX -> -1.      }T
T{ MAX-2INT  HI-2INT DMAX -> MAX-2INT }T
T{ MAX-2INT MIN-2INT DMAX -> MAX-2INT }T
T{ MIN-2INT MAX-2INT DMAX -> MAX-2INT }T
T{ MIN-2INT  LO-2INT DMAX -> LO-2INT  }T

T{ MAX-2INT       1. DMAX -> MAX-2INT }T
T{ MAX-2INT      -1. DMAX -> MAX-2INT }T
T{ MIN-2INT       1. DMAX ->  1.      }T
T{ MIN-2INT      -1. DMAX -> -1.      }T

\ DMIN
T{       1.       2. DMIN ->  1.      }T
T{       1.       0. DMIN ->  0.      }T
T{       1.      -1. DMIN -> -1.      }T
T{       1.       1. DMIN ->  1.      }T
T{       0.       1. DMIN ->  0.      }T
T{       0.      -1. DMIN -> -1.      }T
T{      -1.       1. DMIN -> -1.      }T
T{      -1.      -2. DMIN -> -2.      }T
T{ MAX-2INT  HI-2INT DMIN -> HI-2INT  }T
T{ MAX-2INT MIN-2INT DMIN -> MIN-2INT }T
T{ MIN-2INT MAX-2INT DMIN -> MIN-2INT }T
T{ MIN-2INT  LO-2INT DMIN -> MIN-2INT }T

T{ MAX-2INT       1. DMIN ->  1.      }T
T{ MAX-2INT      -1. DMIN -> -1.      }T
T{ MIN-2INT       1. DMIN -> MIN-2INT }T
T{ MIN-2INT      -1. DMIN -> MIN-2INT }T

DONE
