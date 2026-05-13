\ io_test.fs - I/O regression tests

\ EMIT - no stack result, just verify stack is clean
T{ 69 EMIT -> }T    \ emits 'E'

\ KEY - untestable via T{/}T, requires interactive input
\ skipped

\ KEY? - may return 0 if no key pending, just verify stack effect
T{ KEY? DROP -> }T

\ TYPE - no stack result
T{ S" hello" TYPE -> }T

\ CR - no stack result
T{ CR -> }T

\ SPACE - no stack result
T{ SPACE -> }T

\ SPACES
T{ 10 SPACES -> }T

\ . (DOT)
T{ 0 . -> }T
T{ 10 . -> }T
T{ -3 . -> }T
T{ 15936 . -> }T

\ U.
T{ 0 U. -> }T
T{ 65535 U. -> }T
T{ 32768 U. -> }T

\ .HEX
T{ 0 .HEX -> }T
T{ $DEAD .HEX -> }T
T{ $FFFF .HEX -> }T

\ D.
T{ 0. D. -> }T
T{ 1234. D. -> }T
T{ -1. D. -> }T
T{ 100000. D. -> }T


\ Pictured I/O Tests
: GP1 <# $41 HOLD $42 HOLD 0 0 #> S" BA" COMPARE ;

T{ GP1 -> 0 }T

T{ 0. <# S" Test" HOLDS #> S" Test" COMPARE -> 0 }T

45 10 .R
-45 10 .R

10 10 U.R
-1 10 U.R

-12. 10 D.R

100000. 12 d.r

-100000. 12 d.r

.( hello }
: foo 1 .( world ) ;

DONE
