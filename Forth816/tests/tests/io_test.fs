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

DONE
