\ number_test.fs - Number conversion regression tests

CREATE NUMTEST-BUF 32 ALLOT
: NUMTEST-STR ( c-addr u -- addr ) NUMTEST-BUF PLACE NUMTEST-BUF ;

\ >NUMBER ( ud c-addr u -- ud c-addr u )
\ NIP drops c-addr leaving ( ud_lo ud_hi u )
T{ 0 0 S" " >NUMBER NIP -> 0 0 0 }T
T{ 0 0 S" 0" >NUMBER NIP -> 0 0 0 }T
T{ 0 0 S" 500" >NUMBER NIP -> 500 0 0 }T
T{ 0 0 S" 12G" >NUMBER NIP -> 12 0 1 }T

HEX
T{ 0 0 S" 7FF" >NUMBER NIP -> 7FF 0 0 }T
T{ 0 0 S" DEAD" >NUMBER NIP -> DEAD 0 0 }T
DECIMAL

\ NUMBER? invalid input
T{ S" "    NUMTEST-STR NUMBER? NIP -> 0 }T
T{ S" --"  NUMTEST-STR NUMBER? NIP -> 0 }T
T{ S" fpp" NUMTEST-STR NUMBER? NIP -> 0 }T
T{ S" 12G" NUMTEST-STR NUMBER? NIP -> 0 }T
T{ S" CELL" NUMTEST-STR NUMBER? NIP -> 0 }T

\ NUMBER? valid decimal
T{ S" 0"   NUMTEST-STR NUMBER? -> 0 -1 }T
T{ S" -10" NUMTEST-STR NUMBER? -> -10 -1 }T
T{ S" 500" NUMTEST-STR NUMBER? -> 500 -1 }T

\ NUMBER? valid hex
T{ S" $7FF"  NUMTEST-STR NUMBER? -> $7FF -1 }T
T{ S" -$7FF" NUMTEST-STR NUMBER? -> -$7FF -1 }T
T{ S" $7FFF" NUMTEST-STR NUMBER? -> $7FFF -1 }T
T{ S" $8000" NUMTEST-STR NUMBER? -> $8000 -1 }T

\ NUMBER? boundary - single cell
T{ S" 65535" NUMTEST-STR NUMBER? -> 65535 -1 }T

\ NUMBER? overflow without dot - should fail
T{ S" 65536" NUMTEST-STR NUMBER? NIP -> 0 }T

\ NUMBER? double literals
T{ S" 1234."    NUMTEST-STR NUMBER? -> 1234 0 -1 }T
T{ S" 0."       NUMTEST-STR NUMBER? -> 0 0 -1 }T
T{ S" 100000."  NUMTEST-STR NUMBER? -> $86A0 1 -1 }T
T{ S" -1."      NUMTEST-STR NUMBER? -> -1 -1 -1 }T
T{ S" -100000." NUMTEST-STR NUMBER? -> $7960 -2 -1 }T
T{ S" 65536."   NUMTEST-STR NUMBER? -> 0 1 -1 }T
T{ S" $10000."  NUMTEST-STR NUMBER? -> 0 1 -1 }T

DONE
