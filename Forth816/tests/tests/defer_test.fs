\ defer_test.fs - DEFER, DEFER!, DEFER@, IS, ACTION-OF regression tests

\ Basic DEFER and IS
DEFER MYDEFER
: RETURNS42 42 ;
T{ ' RETURNS42 IS MYDEFER MYDEFER -> 42 }T

\ IS in compile mode
: SET-MYDEFER ' RETURNS42 IS MYDEFER ;
: RETURNS99 99 ;
T{ ' RETURNS99 IS MYDEFER MYDEFER -> 99 }T
T{ SET-MYDEFER MYDEFER -> 42 }T

\ DEFER@ fetches current xt
T{ ' MYDEFER DEFER@ ' RETURNS42 = -> -1 }T

\ ACTION-OF in interpret mode
T{ ACTION-OF MYDEFER ' RETURNS42 = -> -1 }T

\ ACTION-OF in compile mode
: GET-ACTION ACTION-OF MYDEFER ;
T{ GET-ACTION ' RETURNS42 = -> -1 }T

\ DEFER! stores xt directly
T{ ' RETURNS99 ' MYDEFER DEFER! MYDEFER -> 99 }T

\ Uninitialized DEFER prints warning but does not abort
DEFER UNINIT-DEFER
UNINIT-DEFER
T{ RECOVERED? -> -1 }T

\ IS safety check - not a DEFER
55 CONSTANT NOTADEFER
T{ ' RETURNS42 IS NOTADEFER -> }T
T{ RECOVERED? -> -1 }T

\ ACTION-OF safety check - not a DEFER
T{ ACTION-OF NOTADEFER -> }T
T{ RECOVERED? -> -1 }T

DONE
