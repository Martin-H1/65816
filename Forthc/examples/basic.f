\ examples/basic.f

.origin $4000
.main main

15 constant foo

: multiply-demo
    2 3 *
;

: show-foo
    foo .
    cr
;

: max   ( n1 n2 -- max )
    over over < if
        swap
    then
    drop
;

: countdown   ( n -- )
    begin
        dup .
        cr
        1 -
        dup 0 =
    until
    drop
;

variable counter

: increment-counter
    counter @
    1 +
    counter !
;

: reset-counter
    0 counter !
;

: get-counter  ( -- n )
    counter @
;

: say-hello
    ." Hello, World!"
    cr
;

: main
    say-hello
    5 countdown
    show-foo
;
